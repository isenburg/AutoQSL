import Foundation

public final class ADIFParser {
    public struct ADIFRecord {
        public var fields: [String: String] = [:]
        
        public subscript(key: String) -> String? {
            return fields[key.uppercased()]
        }
        
        public var dxCall: String? { self["CALL"] ?? self["DXCALL"] ?? self["CALLSIGN"] ?? self["DX_CALL"] }
        public var band: String? {
            guard let raw = self["BAND"] ?? self["DX_BAND"] else { return nil }
            let lower = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if lower.hasSuffix("m") || lower.hasSuffix("cm") {
                return lower
            }
            // Map numeric MHz to standard ham bands (e.g. 14 -> 20m, 7 -> 40m, 28 -> 10m)
            switch lower {
            case "1.8", "160", "160m": return "160m"
            case "3.5", "3", "80", "80m": return "80m"
            case "5", "60", "60m": return "60m"
            case "7", "40", "40m": return "40m"
            case "10", "30m": return "30m"
            case "14", "20", "20m": return "20m"
            case "18", "17", "17m": return "17m"
            case "21", "15", "15m": return "15m"
            case "24", "12", "12m": return "12m"
            case "28", "10m": return "10m"
            case "50", "6", "6m": return "6m"
            case "70", "4m": return "4m"
            case "144", "2", "2m": return "2m"
            case "430", "432", "70cm": return "70cm"
            case "1296", "23", "23cm": return "23cm"
            default: return lower.contains("m") ? lower : "\(lower)m"
            }
        }
        public var mode: String? {
            if let sub = self["SUBMODE"], !sub.isEmpty {
                return sub.uppercased()
            }
            return self["MODE"]?.uppercased()
        }
        public var freqMHz: Double? {
            if let f = self["TXFREQ"] ?? self["RXFREQ"] ?? self["FREQ"] ?? self["FREQUENCY"],
                let val = Double(f.replacingOccurrences(of: ",", with: ".")) {
                // If frequency is 7-digits (e.g. 1408000 in 10Hz units = 14.080 MHz)
                if val >= 100_000 && val < 10_000_000 {
                    return val / 100_000.0
                }
                // If frequency is in Hz (e.g. 14080000)
                if val >= 10_000_000 {
                    return val / 1_000_000.0
                }
                // If frequency is in kHz (e.g. 14080.0)
                if val > 1000 && val < 100_000 {
                    return val / 1000.0
                }
                return val
            }
            return nil
        }
        public var rstSent: String? { self["RST_SENT"] ?? self["SNT"] ?? self["RSTSNT"] }
        public var rstRcvd: String? { self["RST_RCVD"] ?? self["RCV"] ?? self["RSTRCVD"] }
        public var comment: String? { self["COMMENT"] ?? self["NOTES"] ?? self["QSLMSG"] ?? self["REMARKS"] }
        public var dxCountry: String? { self["COUNTRY"] ?? self["DXCC_COUNTRY"] ?? self["COUNTRYPREFIX"] }
        public var txPower: Double? {
            if let p = self["TX_PWR"] ?? self["POWER"] ?? self["TXPOWER"], let val = Double(p) { return val }
            return nil
        }
        public var dxGrid: String? { self["GRIDSQUARE"] ?? self["GRID"] ?? self["MYGRID"] }
        public var dxName: String? { self["NAME"] ?? self["OPNAME"] ?? self["FNAME"] }
        public var dxQTH: String? { self["QTH"] ?? self["CITY"] }
        public var dxZone: String? { self["ZONE"] ?? self["CQZ"] }
        public var dxEmail: String? { self["EMAIL"] }
        public var myCall: String? { self["STATION_CALLSIGN"] ?? self["OPERATOR"] ?? self["MY_CALL"] ?? self["MYCALL"] }
        public var myGrid: String? { self["MY_GRIDSQUARE"] ?? self["MY_GRID"] }
        public var isDelete: Bool {
            let act = self["ACTION"] ?? self["QSO_ACTION"] ?? self["APP_N1MM_ACTION"]
            return act?.uppercased() == "DELETE" || act?.uppercased() == "DEL"
        }
        
        public var qsoDate: Date? {
            if let ts = self["TIMESTAMP"] ?? self["TIME"] {
                let fmt1 = DateFormatter()
                fmt1.dateFormat = "yyyy-MM-dd HH:mm:ss"
                fmt1.timeZone = TimeZone(secondsFromGMT: 0)
                if let d = fmt1.date(from: ts) { return d }
                
                let fmt2 = DateFormatter()
                fmt2.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
                fmt2.timeZone = TimeZone(secondsFromGMT: 0)
                if let d = fmt2.date(from: ts) { return d }
            }
            
            guard let dateStr = self["QSO_DATE"] ?? self["DATE"] else { return nil }
            let cleanDate = dateStr.replacingOccurrences(of: "-", with: "").replacingOccurrences(of: ".", with: "")
            let timeStr = self["TIME_ON"] ?? self["TIME_OFF"] ?? self["TIME"] ?? "000000"
            let cleanTime = timeStr.replacingOccurrences(of: ":", with: "")
            let fullStr = cleanDate + cleanTime.prefix(6)
            
            let formatter = DateFormatter()
            formatter.dateFormat = fullStr.count >= 14 ? "yyyyMMddHHmmss" : (fullStr.count >= 12 ? "yyyyMMddHHmm" : "yyyyMMdd")
            formatter.timeZone = TimeZone(secondsFromGMT: 0)
            return formatter.date(from: fullStr)
        }
    }
    
    public static func parse(text: String) -> [ADIFRecord] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return [] }
        
        // 1. Check if XML format (N1MM / RUMlogNG XML broadcast e.g. <contactinfo> or <?xml)
        if trimmed.localizedCaseInsensitiveContains("<contactinfo") ||
           trimmed.localizedCaseInsensitiveContains("<qso") ||
           trimmed.localizedCaseInsensitiveContains("<record") ||
           trimmed.localizedCaseInsensitiveContains("<?xml") {
            
            var xmlText = trimmed
            if let range = xmlText.range(of: "<?xml", options: .caseInsensitive) {
                xmlText = String(xmlText[range.lowerBound...])
            } else if let range = xmlText.range(of: "<contactinfo", options: .caseInsensitive) {
                xmlText = String(xmlText[range.lowerBound...])
            } else if let range = xmlText.range(of: "<qso", options: .caseInsensitive) {
                xmlText = String(xmlText[range.lowerBound...])
            } else if let range = xmlText.range(of: "<record", options: .caseInsensitive) {
                xmlText = String(xmlText[range.lowerBound...])
            }
            
            let xmlRecords = parseXML(text: xmlText)
            if !xmlRecords.isEmpty {
                return xmlRecords
            }
        }
        
        // 2. Standard ADIF Parser
        return parseADIF(text: text)
    }
    
    private static func parseADIF(text: String) -> [ADIFRecord] {
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
    
    private static func parseXML(text: String) -> [ADIFRecord] {
        var record = ADIFRecord()
        let tagRegex = #"<([a-zA-Z0-9_]+)(?:\s+[^>]*)?>([^<]*)</\1>"#
        guard let regex = try? NSRegularExpression(pattern: tagRegex, options: [.caseInsensitive]) else {
            return []
        }
        
        let nsString = text as NSString
        let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        
        for match in matches {
            let tag = nsString.substring(with: match.range(at: 1)).uppercased()
            let val = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            record.fields[tag] = val
        }
        
        return record.fields.isEmpty ? [] : [record]
    }
}
