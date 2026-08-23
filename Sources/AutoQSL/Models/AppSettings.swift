import Foundation

public enum SendingMode: String, Codable, CaseIterable {
    case confirmBeforeSend = "Preview & Confirm (Recommended)"
    case autoSend = "Fully Automatic (Send Immediately)"
    case manualQueue = "Manual Queue (Hold for Review)"
    
    public var description: String {
        switch self {
        case .confirmBeforeSend:
            return "Shows the rendered QSL card preview dialog and waits for your confirmation before sending."
        case .autoSend:
            return "Automatically renders and emails the QSL card immediately when a QSO is logged."
        case .manualQueue:
            return "Queues all received QSOs in the list without sending until you manually click Send."
        }
    }
}

public enum EmailDeliveryMethod: String, Codable, CaseIterable, Identifiable {
    case appleMail = "Apple Mail (Recommended for Mac)"
    case defaultClient = "Default macOS Email Client"
    case directSMTP = "Direct SMTP Server"
    
    public var id: String { rawValue }
    
    public var description: String {
        switch self {
        case .appleMail:
            return "Dispatches directly through the macOS Apple Mail application. No SMTP server configuration or app passwords needed."
        case .defaultClient:
            return "Opens your default macOS email client compose window (Mail, Outlook, Thunderbird, etc.) with the QSL card attached."
        case .directSMTP:
            return "Sends directly via an outbound SMTP server (Gmail, Outlook, custom mail host)."
        }
    }
}

public enum DateOrder: String, Codable, CaseIterable, Identifiable {
    case ddMMyyyy = "DD MM YYYY"
    case yyyyMMdd = "YYYY MM DD"
    
    public var id: String { rawValue }
}

public enum DateSeparator: String, Codable, CaseIterable, Identifiable {
    case dot = "Dot (.)"
    case dash = "Dash (-)"
    case slash = "Slash (/)"
    case space = "Space ( )"
    
    public var id: String { rawValue }
    
    public var symbol: String {
        switch self {
        case .dot: return "."
        case .dash: return "-"
        case .slash: return "/"
        case .space: return " "
        }
    }
}

public enum DateHeaderStyle: String, Codable, CaseIterable, Identifiable {
    case singleDate = "Single Header (Date)"
    case splitSubheaders = "Split Sub-headers (Day Month Year)"
    
    public var id: String { rawValue }
}

public enum DateFormatOption: String, Codable, CaseIterable, Identifiable {
    case yyyyMMdd = "YYYY MM DD"
    case ddMMyyyy = "DD MM YYYY"
    
    public var id: String { rawValue }
}

public struct AppSettings: Codable {
    // Automation Mode
    public var sendingMode: SendingMode
    
    // Station Profile
    public var myCallsign: String
    public var myName: String
    public var myStreet: String
    public var myCity: String
    public var myState: String
    public var myCountry: String
    public var myGrid: String
    public var myCQZone: String
    public var myITUZone: String
    public var myCounty: String
    public var defaultComment: String
    
    // Date Configuration
    public var dateOrder: DateOrder
    public var dateSeparator: DateSeparator
    public var dateHeaderStyle: DateHeaderStyle
    
    // UDP Network Listener
    public var wsjtxEnabled: Bool
    public var wsjtxPort: Int
    public var rumlogEnabled: Bool
    public var rumlogPort: Int
    
    // QRZ.com XML API
    public var qrzEnabled: Bool
    public var qrzUsername: String
    public var qrzPassword: String
    
    // Email Delivery
    public var emailDeliveryMethod: EmailDeliveryMethod
    public var appleMailSendImmediately: Bool
    
    // SMTP Email Delivery
    public var smtpHost: String
    public var smtpPort: Int
    public var smtpUsername: String
    public var smtpPassword: String
    public var smtpUseTLS: Bool
    public var fromName: String
    public var fromEmail: String
    public var replyToEmail: String
    public var emailSubjectTemplate: String
    public var emailBodyTemplate: String
    
    // Selected Template
    public var activeTemplateId: UUID?
    
    public var dateFormat: DateFormatOption {
        get { dateOrder == .ddMMyyyy ? .ddMMyyyy : .yyyyMMdd }
        set { dateOrder = (newValue == .ddMMyyyy ? .ddMMyyyy : .yyyyMMdd) }
    }
    
