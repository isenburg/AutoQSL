import Foundation
import Combine

public final class UDPListenerService: ObservableObject {
    public struct ListenerState: Identifiable {
        public var id: String { "\(address):\(port)" }
        public var port: Int
        public var address: String
        public var name: String
        public var isMulticast: Bool
        public var isRunning: Bool = false
        public var packetsReceived: Int = 0
        public var lastPacketDate: Date? = nil
        public var errorMessage: String? = nil
    }
    
    @Published public private(set) var listeners: [String: ListenerState] = [:]
    @Published public private(set) var isAnyListening: Bool = false
    
    private var sockets: [String: (fd: Int32, source: DispatchSourceRead)] = [:]
    private let queue = DispatchQueue(label: "org.autoqsl.udp.listener", qos: .userInitiated, attributes: .concurrent)
    private let lock = NSLock()
    
    public var onQSORecordReceived: ((QSO) -> Void)?
    
    public init() {}
    
    public func startListening(listeners: [(port: Int, address: String, name: String)]) {
        stopAll()
        
        // Group by port so multiple targets on the same port share a single socket
        var byPort: [Int: [(address: String, name: String)]] = [:]
        for item in listeners {
            guard item.port > 0 && item.port <= 65535 else { continue }
            byPort[item.port, default: []].append((address: item.address, name: item.name))
        }
        
        for (port, targets) in byPort {
            startPortListener(port: port, targets: targets)
        }
    }
    
    private func startPortListener(port: Int, targets: [(address: String, name: String)]) {
        let combinedNames = targets.map { $0.name }.joined(separator: " / ")
        let primaryAddr = targets.first?.address ?? "0.0.0.0"
        let isAnyMC = targets.contains { AppSettings.isMulticast(address: $0.address) }
        let key = "\(primaryAddr):\(port)"
        
        queue.async { [weak self] in
            guard let self = self else { return }
            
            let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
            guard fd >= 0 else {
                let err = String(cString: strerror(errno))
                DispatchQueue.main.async {
                    self.listeners[key] = ListenerState(
                        port: port,
                        address: primaryAddr,
                        name: combinedNames,
                        isMulticast: isAnyMC,
                        isRunning: false,
                        errorMessage: "Socket error: \(err)"
                    )
                }
                return
            }
            
            var yes: Int32 = 1
            setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &yes, socklen_t(MemoryLayout<Int32>.size))
            setsockopt(fd, SOL_SOCKET, SO_REUSEPORT, &yes, socklen_t(MemoryLayout<Int32>.size))
            
            var broadcastOn: Int32 = 1
            setsockopt(fd, SOL_SOCKET, SO_BROADCAST, &broadcastOn, socklen_t(MemoryLayout<Int32>.size))
            
            let flags = fcntl(fd, F_GETFL)
            _ = fcntl(fd, F_SETFL, flags | O_NONBLOCK)
            
            var bindAddr = sockaddr_in()
            bindAddr.sin_family = sa_family_t(AF_INET)
            bindAddr.sin_port = UInt16(port).bigEndian
            bindAddr.sin_addr.s_addr = in_addr_t(0) // INADDR_ANY (0.0.0.0)
            
            var bindResult: Int32 = -1
            for _ in 1...5 {
                bindResult = withUnsafePointer(to: &bindAddr) {
                    $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                        Darwin.bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
                    }
                }
                if bindResult == 0 { break }
                usleep(100_000)
            }
            
            guard bindResult == 0 else {
                let err = String(cString: strerror(errno))
                close(fd)
                DispatchQueue.main.async {
                    self.listeners[key] = ListenerState(
                        port: port,
                        address: primaryAddr,
                        name: combinedNames,
                        isMulticast: isAnyMC,
                        isRunning: false,
                        errorMessage: "Port \(port) bind failed: \(err)"
                    )
                }
                return
            }
            
            var ttl: UInt8 = 4
            setsockopt(fd, IPPROTO_IP, IP_MULTICAST_TTL, &ttl, socklen_t(MemoryLayout<UInt8>.size))
            var loop: UInt8 = 1
            setsockopt(fd, IPPROTO_IP, IP_MULTICAST_LOOP, &loop, socklen_t(MemoryLayout<UInt8>.size))
            
            var joinError: String? = nil
            for target in targets {
                let trimmed = target.address.trimmingCharacters(in: .whitespacesAndNewlines)
                if AppSettings.isMulticast(address: trimmed) {
                    var mreq = ip_mreq()
                    mreq.imr_multiaddr.s_addr = inet_addr(trimmed)
                    mreq.imr_interface.s_addr = in_addr_t(0)
                    let res = setsockopt(fd, IPPROTO_IP, IP_ADD_MEMBERSHIP, &mreq, socklen_t(MemoryLayout<ip_mreq>.size))
                    if res != 0 {
                        joinError = "MC join \(trimmed): \(String(cString: strerror(errno)))"
                    }
                }
            }
            
            let readSource = DispatchSource.makeReadSource(fileDescriptor: fd, queue: self.queue)
            readSource.setEventHandler { [weak self] in
                self?.readSocket(fd: fd, key: key, port: port)
            }
            readSource.setCancelHandler {
                close(fd)
            }
            readSource.resume()
            
            self.lock.lock()
            self.sockets[key] = (fd: fd, source: readSource)
            self.lock.unlock()
            
