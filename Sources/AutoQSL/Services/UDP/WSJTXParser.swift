import Foundation

public final class WSJTXParser {
    public static let wsjtxMagic: UInt32 = 0xADBCCBDA
    
    public enum WSJTXMessageType: UInt32 {
        case heartbeat = 0
        case status = 1
        case decode = 2
        case clear = 3
        case reply = 4
        case qsoLogged = 5
        case close = 6
        case replay = 7
        case haltTx = 8
        case freeText = 9
        case wsprDecode = 10
        case location = 11
        case loggedQSO = 12
        case unknown = 999
    }
    
    public struct WSJTXQSORecord {
        public var id: String
        public var dateOff: Date
        public var dxCall: String
        public var dxGrid: String
        public var frequencyHz: Double
        public var mode: String
        public var reportSent: String
        public var reportRcvd: String
        public var txPower: String
        public var comments: String
        public var name: String
        public var dateOn: Date?
        public var operatorCall: String?
        public var myCall: String?
        public var myGrid: String?
    }
    
    private let data: Data
    private var offset: Int = 0
    
    public init(data: Data) {
        self.data = data
        self.offset = 0
    }
    
    public static func parse(data: Data) -> WSJTXQSORecord? {
        let parser = WSJTXParser(data: data)
        return parser.parsePacket()
    }
    
    public func parsePacket() -> WSJTXQSORecord? {
        guard data.count >= 8 else { return nil }
        
        guard let magic = readUInt32(), magic == WSJTXParser.wsjtxMagic else {
            return nil
        }
        
        guard let _ = readUInt32() else { // schema version
            return nil
        }
        
        guard let msgTypeRaw = readUInt32() else {
            return nil
        }
        
        let msgType = WSJTXMessageType(rawValue: msgTypeRaw) ?? .unknown
        
        switch msgType {
        case .qsoLogged, .loggedQSO:
            return parseQSOLoggedPayload()
        default:
            return nil
        }
    }
    
    private func parseQSOLoggedPayload() -> WSJTXQSORecord? {
        guard let id = readUtf8String() else { return nil }
        guard let dateOff = readQDateTime() else { return nil }
        guard let dxCall = readUtf8String() else { return nil }
        guard let dxGrid = readUtf8String() else { return nil }
        guard let freq = readUInt64() else { return nil }
        guard let mode = readUtf8String() else { return nil }
        guard let rstSent = readUtf8String() else { return nil }
        guard let rstRcvd = readUtf8String() else { return nil }
        guard let txPower = readUtf8String() else { return nil }
        guard let comments = readUtf8String() else { return nil }
        guard let name = readUtf8String() else { return nil }
        
        let dateOn = readQDateTime()
        let opCall = readUtf8String()
        let myCall = readUtf8String()
        let myGrid = readUtf8String()
        
        return WSJTXQSORecord(
            id: id,
            dateOff: dateOff,
            dxCall: dxCall,
            dxGrid: dxGrid,
            frequencyHz: Double(freq),
            mode: mode,
            reportSent: rstSent,
            reportRcvd: rstRcvd,
            txPower: txPower,
            comments: comments,
            name: name,
            dateOn: dateOn,
            operatorCall: opCall,
            myCall: myCall,
            myGrid: myGrid
        )
    }
    
    // MARK: - Binary Helper Methods (Big Endian / Qt QDataStream format)
    
    private func readUInt32() -> UInt32? {
        guard offset + 4 <= data.count else { return nil }
        let value = data.subdata(in: offset..<offset+4).withUnsafeBytes { $0.load(as: UInt32.self).bigEndian }
        offset += 4
        return value
    }
    
    private func readInt64() -> Int64? {
        guard offset + 8 <= data.count else { return nil }
        let value = data.subdata(in: offset..<offset+8).withUnsafeBytes { $0.load(as: Int64.self).bigEndian }
        offset += 8
        return value
    }
    
    private func readUInt64() -> UInt64? {
        guard offset + 8 <= data.count else { return nil }
        let value = data.subdata(in: offset..<offset+8).withUnsafeBytes { $0.load(as: UInt64.self).bigEndian }
        offset += 8
        return value
    }
    
    private func readUInt8() -> UInt8? {
        guard offset + 1 <= data.count else { return nil }
        let value = data[offset]
        offset += 1
        return value
    }
    
    private func readUtf8String() -> String? {
        guard let length = readUInt32() else { return nil }
        if length == 0xFFFFFFFF { // Qt null string
            return ""
        }
        let len = Int(length)
        guard offset + len <= data.count else { return nil }
        let strData = data.subdata(in: offset..<offset+len)
        offset += len
        return String(data: strData, encoding: .utf8) ?? ""
    }
    
    private func readQDateTime() -> Date? {
        guard let julianDay = readInt64() else { return nil }
        guard let msecsSinceMidnight = readUInt32() else { return nil }
        guard let _ = readUInt8() else { return nil } // timespec
        
        // Convert Julian Day to Gregorian Date
        // JD 2440588 is 1970-01-01 (Unix Epoch)
        let daysSinceEpoch = Double(julianDay - 2440588)
        let seconds = (daysSinceEpoch * 86400.0) + (Double(msecsSinceMidnight) / 1000.0)
        return Date(timeIntervalSince1970: seconds)
    }
}