    public init(
        sendingMode: SendingMode = .confirmBeforeSend,
        myCallsign: String = "DJ6GI",
        myName: String = "Georg Isenbürger",
        myStreet: String = "Heeresfliegerstrasse 16",
        myCity: String = "Hohenlockstedt",
        myState: String = "SH",
        myCountry: String = "Germany",
        myGrid: String = "JO43sx",
        myCQZone: String = "5",
        myITUZone: String = "8",
        myCounty: String = "",
        defaultComment: String = "73, Thanks for the QSO.",
        dateOrder: DateOrder = .ddMMyyyy,
        dateSeparator: DateSeparator = .dot,
        dateHeaderStyle: DateHeaderStyle = .singleDate,
        wsjtxEnabled: Bool = true,
        wsjtxPort: Int = 2237,
        rumlogEnabled: Bool = true,
        rumlogPort: Int = 2333,
        qrzEnabled: Bool = true,
        qrzUsername: String = "",
        qrzPassword: String = "",
        emailDeliveryMethod: EmailDeliveryMethod = .appleMail,
        appleMailSendImmediately: Bool = false,
        smtpHost: String = "smtp.gmail.com",
        smtpPort: Int = 587,
        smtpUsername: String = "",
        smtpPassword: String = "",
        smtpUseTLS: Bool = true,
        fromName: String = "DJ6GI",
        fromEmail: String = "",
        replyToEmail: String = "",
        emailSubjectTemplate: String = "eQSL Card from {MY_CALL} for our {BAND} {MODE} QSO",
        emailBodyTemplate: String = """
Hello {DX_NAME} ({DX_CALL}),

Thank you very much for our recent QSO on {DATE} at {TIME} UTC on {BAND} ({MODE})!
Please find attached my electronic QSL card confirming our contact.

73 and Good DX,
{MY_NAME} ({MY_CALL})
Grid: {MY_GRID} | CQ: {MY_CQ} | ITU: {MY_ITU}
""",
        activeTemplateId: UUID? = nil
    ) {
        self.sendingMode = sendingMode
        self.myCallsign = myCallsign
        self.myName = myName
        self.myStreet = myStreet
        self.myCity = myCity
        self.myState = myState
        self.myCountry = myCountry
        self.myGrid = myGrid
        self.myCQZone = myCQZone
        self.myITUZone = myITUZone
        self.myCounty = myCounty
        self.defaultComment = defaultComment
        self.dateOrder = dateOrder
        self.dateSeparator = dateSeparator
        self.dateHeaderStyle = dateHeaderStyle
        self.wsjtxEnabled = wsjtxEnabled
        self.wsjtxPort = wsjtxPort
        self.rumlogEnabled = rumlogEnabled
        self.rumlogPort = rumlogPort
        self.qrzEnabled = qrzEnabled
        self.qrzUsername = qrzUsername
        self.qrzPassword = qrzPassword
        self.emailDeliveryMethod = emailDeliveryMethod
        self.appleMailSendImmediately = appleMailSendImmediately
        self.smtpHost = smtpHost
        self.smtpPort = smtpPort
        self.smtpUsername = smtpUsername
        self.smtpPassword = smtpPassword
        self.smtpUseTLS = smtpUseTLS
        self.fromName = fromName
        self.fromEmail = fromEmail
        self.replyToEmail = replyToEmail
        self.emailSubjectTemplate = emailSubjectTemplate
        self.emailBodyTemplate = emailBodyTemplate
        self.activeTemplateId = activeTemplateId
    }
    
    enum CodingKeys: String, CodingKey {
        case sendingMode, myCallsign, myName, myStreet, myCity, myState, myCountry
        case myGrid, myCQZone, myITUZone, myCounty, defaultComment
        case dateOrder, dateSeparator, dateHeaderStyle
        case wsjtxEnabled, wsjtxPort, rumlogEnabled, rumlogPort
        case qrzEnabled, qrzUsername, qrzPassword
        case emailDeliveryMethod, appleMailSendImmediately
        case smtpHost, smtpPort, smtpUsername, smtpPassword, smtpUseTLS
        case fromName, fromEmail, replyToEmail
        case emailSubjectTemplate, emailBodyTemplate, activeTemplateId
    }
    
    enum LegacyCodingKeys: String, CodingKey {
        case dateFormat
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.sendingMode = try container.decodeIfPresent(SendingMode.self, forKey: .sendingMode) ?? .confirmBeforeSend
        self.myCallsign = try container.decodeIfPresent(String.self, forKey: .myCallsign) ?? "DJ6GI"
        self.myName = try container.decodeIfPresent(String.self, forKey: .myName) ?? "Georg Isenbürger"
        self.myStreet = try container.decodeIfPresent(String.self, forKey: .myStreet) ?? "Heeresfliegerstrasse 16"
        self.myCity = try container.decodeIfPresent(String.self, forKey: .myCity) ?? "Hohenlockstedt"
        self.myState = try container.decodeIfPresent(String.self, forKey: .myState) ?? "SH"
        self.myCountry = try container.decodeIfPresent(String.self, forKey: .myCountry) ?? "Germany"
        self.myGrid = try container.decodeIfPresent(String.self, forKey: .myGrid) ?? "JO43sx"
        self.myCQZone = try container.decodeIfPresent(String.self, forKey: .myCQZone) ?? "5"
        self.myITUZone = try container.decodeIfPresent(String.self, forKey: .myITUZone) ?? "8"
        self.myCounty = try container.decodeIfPresent(String.self, forKey: .myCounty) ?? ""
        self.defaultComment = try container.decodeIfPresent(String.self, forKey: .defaultComment) ?? "73, Thanks for the QSO."
        
