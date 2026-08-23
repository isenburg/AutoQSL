import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    @State private var selectedTab: SettingsTab = .station
    @State private var qrzTestStatus: String? = nil
    @State private var isTestingQRZ: Bool = false
    @State private var smtpTestStatus: String? = nil
    @State private var isTestingSMTP: Bool = false
    @State private var mailTestStatus: String? = nil
    @State private var isTestingMail: Bool = false
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case station = "Station Profile"
        case automation = "Automation & Modes"
        case udp = "UDP Logging"
        case qrz = "QRZ.com Lookup"
        case email = "Email Delivery"
        case templates = "Email Templates"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .station: return "antenna.radiowaves.left.and.right"
            case .automation: return "gearshape.2"
            case .udp: return "network"
            case .qrz: return "person.text.rectangle"
            case .email: return "envelope.badge"
            case .templates: return "doc.text"
            }
        }
    }
    
    public var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("Preferences")
            .frame(minWidth: 200)
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .station:
                        stationProfileSection
                    case .automation:
                        automationSection
                    case .udp:
                        udpSection
                    case .qrz:
                        qrzSection
                    case .email:
                        emailDeliverySection
                    case .templates:
                        emailTemplatesSection
                    }
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    // MARK: - Station Profile
    private var stationProfileSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Station Profile")
                .font(.title2.bold())
            Text("Your amateur radio station details are displayed on the QSL card and email greetings.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Form {
                Section("Callsign & Operator") {
                    TextField("My Callsign", text: $appState.settings.myCallsign)
                    TextField("Operator Name", text: $appState.settings.myName)
                }
                
                Section("QTH / Address") {
                    TextField("Street Address", text: $appState.settings.myStreet)
                    TextField("City", text: $appState.settings.myCity)
                    TextField("State / Province / Zip", text: $appState.settings.myState)
                    TextField("Country", text: $appState.settings.myCountry)
                }
                
                Section("Location & Zones") {
                    TextField("Maidenhead Grid (e.g. FM18iv)", text: $appState.settings.myGrid)
                    HStack {
                        TextField("CQ Zone", text: $appState.settings.myCQZone)
                        TextField("ITU Zone", text: $appState.settings.myITUZone)
                    }
                    TextField("County / Region", text: $appState.settings.myCounty)
                }
                
                Section("Default QSL Greeting / Comment") {
                    TextField("Comment", text: $appState.settings.defaultComment)
                }
                
                Section("Date Format on QSL Cards & Emails") {
                    Picker("Date Sequence", selection: $appState.settings.dateOrder) {
                        ForEach(DateOrder.allCases) { opt in
                            Text(opt.rawValue).tag(opt)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Date Separator", selection: $appState.settings.dateSeparator) {
                        ForEach(DateSeparator.allCases) { sep in
                            Text(sep.rawValue).tag(sep)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Picker("Table Header Style", selection: $appState.settings.dateHeaderStyle) {
                        ForEach(DateHeaderStyle.allCases) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    
                    HStack {
                        Text("Preview:")
                            .font(.caption.bold())
                        Text(sampleDatePreview)
                            .font(.caption.monospaced())
                            .foregroundColor(.accentColor)
                    }
                }
            }
            .formStyle(.grouped)
        }
    }
    
    // MARK: - Automation & Modes
    private var automationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Automation & Dispatch Modes")
                .font(.title2.bold())
            Text("Control how QSOs received over UDP network broadcasts are handled and dispatched.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Form {
                Section("Sending Mode") {
                    Picker("Mode", selection: $appState.settings.sendingMode) {
                        ForEach(SendingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text(appState.settings.sendingMode.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .formStyle(.grouped)
        }
    }
    
    // MARK: - UDP Logging Settings
    private var udpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UDP Network Listeners")
                .font(.title2.bold())
            Text("AutoQSL listens on local UDP ports to receive QSO logged broadcast packets from WSJT-X, JTDX, and RUMlogNG.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Form {
                Section("WSJT-X / JTDX") {
                    Toggle("Enable WSJT-X UDP Broadcast Listener", isOn: $appState.settings.wsjtxEnabled)
                    HStack {
                        Text("Port:")
                        TextField("Port", value: $appState.settings.wsjtxPort, format: .number)
                            .frame(width: 80)
                        Text("(Default: 2237)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("RUMlogNG / ADIF Broadcasts") {
                    Toggle("Enable RUMlogNG UDP Listener", isOn: $appState.settings.rumlogEnabled)
                    HStack {
                        Text("Port:")
                        TextField("Port", value: $appState.settings.rumlogPort, format: .number)
                            .frame(width: 80)
                        Text("(Default: 2333 or 2237)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Restart Listeners") {
                    appState.startUDPListening()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
                
                if appState.udpListener.isAnyListening {
                    Label("Listening on configured ports", systemImage: "antenna.radiowaves.left.and.right")
                        .font(.caption.bold())
                        .foregroundColor(.green)
                } else {
                    Label("Listeners stopped", systemImage: "slash.circle")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }
    
    // MARK: - QRZ.com Settings
    private var qrzSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("QRZ.com XML API Integration")
                .font(.title2.bold())
            Text("Retrieves recipient email addresses, QTH, names, and grid squares automatically from QRZ XML Database.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Form {
                Section("Account Credentials") {
                    Toggle("Enable QRZ.com Lookups", isOn: $appState.settings.qrzEnabled)
                    TextField("QRZ.com Username / Callsign", text: $appState.settings.qrzUsername)
                    SecureField("QRZ.com Password", text: $appState.settings.qrzPassword)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Test QRZ Connection") {
                    testQRZ()
                }
                .buttonStyle(.bordered)
                .disabled(appState.settings.qrzUsername.isEmpty || appState.settings.qrzPassword.isEmpty || isTestingQRZ)
                
                if isTestingQRZ {
                    ProgressView().scaleEffect(0.7)
                }
                
                if let status = qrzTestStatus {
                    Text(status)
                        .font(.caption)
                        .foregroundColor(status.contains("Success") ? .green : .red)
                }
            }
        }
    }
    
    // MARK: - Email Delivery Settings
    private var emailDeliverySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email Delivery")
                .font(.title2.bold())
            Text("Choose how outgoing QSL card emails are dispatched to contacts.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Form {
                Section("Delivery Agent") {
                    Picker("Method", selection: $appState.settings.emailDeliveryMethod) {
                        ForEach(EmailDeliveryMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text(appState.settings.emailDeliveryMethod.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                
                if appState.settings.emailDeliveryMethod == .appleMail {
                    Section("Apple Mail Options") {
                        Toggle("Send silently in background without opening Mail compose window", isOn: $appState.settings.appleMailSendImmediately)
                        
                        Text("Uses your existing accounts configured in macOS Mail. No SMTP server configuration or app passwords required.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if appState.settings.emailDeliveryMethod == .defaultClient {
                    Section("Default Email Client") {
                        Text("When sending a card, AutoQSL will trigger macOS to open your default email app composer (Mail, Outlook, Thunderbird, Spark, etc.) pre-filled with recipient, body, and attached QSL card.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else if appState.settings.emailDeliveryMethod == .directSMTP {
                    Section("Server Connection") {
                        TextField("SMTP Host (e.g. smtp.gmail.com, mail.yourshack.com)", text: $appState.settings.smtpHost)
                        HStack {
                            Text("Port:")
                            TextField("Port", value: $appState.settings.smtpPort, format: .number)
                                .frame(width: 80)
                            Toggle("Use TLS / SSL", isOn: $appState.settings.smtpUseTLS)
                        }
                    }
                    
                    Section("Authentication") {
                        TextField("Username / Email", text: $appState.settings.smtpUsername)
                        SecureField("Password / App Password", text: $appState.settings.smtpPassword)
                    }
                    
                    Section("Sender Headers") {
                        TextField("Sender Display Name", text: $appState.settings.fromName)
                        TextField("From Email Address", text: $appState.settings.fromEmail)
                        TextField("Reply-To Address (optional)", text: $appState.settings.replyToEmail)
                    }
                }
            }
            .formStyle(.grouped)
            
            HStack {
                if appState.settings.emailDeliveryMethod == .appleMail {
                    Button("Test Apple Mail Integration") {
                        testAppleMail()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isTestingMail)
                    
                    if isTestingMail {
                        ProgressView().scaleEffect(0.7)
                    }
                    
                    if let status = mailTestStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("ready") || status.contains("Success") ? .green : .red)
                    }
                } else if appState.settings.emailDeliveryMethod == .directSMTP {
                    Button("Test SMTP Connection") {
                        testSMTP()
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.settings.smtpHost.isEmpty || isTestingSMTP)
                    
                    if isTestingSMTP {
                        ProgressView().scaleEffect(0.7)
                    }
                    
                    if let status = smtpTestStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Success") ? .green : .red)
                    }
                }
            }
        }
    }
    
    // MARK: - Email Templates
    private var emailTemplatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Email Subject & Body Templates")
                .font(.title2.bold())
            
            Form {
                Section("Subject Line Template") {
                    TextField("Subject", text: $appState.settings.emailSubjectTemplate)
                }
                
                Section("Body Message Template") {
                    TextEditor(text: $appState.settings.emailBodyTemplate)
                        .font(.system(size: 12, design: .monospaced))
                        .frame(height: 180)
                }
            }
            .formStyle(.grouped)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Available Placeholders:")
                    .font(.caption.bold())
                Text("{DX_CALL}, {DX_NAME}, {DX_GRID}, {DX_COUNTRY}, {BAND}, {MODE}, {FREQ}, {DATE}, {TIME}, {RST_SENT}, {RST_RCVD}, {COMMENT}, {MY_CALL}, {MY_NAME}, {MY_GRID}, {MY_CQ}, {MY_ITU}")
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }
    
    private func testQRZ() {
        isTestingQRZ = true
        qrzTestStatus = nil
        Task {
            let ok = await appState.qrzService.authenticate(
                username: appState.settings.qrzUsername,
                password: appState.settings.qrzPassword
            )
            isTestingQRZ = false
            if ok {
                qrzTestStatus = "Success! Logged into QRZ.com successfully."
            } else {
                qrzTestStatus = appState.qrzService.lastError ?? "Authentication failed"
            }
        }
    }
    
    private func testAppleMail() {
        isTestingMail = true
        mailTestStatus = nil
        Task {
            do {
                let msg = try await appState.appleMailService.testConnection()
                isTestingMail = false
                mailTestStatus = "Success: \(msg)"
            } catch {
                isTestingMail = false
                mailTestStatus = error.localizedDescription
            }
        }
    }
    
    private func testSMTP() {
        isTestingSMTP = true
        smtpTestStatus = nil
        Task {
            do {
                let msg = try await appState.smtpService.testConnection(settings: appState.settings)
                isTestingSMTP = false
                smtpTestStatus = "Success: \(msg)"
            } catch {
                isTestingSMTP = false
                smtpTestStatus = error.localizedDescription
            }
        }
    }

    private var sampleDatePreview: String {
        let order = appState.settings.dateOrder
        let sep = appState.settings.dateSeparator.symbol
        return order == .ddMMyyyy ? "23\(sep)08\(sep)2026" : "2026\(sep)08\(sep)23"
    }
}
