import Foundation

public final class ADIFParser {
    public struct ADIFRecord {
        public var fields: [String: String] = [:]
        
        public subscript(key: String) -> String? {
            return fields[key.uppercased()]
        }
        
        public var dxCall: String? {
            self["CALL"] ?? self["DXCALL"] ?? self["CALLSIGN"] ?? self["DX_CALL"] ?? self["HIS_CALL"]
        }
        
        public var band: String? {
            if let raw = self["BAND"] ?? self["DX_BAND"] {
                let clean = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
                if clean.hasSuffix("m") || clean.hasSuffix("cm") {
                    return clean
                }
                switch clean {
                case "1.8", "160", "160m": return "160m"
                case "3.5", "3", "80", "80m": return "80m"
                case "5", "5.3", "60", "60m": return "60m"
                case "7", "40", "40m": return "40m"
                case "10", "30", "30m": return "30m"
                case "14", "20", "20m": return "20m"
                case "18", "17", "17m": return "17m"
                case "21", "15", "15m": return "15m"
                case "24", "12", "12m": return "12m"
                case "28", "10m": return "10m"
                case "50", "6", "6m": return "6m"
                case "70", "4", "4m": return "4m"
                case "144", "2", "2m": return "2m"
                case "430", "432", "70cm": return "70cm"
                case "1296", "23", "23cm": return "23cm"
                default:
                    if let num = Double(clean) {
                        if num >= 1_000_000 {
                            return RadioUtils.frequencyToBand(num)
                        } else if num >= 1_000 {
                            return RadioUtils.frequencyToBand(num * 1_000.0)
                        } else if num > 1.0 {
                            return RadioUtils.frequencyToBand(num * 1_000_000.0)
                        }
                    }
                    return clean.contains("m") ? clean : "\(clean)m"
                }
            }
            if let freq = freqMHz {
                return RadioUtils.frequencyToBand(freq * 1_000_000.0)
            }
            return nil
        }
        
        public var mode: String? {
            if let sub = self["SUBMODE"], !sub.isEmpty {
                return sub.uppercased()
            }
            return self["MODE"]?.uppercased()
        }
        
        public var freqMHz: Double? {
            if let f = self["TXFREQ"] ?? self["RXFREQ"] ?? self["FREQ"] ?? self["FREQUENCY"] ?? self["TX_FREQ"] ?? self["RX_FREQ"],
               let val = Double(f.replacingOccurrences(of: ",", with: ".")) {
                // In RUMlogNG / N1MM XML: 10Hz units (e.g. 1407400 -> 14.074 MHz)
                if val >= 100_000 && val < 10_000_000 {
                    return val / 100_000.0
                }
                // In Hz (e.g. 14074000 -> 14.074 MHz)
                if val >= 10_000_000 {
                    return val / 1_000_000.0
                }
                // In kHz (e.g. 14074.0 -> 14.074 MHz)
                if val > 1000 && val < 100_000 {
                    return val / 1000.0
                }
                // In MHz (e.g. 14.074)
                return val
            }
            return nil
        }
        
        public var rstSent: String? { self["RST_SENT"] ?? self["SNT"] ?? self["RSTSNT"] ?? self["SENT"] }
        public var rstRcvd: String? { self["RST_RCVD"] ?? self["RCV"] ?? self["RSTRCVD"] ?? self["RCVD"] }
        public var comment: String? { self["COMMENT"] ?? self["NOTES"] ?? self["QSLMSG"] ?? self["REMARKS"] ?? self["MEMO"] }
        public var dxCountry: String? { self["COUNTRY"] ?? self["DXCC_COUNTRY"] ?? self["COUNTRYPREFIX"] }
        public var txPower: Double? {
            if let p = self["TX_PWR"] ?? self["POWER"] ?? self["TXPOWER"], let val = Double(p) { return val }
            return nil
        }
        public var dxGrid: String? { self["GRIDSQUARE"] ?? self["GRID"] ?? self["MYGRID"] }
        public var dxName: String? { self["NAME"] ?? self["OPNAME"] ?? self["FNAME"] }
        public var dxQTH: String? { self["QTH"] ?? self["CITY"] ?? self["STATE"] }
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
        
        var content = text
        if let eohRange = content.range(of: "<EOH>", options: .caseInsensitive) {
            content = String(content[eohRange.upperBound...])
        }
        
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
            var val = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Strip CDATA if present
            if val.hasPrefix("<![CDATA[") && val.hasSuffix("]]>") {
                val = String(val.dropFirst(9).dropLast(3)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // Skip top-level container tags
            if tag == "CONTACTINFO" || tag == "QSO" || tag == "RECORD" || tag == "RADIOINFO" {
                continue
            }
            
            record.fields[tag] = val
        }
        
        return record.fields.isEmpty ? [] : [record]
    }
}
