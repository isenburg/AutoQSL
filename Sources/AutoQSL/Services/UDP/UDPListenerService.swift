import Foundation
import Network
import Combine

public final class UDPListenerService: ObservableObject {
    public struct ListenerState {
        public var port: Int
        public var name: String
        public var isRunning: Bool = false
        public var packetsReceived: Int = 0
        public var lastPacketDate: Date? = nil
        public var errorMessage: String? = nil
    }
    
    @Published public private(set) var listeners: [Int: ListenerState] = [:]
    @Published public private(set) var isAnyListening: Bool = false
    
    private var nwListeners: [Int: NWListener] = [:]
    private let queue = DispatchQueue(label: "org.autoqsl.udp.listener", qos: .userInitiated)
    
    public var onQSORecordReceived: ((QSO) -> Void)?
    
    public init() {}
    
    public func startListening(ports: [(port: Int, name: String)]) {
        stopAll()
        for p in ports {
            startListener(port: p.port, name: p.name)
        }
    }
    
    public func startListener(port: Int, name: String) {
        guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else {
            DispatchQueue.main.async {
                self.listeners[port] = ListenerState(port: port, name: name, isRunning: false, errorMessage: "Invalid port number")
            }
            return
        }
        
        do {
            let params = NWParameters.udp
            params.allowLocalEndpointReuse = true
            let listener = try NWListener(using: params, on: nwPort)
            
            listener.stateUpdateHandler = { [weak self] state in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        var cur = self.listeners[port] ?? ListenerState(port: port, name: name)
                        cur.isRunning = true
                        cur.errorMessage = nil
                        self.listeners[port] = cur
                        self.isAnyListening = self.listeners.values.contains { $0.isRunning }
                    case .failed(let err):
                        var cur = self.listeners[port] ?? ListenerState(port: port, name: name)
                        cur.isRunning = false
                        cur.errorMessage = err.localizedDescription
                        self.listeners[port] = cur
                        self.isAnyListening = self.listeners.values.contains { $0.isRunning }
                    case .cancelled:
                        var cur = self.listeners[port] ?? ListenerState(port: port, name: name)
                        cur.isRunning = false
                        self.listeners[port] = cur
                        self.isAnyListening = self.listeners.values.contains { $0.isRunning }
                    default:
                        break
                    }
                }
            }
            
            listener.newConnectionHandler = { [weak self] connection in
                self?.handleNewConnection(connection, port: port)
            }
            
            self.nwListeners[port] = listener
            self.listeners[port] = ListenerState(port: port, name: name, isRunning: false)
            listener.start(queue: self.queue)
        } catch {
            DispatchQueue.main.async {
                self.listeners[port] = ListenerState(port: port, name: name, isRunning: false, errorMessage: error.localizedDescription)
            }
        }
    }
    
    private func handleNewConnection(_ connection: NWConnection, port: Int) {
        connection.start(queue: self.queue)
        self.receiveNextPacket(from: connection, port: port)
    }
    
    private func receiveNextPacket(from connection: NWConnection, port: Int) {
        connection.receiveMessage { [weak self] (content, context, isComplete, error) in
            guard let self = self else { return }
            
            if let data = content, !data.isEmpty {
                DispatchQueue.main.async {
                    var cur = self.listeners[port] ?? ListenerState(port: port, name: "Port \(port)")
                    cur.packetsReceived += 1
                    cur.lastPacketDate = Date()
                    self.listeners[port] = cur
                }
                
                self.processPacketData(data, port: port)
            }
            
            if error == nil {
                self.receiveNextPacket(from: connection, port: port)
            }
        }
    }
    
    public func processPacketData(_ data: Data, port: Int = 2237) {
        // 1. Try WSJT-X Binary Parser
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
                comment: wsjtx.comments.isEmpty ? "73, Thanks for the QSO. I hope to meet you further down the log." : wsjtx.comments,
                txPowerWatts: Double(wsjtx.txPower) ?? nil,
                myCall: wsjtx.myCall ?? "",
                myGrid: wsjtx.myGrid ?? "",
                dxName: wsjtx.name,
                dxGrid: wsjtx.dxGrid
            )
            DispatchQueue.main.async {
                self.onQSORecordReceived?(qso)
            }
            return
        }
        
        // 2. Try ADIF Parser (RUMlog / plain text broadcast)
        if let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) {
            let records = ADIFParser.parse(text: text)
            for rec in records {
                if let call = rec.dxCall, !call.isEmpty {
                    let freqHz = rec.freqMHz != nil ? rec.freqMHz! * 1_000_000 : nil
                    let bandStr = rec.band ?? (freqHz != nil ? formatFrequencyToBand(freqHz!) : "20m")
                    let qso = QSO(
                        source: .rumlog,
                        dxCall: call,
                        band: bandStr,
                        mode: rec.mode ?? "SSB",
                        frequencyHz: freqHz,
                        qsoDate: rec.qsoDate ?? Date(),
                        rstSent: rec.rstSent ?? "59",
                        rstRcvd: rec.rstRcvd ?? "59",
                        comment: rec.comment ?? "",
                        txPowerWatts: rec.txPower,
                        myCall: rec.myCall ?? "",
                        myGrid: rec.myGrid ?? "",
                        dxName: rec.dxName ?? "",
                        dxAddress: "",
                        dxGrid: rec.dxGrid ?? "",
                        dxCountry: rec.dxCountry ?? "",
                        dxEmail: rec.dxEmail ?? ""
                    )
                    DispatchQueue.main.async {
                        self.onQSORecordReceived?(qso)
                    }
                }
            }
        }
    }
    
    public func stopAll() {
        for (_, listener) in nwListeners {
            listener.cancel()
        }
        nwListeners.removeAll()
        for port in listeners.keys {
            listeners[port]?.isRunning = false
        }
        isAnyListening = false
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
