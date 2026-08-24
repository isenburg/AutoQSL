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
    @State private var migrationMessage: String? = nil
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case appearance = "Appearance"
        case station = "Station Profile"
        case automation = "Automation & Modes"
        case storage = "Storage & iCloud"
        case udp = "UDP Logging"
        case qrz = "QRZ.com Lookup"
        case email = "Email Delivery"
        case templates = "Email Templates"
        
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .appearance: return "circle.lefthalf.filled"
            case .station: return "antenna.radiowaves.left.and.right"
            case .automation: return "gearshape.2"
            case .storage: return "icloud.circle.fill"
            case .udp: return "network"
            case .qrz: return "person.text.rectangle"
            case .email: return "envelope.badge"
            case .templates: return "doc.text"
            }
        }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Settings Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text("Settings")
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                
                List(SettingsTab.allCases, selection: $selectedTab) { tab in
                    Label(tab.rawValue, systemImage: tab.icon)
                        .tag(tab)
                }
                .listStyle(.sidebar)
            }
            .frame(width: 210)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .appearance:
                        appearanceSection
                    case .station:
                        stationProfileSection
                    case .automation:
                        automationSection
                    case .storage:
                        storageSettingsTab
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
                .frame(maxWidth: 780, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Appearance")
                .font(.title2.bold())
            Text("Choose how AutoQSL looks on your Mac.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Text("Color Scheme & Theme").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: "Theme Mode:", labelWidth: 120) {
                        Picker("", selection: $appState.settings.appearance) {
                            ForEach(AppAppearance.allCases) { item in
                                Text(item.rawValue).tag(item)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 320)
                    }
                    
                    Text(appearanceExplanation)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                .padding(10)
            }
        }
    }
    
    private var appearanceExplanation: String {
        switch appState.settings.appearance {
        case .system:
            return "Follows your macOS System Settings (automatically switches between Light and Dark mode)."
        case .light:
            return "Forces a clean, high-contrast light theme across all windows."
        case .dark:
            return "Forces a modern dark theme optimized for low-light shack environments."
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
            
            GroupBox(label: Text("Callsign & Operator").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    FormRow(label: "Callsign:") {
                        TextField("My Callsign", text: $appState.settings.myCallsign)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                            .onChange(of: appState.settings.myCallsign) { _, newCall in
                                appState.settings.autofillStationZonesAndCountry(for: newCall, overwriteNonEmpty: true)
                            }
                    }
                    
                    FormRow(label: "Operator:") {
                        TextField("Operator Name", text: $appState.settings.myName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 240)
                    }
                }
                .padding(8)
            }
            
            GroupBox(label: Text("QTH & Address").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    FormRow(label: "Street:") {
                        TextField("Street Address", text: $appState.settings.myStreet)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 280)
                    }
                    
                    FormRow(label: "City:") {
                        TextField("City", text: $appState.settings.myCity)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 240)
                    }
                    
                    FormRow(label: "State / Zip:") {
                        TextField("State / Province / Zip", text: $appState.settings.myState)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    
                    FormRow(label: "Country:") {
                        TextField("Country", text: $appState.settings.myCountry)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                }
                .padding(8)
            }
            
            GroupBox(label: Text("Location & Zones").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    FormRow(label: "Maidenhead:") {
                        TextField("e.g. FM18iv", text: $appState.settings.myGrid)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                    
                    FormRow(label: "CQ Zone:") {
                        HStack(spacing: 16) {
                            TextField("CQ Zone", text: $appState.settings.myCQZone)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            Text("ITU Zone:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            TextField("ITU Zone", text: $appState.settings.myITUZone)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    
                    FormRow(label: "County:") {
                        TextField("County / Region", text: $appState.settings.myCounty)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    
                    HStack {
                        Text("")
                            .frame(width: 110)
                        Button("Auto-detect Country & Zones from Callsign") {
                            appState.settings.autofillStationZonesAndCountry(for: appState.settings.myCallsign, overwriteNonEmpty: true)
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
                .padding(8)
            }
            
            GroupBox(label: Text("Default Greeting & Date Format").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: "Greeting:") {
                        TextField("Comment printed on QSL table", text: $appState.settings.defaultComment)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 380)
                    }
                    
                    FormRow(label: "Date Order:") {
                        Picker("", selection: $appState.settings.dateOrder) {
                            ForEach(DateOrder.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }
                    
                    FormRow(label: "Separator:") {
                        Picker("", selection: $appState.settings.dateSeparator) {
                            ForEach(DateSeparator.allCases) { sep in
                                Text(sep.rawValue).tag(sep)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }
                    
                    FormRow(label: "Preview:") {
                        Text(sampleDatePreview)
                            .font(.subheadline.monospaced().bold())
                            .foregroundColor(.accentColor)
                    }
                }
                .padding(8)
            }
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
            
            GroupBox(label: Text("Sending Mode").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
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
                .padding(8)
            }
        }
    }
    
    // MARK: - UDP Logging Settings
    private var udpSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("UDP Network Listeners")
                .font(.title2.bold())
            Text("AutoQSL listens on local UDP ports to receive QSO logged broadcasts from WSJT-X etc. and RL (RUMlog). Each application can be configured with its own port and Multicast (MC) or Unicast (UC) IP address.")
                .font(.caption)
                .foregroundColor(.secondary)
                
            GroupBox(label: Label("Important Note on Duplicates", systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)) {
                Text("If you have switched on UDP for WSJTX and RumLog in AutoQSL you will get duplicate QSLs depending on RumLog's configuration. It is recommended to use either or.")
                    .font(.caption)
            }
            
            // Section 1: WSJT-X
            GroupBox(label: Text("WSJT-X etc.").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable WSJT-X etc. UDP Listener", isOn: $appState.settings.wsjtxEnabled)
                    
                    FormRow(label: "IP Address:") {
                        TextField("", text: $appState.settings.wsjtxAddress)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        
                        let isMC = AppSettings.isMulticast(address: appState.settings.wsjtxAddress)
                        Text(isMC ? "Multicast (MC)" : "Unicast (UC)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isMC ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundColor(isMC ? .blue : .orange)
                            .cornerRadius(4)
                        
                        Button("224.0.0.1 (MC)") { appState.settings.wsjtxAddress = "224.0.0.1" }
                            .buttonStyle(.link)
                            .font(.caption2)
                        Button("127.0.0.1 (UC)") { appState.settings.wsjtxAddress = "127.0.0.1" }
                            .buttonStyle(.link)
                            .font(.caption2)
                    }
                    
                    FormRow(label: "Port:") {
                        TextField("", value: $appState.settings.wsjtxPort, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                }
                .padding(8)
            }
            
            // Section 2: RL (RUMlog)
            GroupBox(label: Text("RL (RUMlog)").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable RL (RUMlog) UDP Listener", isOn: $appState.settings.rumlogEnabled)
                    
                    FormRow(label: "IP Address:") {
                        TextField("", text: $appState.settings.rumlogAddress)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        
                        let isMC = AppSettings.isMulticast(address: appState.settings.rumlogAddress)
                        Text(isMC ? "Multicast (MC)" : "Unicast (UC)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isMC ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundColor(isMC ? .blue : .orange)
                            .cornerRadius(4)
                        
                        Button("127.0.0.1 (UC)") { appState.settings.rumlogAddress = "127.0.0.1" }
                            .buttonStyle(.link)
                            .font(.caption2)
                        Button("224.0.0.1 (MC)") { appState.settings.rumlogAddress = "224.0.0.1" }
                            .buttonStyle(.link)
                            .font(.caption2)
                    }
                    
                    FormRow(label: "Port:") {
                        TextField("", value: $appState.settings.rumlogPort, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                }
                .padding(8)
            }
            
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
            
            if !appState.udpListener.listeners.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Active UDP Sockets:")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(appState.udpListener.listeners.values), id: \.id) { l in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(l.isRunning ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text(l.name)
                                .font(.caption.bold())
                            
                            Text(verbatim: "\(l.address):\(l.port)")
                                .font(.caption.monospaced())
                                .foregroundColor(.secondary)
                            
                            Text(l.isMulticast ? "MC" : "UC")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(l.isMulticast ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                                .foregroundColor(l.isMulticast ? .blue : .orange)
                                .cornerRadius(3)
                            
                            if l.packetsReceived > 0 {
                                Text(verbatim: "\(l.packetsReceived) packets")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let err = l.errorMessage {
                                Text(err)
                                    .font(.caption2)
                                    .foregroundColor(.red)
                            }
                            
                            Spacer()
                        }
                    }
                }
                .padding(10)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
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
            
            GroupBox(label: Text("Account Credentials").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Enable QRZ.com Lookups", isOn: $appState.settings.qrzEnabled)
                    
                    FormRow(label: "Username:") {
                        TextField("QRZ Callsign / Username", text: $appState.settings.qrzUsername)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }
                    
                    FormRow(label: "Password:") {
                        SecureField("QRZ.com Password", text: $appState.settings.qrzPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }
                }
                .padding(8)
            }
            
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
            
            GroupBox(label: Text("Delivery Method").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
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
                .padding(8)
            }
            
            if appState.settings.emailDeliveryMethod == .appleMail {
                GroupBox(label: Text("Apple Mail Options").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Send silently in background without opening Mail compose window", isOn: $appState.settings.appleMailSendImmediately)
                        
                        Text("Uses your existing accounts configured in macOS Mail. No SMTP server configuration or app passwords required.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(8)
                }
            } else if appState.settings.emailDeliveryMethod == .defaultClient {
                GroupBox(label: Text("Default Email Client").font(.headline)) {
                    Text("When sending a card, AutoQSL will trigger macOS to open your default email app composer (Mail, Outlook, Thunderbird, Spark, etc.) pre-filled with recipient, body, and attached QSL card.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                }
            } else if appState.settings.emailDeliveryMethod == .directSMTP {
                GroupBox(label: Text("Server Connection").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        FormRow(label: "SMTP Host:") {
                            TextField("e.g. smtp.gmail.com", text: $appState.settings.smtpHost)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 240)
                        }
                        
                        FormRow(label: "Port:") {
                            HStack(spacing: 16) {
                                TextField("", value: $appState.settings.smtpPort, format: .number.grouping(.never))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                Toggle("Use TLS / SSL", isOn: $appState.settings.smtpUseTLS)
                            }
                        }
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Authentication").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        FormRow(label: "Username:") {
                            TextField("Username / Email", text: $appState.settings.smtpUsername)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 240)
                        }
                        
                        FormRow(label: "Password:") {
                            SecureField("Password / App Password", text: $appState.settings.smtpPassword)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 240)
                        }
                    }
                    .padding(8)
                }
                
                GroupBox(label: Text("Sender Headers").font(.headline)) {
                    VStack(alignment: .leading, spacing: 10) {
                        FormRow(label: "From Name:") {
                            TextField("Display Name", text: $appState.settings.fromName)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 240)
                        }
                        
                        FormRow(label: "From Email:") {
                            TextField("Sender Email", text: $appState.settings.fromEmail)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 240)
                        }
                        
                        FormRow(label: "Reply-To:") {
                            TextField("Optional Reply-To Address", text: $appState.settings.replyToEmail)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 240)
                        }
                    }
                    .padding(8)
                }
            }
            
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
            
            GroupBox(label: Text("Subject Line Template").font(.headline)) {
                FormRow(label: "Subject:") {
                    TextField("Subject Line", text: $appState.settings.emailSubjectTemplate)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                }
                .padding(8)
            }
            
            GroupBox(label: Text("Body Message Template").font(.headline)) {
                TextEditor(text: $appState.settings.emailBodyTemplate)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 180)
                    .padding(4)
            }
            
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
    
    // MARK: - Storage & iCloud Sync
    private var storageSettingsTab: some View {
        VStack(alignment: .leading, spacing: 18) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Storage & Synchronization Engine", systemImage: "icloud.and.arrow.up.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text("Choose whether AutoQSL stores all configuration, card templates, QSO queue items, and rendered cards locally on this Mac, or syncs them seamlessly across all your Macs via iCloud Drive.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    FormRow(label: "Storage Location:", labelWidth: 120) {
                        Picker("", selection: Binding(
                            get: { appState.settings.storageLocation },
                            set: { newLoc in
                                appState.switchStorageLocation(to: newLoc, migrateCurrentData: true)
                            }
                        )) {
                            ForEach(StorageLocation.allCases) { loc in
                                Text(loc.rawValue).tag(loc)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    FormRow(label: "Active Path:", labelWidth: 120) {
                        Text(PersistenceService.shared.storageDirectory(for: appState.settings.storageLocation).path)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    
                    FormRow(label: "iCloud Status:", labelWidth: 120) {
                        HStack(spacing: 8) {
                            if PersistenceService.shared.isICloudAvailable {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("iCloud Drive is configured & accessible on this Mac")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("iCloud Drive directory not found. Please log into Apple ID in System Settings.")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                    
                    if appState.settings.storageLocation == .iCloud {
                        FormRow(label: "Auto Sync:", labelWidth: 120) {
                            Toggle("Automatically sync templates and queue across Macs", isOn: $appState.settings.autoSyncICloud)
                                .font(.callout)
                        }
                    }
                }
                .padding(6)
            }
            
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Data Migration & Finder Access", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.headline)
                    
                    Text("Easily transfer your existing data between Local storage and iCloud Drive, or inspect the stored JSON data and rendered card images.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            migrateData(to: .iCloud)
                        }) {
                            Label("Copy Local Data to iCloud", systemImage: "arrow.up.doc.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            migrateData(to: .local)
                        }) {
                            Label("Restore from iCloud to Local", systemImage: "arrow.down.doc.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            PersistenceService.shared.revealInFinder(location: appState.settings.storageLocation)
                        }) {
                            Label("Reveal in Finder", systemImage: "folder.fill")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if let msg = migrationMessage {
                        HStack {
                            Image(systemName: msg.contains("Error") || msg.contains("warning") ? "exclamationmark.circle.fill" : "checkmark.circle.fill")
                                .foregroundColor(msg.contains("Error") || msg.contains("warning") ? .orange : .green)
                            Text(msg)
                                .font(.caption)
                                .foregroundColor(msg.contains("Error") || msg.contains("warning") ? .orange : .green)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(6)
            }
        }
    }
    
    private func migrateData(to destination: StorageLocation) {
        let source: StorageLocation = (destination == .iCloud) ? .local : .iCloud
        do {
            try PersistenceService.shared.migrateData(from: source, to: destination)
            migrationMessage = "Success: Copied all settings, templates, queue history, and rendered cards to \(destination.rawValue)."
            if appState.settings.storageLocation == destination {
                appState.switchStorageLocation(to: destination, migrateCurrentData: false)
            }
        } catch {
            migrationMessage = "Error migrating data: \(error.localizedDescription)"
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