        let legacyContainer = try? decoder.container(keyedBy: LegacyCodingKeys.self)
        let legacyFormat = try? legacyContainer?.decodeIfPresent(DateFormatOption.self, forKey: .dateFormat)
        let defaultOrder: DateOrder = (legacyFormat == .yyyyMMdd ? .yyyyMMdd : .ddMMyyyy)
        self.dateOrder = try container.decodeIfPresent(DateOrder.self, forKey: .dateOrder) ?? defaultOrder
        self.dateSeparator = try container.decodeIfPresent(DateSeparator.self, forKey: .dateSeparator) ?? .dot
        self.dateHeaderStyle = try container.decodeIfPresent(DateHeaderStyle.self, forKey: .dateHeaderStyle) ?? .singleDate
        
        self.wsjtxEnabled = try container.decodeIfPresent(Bool.self, forKey: .wsjtxEnabled) ?? true
        self.wsjtxPort = try container.decodeIfPresent(Int.self, forKey: .wsjtxPort) ?? 2237
        self.rumlogEnabled = try container.decodeIfPresent(Bool.self, forKey: .rumlogEnabled) ?? true
        self.rumlogPort = try container.decodeIfPresent(Int.self, forKey: .rumlogPort) ?? 2333
        self.qrzEnabled = try container.decodeIfPresent(Bool.self, forKey: .qrzEnabled) ?? true
        self.qrzUsername = try container.decodeIfPresent(String.self, forKey: .qrzUsername) ?? ""
        self.qrzPassword = try container.decodeIfPresent(String.self, forKey: .qrzPassword) ?? ""
        self.emailDeliveryMethod = try container.decodeIfPresent(EmailDeliveryMethod.self, forKey: .emailDeliveryMethod) ?? .appleMail
        self.appleMailSendImmediately = try container.decodeIfPresent(Bool.self, forKey: .appleMailSendImmediately) ?? false
        self.smtpHost = try container.decodeIfPresent(String.self, forKey: .smtpHost) ?? "smtp.gmail.com"
        self.smtpPort = try container.decodeIfPresent(Int.self, forKey: .smtpPort) ?? 587
        self.smtpUsername = try container.decodeIfPresent(String.self, forKey: .smtpUsername) ?? ""
        self.smtpPassword = try container.decodeIfPresent(String.self, forKey: .smtpPassword) ?? ""
        self.smtpUseTLS = try container.decodeIfPresent(Bool.self, forKey: .smtpUseTLS) ?? true
        self.fromName = try container.decodeIfPresent(String.self, forKey: .fromName) ?? "DJ6GI"
        self.fromEmail = try container.decodeIfPresent(String.self, forKey: .fromEmail) ?? ""
        self.replyToEmail = try container.decodeIfPresent(String.self, forKey: .replyToEmail) ?? ""
        self.emailSubjectTemplate = try container.decodeIfPresent(String.self, forKey: .emailSubjectTemplate) ?? "eQSL Card from {MY_CALL} for our {BAND} {MODE} QSO"
        self.emailBodyTemplate = try container.decodeIfPresent(String.self, forKey: .emailBodyTemplate) ?? "Hello {DX_NAME} ({DX_CALL}),\n\nThank you very much for our recent QSO on {DATE} at {TIME} UTC on {BAND} ({MODE})!\nPlease find attached my electronic QSL card confirming our contact.\n\n73 and Good DX,\n{MY_NAME} ({MY_CALL})\nGrid: {MY_GRID} | CQ: {MY_CQ} | ITU: {MY_ITU}\n"
        self.activeTemplateId = try container.decodeIfPresent(UUID.self, forKey: .activeTemplateId)
    }
    
    public var fullMyAddress: String {
        var parts: [String] = []
        if !myName.isEmpty { parts.append(myName) }
        if !myStreet.isEmpty { parts.append(myStreet) }
        var loc = ""
        if !myCity.isEmpty { loc += myCity }
        if !myState.isEmpty { loc += (loc.isEmpty ? "" : ", ") + myState }
        if !loc.isEmpty { parts.append(loc) }
        if !myCountry.isEmpty { parts.append(myCountry) }
        return parts.joined(separator: "\n")
    }
}
