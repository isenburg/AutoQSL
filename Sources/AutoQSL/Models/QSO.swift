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