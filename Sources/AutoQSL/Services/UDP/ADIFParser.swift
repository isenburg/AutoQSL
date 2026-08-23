import Foundation

public final class ADIFParser {
    public struct ADIFRecord {
        public var fields: [String: String] = [:]
        
        public subscript(key: String) -> String? {
            return fields[key.uppercased()]
        }
        
        public var dxCall: String? { self["CALL"] }
        public var band: String? { self["BAND"] }
        public var mode: String? { self["MODE"] }
        public var freqMHz: Double? {
            if let f = self["FREQ"], let val = Double(f) { return val }
            return nil
        }
        public var rstSent: String? { self["RST_SENT"] }
        public var rstRcvd: String? { self["RST_RCVD"] }
        public var comment: String? { self["COMMENT"] ?? self["NOTES"] ?? self["QSLMSG"] }
        public var dxCountry: String? { self["COUNTRY"] }
        public var txPower: Double? {
            if let p = self["TX_PWR"], let val = Double(p) { return val }
            return nil
        }
        public var dxGrid: String? { self["GRIDSQUARE"] }
        public var dxName: String? { self["NAME"] }
        public var dxEmail: String? { self["EMAIL"] }
        public var myCall: String? { self["STATION_CALLSIGN"] ?? self["OPERATOR"] ?? self["MY_CALL"] }
        public var myGrid: String? { self["MY_GRIDSQUARE"] }
        
        public var qsoDate: Date? {
            guard let dateStr = self["QSO_DATE"] else { return nil }
            let timeStr = self["TIME_ON"] ?? self["TIME_OFF"] ?? "000000"
            let fullStr = dateStr + timeStr.prefix(6)
            
            let formatter = DateFormatter()
            formatter.dateFormat = fullStr.count >= 14 ? "yyyyMMddHHmmss" : (fullStr.count >= 12 ? "yyyyMMddHHmm" : "yyyyMMdd")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: fullStr)
        }
    }
    
    public static func parse(text: String) -> [ADIFRecord] {
        var records: [ADIFRecord] = []
        var currentRecord = ADIFRecord()
        
        // Find header end if present
        var content = text
        if let eohRange = content.range(of: "<EOH>", options: .caseInsensitive) {
            content = String(content[eohRange.upperBound...])
        }
        
        // Regex pattern to match <TAG:LENGTH>VALUE or <TAG:LENGTH:TYPE>VALUE or <EOR>
        let tagPattern = #"<([a-zA-Z0-9_]+):?([0-9]*):?([a-zA-Z0-9]*)>"#
        guard let regex = try? NSRegularExpression(pattern: tagPattern, options: []) else {
            return []
        }
        
        let nsString = content as NSString
        let matches = regex.matches(in: content, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for (index, match) in matches.enumerated() {
            let tagName = nsString.substring(with: match.range(at: 1)).uppercased()
            
            if tagName == "EOR" {
                if !currentRecord.fields.isEmpty {
                    records.append(currentRecord)
                    currentRecord = ADIFRecord()
                }
                continue
            }
            
            let lenStr = match.numberOfRanges > 2 && match.range(at: 2).location != NSNotFound ? nsString.substring(with: match.range(at: 2)) : ""
            let valueLength = Int(lenStr) ?? 0
            
            let valueStart = match.range.location + match.range.length
            var valString = ""
            
            if valueLength > 0 && valueStart + valueLength <= nsString.length {
                valString = nsString.substring(with: NSRange(location: valueStart, length: valueLength))
            } else if index + 1 < matches.count {
                let nextMatchStart = matches[index + 1].range.location
                if nextMatchStart > valueStart {
                    valString = nsString.substring(with: NSRange(location: valueStart, length: nextMatchStart - valueStart)).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
                valString = nsString.substring(from: valueStart).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            currentRecord.fields[tagName] = valString.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        if !currentRecord.fields.isEmpty {
            records.append(currentRecord)
        }
        
        return records
    }
}
