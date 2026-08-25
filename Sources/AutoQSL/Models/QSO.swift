import Foundation

public enum QSOStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case lookingUpQRZ = "Looking up QRZ"
    case awaitingConfirmation = "Awaiting Confirmation"
    case readyToSend = "Ready to Send"
    case sending = "Sending..."
    case sent = "Sent"
    case failed = "Failed"
    case skipped = "Skipped"
    
    public var iconName: String {
        switch self {
        case .pending: return "clock"
        case .lookingUpQRZ: return "magnifyingglass"
        case .awaitingConfirmation: return "exclamationmark.bubble"
        case .readyToSend: return "paperplane"
        case .sending: return "arrow.up.circle.badge.clock"
        case .sent: return "checkmark.circle.fill"
        case .failed: return "xmark.octagon.fill"
        case .skipped: return "slash.circle"
        }
    }
}

public enum QSOSource: String, Codable {
    case wsjtx = "WSJT-X"
    case rumlog = "RUMlogNG"
    case manual = "Manual"
    case adifFile = "ADIF File"
}

public struct QSO: Identifiable, Codable, Hashable {
    public var id: UUID
    public var timestamp: Date
    public var source: QSOSource
    
    // QSO Data
    public var dxCall: String
    public var band: String
    public var mode: String
    public var frequencyHz: Double?
    public var qsoDate: Date
    public var rstSent: String
    public var rstRcvd: String
    public var comment: String
    public var txPowerWatts: Double?
    
    // My Station Data (snapshot at QSO time)
    public var myCall: String
    public var myGrid: String
    public var myName: String
    public var myAddress: String
    public var myCQZone: String
    public var myITUZone: String
    
    // DX Contact Info (retrieved from QRZ or manual)
    public var dxName: String
    public var dxAddress: String
    public var dxGrid: String
    public var dxCountry: String
    public var dxEmail: String
    public var qrzFound: Bool
    
    // Custom Card Template & Overrides
    public var templateId: UUID?
    public var customTemplate: QSLCardTemplate?
    
    // Status & Output
    public var status: QSOStatus
    public var statusMessage: String?
    public var generatedCardPath: String?
    public var sentAt: Date?
    
    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        source: QSOSource = .wsjtx,
        dxCall: String = "",
        band: String = "20m",
        mode: String = "FT8",
        frequencyHz: Double? = 14074000,
        qsoDate: Date = Date(),
        rstSent: String = "-10",
        rstRcvd: String = "-12",
        comment: String = "73, Thanks for the QSO. I hope to meet you further down the log.",
        txPowerWatts: Double? = nil,
        myCall: String = "",
        myGrid: String = "",
        myName: String = "",
        myAddress: String = "",
        myCQZone: String = "",
        myITUZone: String = "",
        dxName: String = "",
        dxAddress: String = "",
        dxGrid: String = "",
        dxCountry: String = "",
        dxEmail: String = "",
        qrzFound: Bool = false,
        templateId: UUID? = nil,
        customTemplate: QSLCardTemplate? = nil,
        status: QSOStatus = .pending,
        statusMessage: String? = nil,
        generatedCardPath: String? = nil,
        sentAt: Date? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.source = source
        self.dxCall = dxCall.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        self.band = band
        self.mode = mode
        self.frequencyHz = frequencyHz
        self.qsoDate = qsoDate
        self.rstSent = rstSent
        self.rstRcvd = rstRcvd
        self.comment = comment
        self.txPowerWatts = txPowerWatts
        self.myCall = myCall
        self.myGrid = myGrid
        self.myName = myName
        self.myAddress = myAddress
        self.myCQZone = myCQZone
        self.myITUZone = myITUZone
        self.dxName = dxName
        self.dxAddress = dxAddress
        self.dxGrid = dxGrid
        self.dxCountry = dxCountry
        self.dxEmail = dxEmail
        self.qrzFound = qrzFound
        self.templateId = templateId
        self.customTemplate = customTemplate
        self.status = status
        self.statusMessage = statusMessage
        self.generatedCardPath = generatedCardPath
        self.sentAt = sentAt
    }
    
    public var formattedDateYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: qsoDate)
    }
    
    public var formattedDateMonth: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: qsoDate)
    }
    
    public var formattedDateDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: qsoDate)
    }
    
    public var formattedUTCTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: qsoDate)
    }
    public func formattedDate(format: DateFormatOption = .yyyyMMdd) -> String {
        switch format {
        case .ddMMyyyy:
            return "\(formattedDateDay).\(formattedDateMonth).\(formattedDateYear)"
        case .yyyyMMdd:
            return "\(formattedDateYear).\(formattedDateMonth).\(formattedDateDay)"
        }
    }
    
    public func formattedDate(order: DateOrder, separator: DateSeparator) -> String {
        let sep = separator.symbol
        if order == .ddMMyyyy {
            return "\(formattedDateDay)\(sep)\(formattedDateMonth)\(sep)\(formattedDateYear)"
        } else {
            return "\(formattedDateYear)\(sep)\(formattedDateMonth)\(sep)\(formattedDateDay)"
        }
    }
}