            DispatchQueue.main.async {
                self.listeners[key] = ListenerState(
                    port: port,
                    address: primaryAddr,
                    name: combinedNames,
                    isMulticast: isAnyMC,
                    isRunning: true,
                    errorMessage: joinError
                )
                self.isAnyListening = self.listeners.values.contains { $0.isRunning }
            }
        }
    }
    
    private func readSocket(fd: Int32, key: String, port: Int) {
        while true {
            var buffer = [UInt8](repeating: 0, count: 65536)
            var clientAddr = sockaddr_in()
            var addrLen = socklen_t(MemoryLayout<sockaddr_in>.size)
            
            let bytesRead = withUnsafeMutablePointer(to: &clientAddr) {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    recvfrom(fd, &buffer, buffer.count, 0, $0, &addrLen)
                }
            }
            
            if bytesRead <= 0 {
                break
            }
            
            let data = Data(buffer[0..<bytesRead])
            
            DispatchQueue.main.async {
                if var cur = self.listeners[key] {
                    cur.packetsReceived += 1
                    cur.lastPacketDate = Date()
                    self.listeners[key] = cur
                }
            }
            
            processPacketData(data, port: port)
        }
    }
    
    public func processPacketData(_ data: Data, port: Int = 2237) {
        // 1. Check for WSJT-X Binary Protocol
        if WSJTXParser.isWSJTXPacket(data: data) {
            if let wsjtx = WSJTXParser.parse(data: data) {
                let qso = QSO(
                    source: .wsjtx,
                    dxCall: wsjtx.dxCall,
                    band: formatFrequencyToBand(wsjtx.frequencyHz),
                    mode: wsjtx.mode,
                    frequencyHz: wsjtx.frequencyHz,
                    qsoDate: wsjtx.dateOff,
                    rstSent: wsjtx.reportSent,
                    rstRcvd: wsjtx.reportRcvd,
                    comment: wsjtx.comments,
                    txPowerWatts: Double(wsjtx.txPower) ?? nil,
                    myCall: wsjtx.myCall ?? "",
                    myGrid: wsjtx.myGrid ?? "",
                    dxName: wsjtx.name,
                    dxGrid: wsjtx.dxGrid
                )
                DispatchQueue.main.async {
                    self.onQSORecordReceived?(qso)
                }
            }
            // Always return for WSJT-X packets to avoid ADIFParser picking up embedded ADIF strings (e.g. Type 12 Logged ADIF)
            return
        }
        
        // 2. Try ADIF / XML Parser (RUMlog / plain text / N1MM broadcast)
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1)
            ?? String(data: data, encoding: .windowsCP1252)
            ?? String(decoding: data, as: UTF8.self)
            
        if !text.isEmpty {
            let records = ADIFParser.parse(text: text)
            for rec in records {
                if rec.isDelete {
                    continue // Ignore delete actions
                }
                
                if let call = rec.dxCall, !call.isEmpty {
                    let freqHz: Double?
                    if let f = rec.freqMHz {
                        freqHz = f * 1_000_000.0
                    } else if let b = rec.band, let defMHz = RadioUtils.defaultFrequencyMHz(for: b) {
                        freqHz = defMHz * 1_000_000.0
                    } else {
                        freqHz = nil
                    }
                    
                    let bandStr = rec.band ?? (freqHz != nil ? RadioUtils.frequencyToBand(freqHz!) : "20m")
                    let qso = QSO(
                        source: .rumlog,
                        dxCall: call.uppercased().trimmingCharacters(in: .whitespacesAndNewlines),
                        band: bandStr,
                        mode: rec.mode ?? "SSB",
                        frequencyHz: freqHz,
                        qsoDate: rec.qsoDate ?? Date(),
                        rstSent: rec.rstSent ?? "599",
                        rstRcvd: rec.rstRcvd ?? "599",
                        comment: rec.comment ?? "",
                        txPowerWatts: rec.txPower,
                        myCall: rec.myCall ?? "",
                        myGrid: rec.myGrid ?? "",
                        dxName: rec.dxName ?? "",
                        dxAddress: rec.dxQTH ?? "",
                        dxGrid: rec.dxGrid ?? "",
                        dxCountry: rec.dxCountry ?? "",
                        dxEmail: rec.dxEmail ?? ""
                    )
                    print("[AutoQSL UDP] Received QSO from RUMlog on port \(port): \(qso.dxCall) on \(qso.band) (\(qso.mode))")
                    DispatchQueue.main.async {
                        self.onQSORecordReceived?(qso)
                    }
                }
            }
        }
    }
    
    public func stopAll() {
        lock.lock()
        for (_, entry) in sockets {
            entry.source.cancel()
        }
        sockets.removeAll()
        lock.unlock()
        
        DispatchQueue.main.async {
            for key in self.listeners.keys {
                self.listeners[key]?.isRunning = false
            }
            self.isAnyListening = false
        }
    }
    
    deinit {
        stopAll()
    }
    
    private func formatFrequencyToBand(_ freqHz: Double) -> String {
        let mhz = freqHz / 1_000_000.0
        switch mhz {
        case 1.8...2.0: return "160m"
        case 3.5...4.0: return "80m"
        case 5.3...5.5: return "60m"
        case 7.0...7.3: return "40m"
        case 10.1...10.15: return "30m"
        case 14.0...14.35: return "20m"
        case 18.068...18.168: return "17m"
        case 21.0...21.45: return "15m"
        case 24.89...24.99: return "12m"
        case 28.0...29.7: return "10m"
        case 50.0...54.0: return "6m"
        case 70.0...70.5: return "4m"
        case 144.0...148.0: return "2m"
        case 420.0...450.0: return "70cm"
        default:
            return String(format: "%.3f MHz", mhz)
        }
    }
}