public struct RadioUtils {
    public static let standardBands: [String] = [
        "2190m", "630m", "160m", "80m", "60m", "40m", "30m", "20m",
        "17m", "15m", "12m", "10m", "6m", "4m", "2m", "1.25m", "70cm",
        "33cm", "23cm", "13cm"
    ]
    
    public static let standardModes: [String] = [
        "FT8", "FT4", "CW", "SSB", "USB", "LSB", "RTTY", "PSK31",
        "FM", "AM", "MSK144", "JS8", "Olivia", "SSTV", "Q65", "FST4",
        "VARAC", "DMR", "C4FM", "D-STAR", "WSPR"
    ]
    
    public static func defaultFrequencyMHz(for band: String) -> Double? {
        let clean = band.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch clean {
        case "2190m": return 0.136
        case "630m": return 0.474
        case "160m": return 1.840
        case "80m": return 3.573
        case "60m": return 5.357
        case "40m": return 7.074
        case "30m": return 10.136
        case "20m": return 14.074
        case "17m": return 18.100
        case "15m": return 21.074
        case "12m": return 24.915
        case "10m": return 28.074
        case "6m": return 50.313
        case "4m": return 70.154
        case "2m": return 144.174
        case "1.25m": return 222.100
        case "70cm": return 432.174
        case "33cm": return 902.100
        case "23cm": return 1296.174
        case "13cm": return 2304.100
        default: return nil
        }
    }
    
    public static func band(forFrequencyMHz mhz: Double) -> String? {
        switch mhz {
        case 0.135...0.138: return "2190m"
        case 0.472...0.479: return "630m"
        case 1.8...2.0: return "160m"
        case 3.5...4.0: return "80m"
        case 5.0...5.5: return "60m"
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
        case 222.0...225.0: return "1.25m"
        case 420.0...450.0: return "70cm"
        case 902.0...928.0: return "33cm"
        case 1240.0...1300.0: return "23cm"
        case 2300.0...2450.0: return "13cm"
        default: return nil
        }
    }
    
    public static func band(forFrequencyHz hz: Double) -> String? {
        return band(forFrequencyMHz: hz / 1_000_000.0)
    }
    
    public static func frequencyToBand(_ freqHz: Double) -> String {
        if let b = band(forFrequencyHz: freqHz) {
            return b
        }
        let mhz = freqHz / 1_000_000.0
        return String(format: "%.3f MHz", mhz)
    }
    
    public static func parseFrequencyMHz(from string: String) -> Double? {
        let cleaned = string.replacingOccurrences(of: "MHz", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "kHz", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "Hz", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: ",", with: ".")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let val = Double(cleaned), val > 0 else { return nil }
        
        if val >= 1_000_000 {
            return val / 1_000_000.0
        }
        if val >= 1_000 && val < 1_000_000 {
            return val / 1_000.0
        }
        return val
    }
}
