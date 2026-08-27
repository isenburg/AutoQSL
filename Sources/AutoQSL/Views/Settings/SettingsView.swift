import SwiftUI

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    @State private var selectedTab: SettingsTab = .station
    @State private var qrzTestStatus: String? = nil
    @State private var isTestingQRZ: Bool = false
    @State private var hamqthTestStatus: String? = nil
    @State private var isTestingHamQTH: Bool = false
    @State private var smtpTestStatus: String? = nil
    @State private var isTestingSMTP: Bool = false
    @State private var mailTestStatus: String? = nil
    @State private var isTestingMail: Bool = false
    @State private var migrationMessage: String? = nil
    
    enum SettingsTab: String, CaseIterable, Identifiable {
        case language = "Language"
        case appearance = "Appearance"
        case station = "Station Profile"
        case automation = "Automation & Modes"
        case storage = "Storage & iCloud"
        case udp = "UDP Logging"
        case callbook = "Callbook Lookups"
        case email = "Email Delivery"
        case templates = "Email Templates"
        
        var id: String { rawValue }
        
        func localizedName(_ lang: AppLanguage) -> String {
            switch self {
            case .language: return L10n.tr(lang, "Language", "Sprache")
            case .appearance: return L10n.tr(lang, "Appearance", "Erscheinungsbild")
            case .station: return L10n.tr(lang, "Station Profile", "Stationsprofil")
            case .automation: return L10n.tr(lang, "Automation & Modes", "Automation & Betriebsmodus")
            case .storage: return L10n.tr(lang, "Storage & iCloud", "Speicher & iCloud")
            case .udp: return L10n.tr(lang, "UDP Logging", "UDP-Logging")
            case .callbook: return L10n.tr(lang, "Callbook Lookups", "Callbook-Abfragen")
            case .email: return L10n.tr(lang, "Email Delivery", "E-Mail-Versand")
            case .templates: return L10n.tr(lang, "Email Templates", "E-Mail-Vorlagen")
            }
        }
        var icon: String {
            switch self {
            case .language: return "globe"
            case .appearance: return "circle.lefthalf.filled"
            case .station: return "antenna.radiowaves.left.and.right"
            case .automation: return "gearshape.2"
            case .storage: return "icloud.circle.fill"
            case .udp: return "network"
            case .callbook: return "person.text.rectangle"
            case .email: return "envelope.badge"
            case .templates: return "doc.text"
            }
        }
    }
    
    public var body: some View {
        HStack(spacing: 0) {
            // Settings Sidebar
            VStack(alignment: .leading, spacing: 0) {
                Text(L10n.tr(appState.settings.appLanguage, "Settings", "Einstellungen"))
                    .font(.headline)
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 8)
                
                List(SettingsTab.allCases, selection: $selectedTab) { tab in
                    Label(tab.localizedName(appState.settings.appLanguage), systemImage: tab.icon)
                        .tag(tab)
                }
                .listStyle(.sidebar)
                
                Divider()
                
                Button(action: {
                    openWindow(id: "help")
                }) {
                    HStack {
                        Label(L10n.Nav.helpDocs(appState.settings.appLanguage), systemImage: "questionmark.circle")
                            .font(.caption)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .frame(width: 210)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    switch selectedTab {
                    case .language:
                        languageSection
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
                    case .callbook:
                        callbookSection
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
    
    // MARK: - Language Section
    private var languageSection: some View {
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Language", "Sprache"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "Choose your preferred interface language for AutoQSL.", "Wähle deine bevorzugte Sprache für die Benutzeroberfläche von AutoQSL."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Label(L10n.tr(lang, "Application Language", "Sprache der Anwendung"), systemImage: "globe").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $appState.settings.appLanguage) {
                        ForEach(AppLanguage.allCases, id: \.self) { l in
                            Text(l.displayName).tag(l)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text(L10n.tr(lang, "Changes take effect immediately across all windows, menus, dialogs, and in-app help documentation.", "Änderungen werden sofort in allen Fenstern, Menüs, Dialogen und der integrierten Hilfe wirksam."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
            }
        }
    }
    
    // MARK: - Appearance Section
    private var appearanceSection: some View {
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Appearance", "Erscheinungsbild"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "Choose how AutoQSL looks on your Mac.", "Wähle das Erscheinungsbild von AutoQSL auf deinem Mac."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Text(L10n.tr(lang, "Color Scheme & Theme", "Farbschema & Design")).font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: L10n.tr(lang, "Theme Mode:", "Design-Modus:"), labelWidth: 120) {
                        Picker("", selection: $appState.settings.appearance) {
                            ForEach(AppAppearance.allCases) { item in
                                Text(item.localizedName(lang)).tag(item)
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
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Station Profile", "Stationsprofil"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "Your amateur radio station details are displayed on the QSL card and email greetings.", "Deine Stationsdaten werden auf der QSL-Karte und in den E-Mail-Grüßen verwendet."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Text(L10n.tr(lang, "Callsign & Operator", "Rufzeichen & Operator")).font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    FormRow(label: L10n.tr(lang, "Callsign:", "Rufzeichen:")) {
                        TextField("My Callsign", text: $appState.settings.myCallsign)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                            .onChange(of: appState.settings.myCallsign) { _, newCall in
                                appState.settings.autofillStationZonesAndCountry(for: newCall, overwriteNonEmpty: true)
                            }
                    }
                    
                    FormRow(label: L10n.tr(lang, "Operator:", "Name / Operator:")) {
                        TextField("Operator Name", text: $appState.settings.myName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 240)
                    }
                }
                .padding(8)
            }
            
            GroupBox(label: Text(L10n.tr(lang, "QTH & Address", "QTH & Adresse")).font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    FormRow(label: L10n.tr(lang, "Street:", "Straße:")) {
                        TextField("Street Address", text: $appState.settings.myStreet)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 280)
                    }
                    
                    FormRow(label: L10n.tr(lang, "City:", "Stadt / QTH:")) {
                        TextField("City", text: $appState.settings.myCity)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 240)
                    }
                    
                    FormRow(label: L10n.tr(lang, "State / Zip:", "Bundesland / PLZ:")) {
                        TextField("State / Province / Zip", text: $appState.settings.myState)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    
                    FormRow(label: L10n.tr(lang, "Country:", "Land / DXCC:")) {
                        TextField("Country", text: $appState.settings.myCountry)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                }
                .padding(8)
            }
            
            GroupBox(label: Text(L10n.tr(lang, "Location & Zones", "Standort & Zonen")).font(.headline)) {
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
                    
                    FormRow(label: L10n.tr(lang, "County:", "Kreis / DOK:")) {
                        TextField("County / Region", text: $appState.settings.myCounty)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                    }
                    
                    HStack {
                        Text("")
                            .frame(width: 110)
                        Button(L10n.tr(lang, "Auto-detect Country & Zones from Callsign", "Land & Zonen automatisch aus Rufzeichen ermitteln")) {
                            appState.settings.autofillStationZonesAndCountry(for: appState.settings.myCallsign, overwriteNonEmpty: true)
                        }
                        .buttonStyle(.link)
                        .font(.caption)
                    }
                }
                .padding(8)
            }
            
            GroupBox(label: Text(L10n.tr(lang, "Default Greeting & Date Format", "Standard-Grußtext & Datumsformat")).font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    FormRow(label: L10n.tr(lang, "Greeting:", "Grußtext:")) {
                        TextField("Comment printed on QSL table", text: $appState.settings.defaultComment)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 380)
                    }
                    
                    FormRow(label: L10n.tr(lang, "Date Order:", "Datumsreihenfolge:")) {
                        Picker("", selection: $appState.settings.dateOrder) {
                            ForEach(DateOrder.allCases) { opt in
                                Text(opt.rawValue).tag(opt)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }
                    
                    FormRow(label: L10n.tr(lang, "Separator:", "Trennzeichen:")) {
                        Picker("", selection: $appState.settings.dateSeparator) {
                            ForEach(DateSeparator.allCases) { sep in
                                Text(sep.rawValue).tag(sep)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }
                    
                    FormRow(label: L10n.tr(lang, "Preview:", "Vorschau:")) {
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
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Automation & Dispatch Modes", "Automation & Versand-Modi"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "Control how QSOs received over UDP network broadcasts are handled and dispatched.", "Steuert, wie über das Netzwerk empfangene QSOs verarbeitet und versendet werden."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Text(L10n.tr(lang, "Sending Mode", "Betriebsmodus")).font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Mode", selection: $appState.settings.sendingMode) {
                        ForEach(SendingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text(appState.settings.sendingMode.localizedDescription(appState.settings.appLanguage))
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
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "UDP Network Listeners", "UDP-Netzwerkempfänger"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "AutoQSL listens on local UDP ports to receive QSO logged broadcasts from WSJT-X etc. and RL (RUMlog). Each application can be configured with its own port and Multicast (MC) or Unicast (UC) IP address.", "AutoQSL lauscht auf lokalen UDP-Ports auf QSO-Broadcasts von WSJT-X und RUMlog. Jede Anwendung kann mit eigenem Port und Multicast (MC) oder Unicast (UC) konfiguriert werden."))
                .font(.caption)
                .foregroundColor(.secondary)
                
            GroupBox(label: Label("Important Note on Duplicates", systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)) {
                Text(L10n.tr(lang, "If you have switched on UDP for WSJTX and RumLog in AutoQSL you will get duplicate QSLs depending on RumLog's configuration. It is recommended to use either or.", "Wenn UDP für WSJT-X und RUMlog gleichzeitig aktiv ist, können je nach RUMlog-Konfiguration doppelte QSLs entstehen. Es wird empfohlen, nur eine Quelle zu aktivieren."))
                    .font(.caption)
            }
            
            // Section 1: WSJT-X
            GroupBox(label: Text("WSJT-X etc.").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(L10n.tr(lang, "Enable WSJT-X etc. UDP Listener", "WSJT-X UDP-Empfänger aktivieren"), isOn: $appState.settings.wsjtxEnabled)
                    
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
                    Toggle(L10n.tr(lang, "Enable RL (RUMlog) UDP Listener", "RUMlog UDP-Empfänger aktivieren"), isOn: $appState.settings.rumlogEnabled)
                    
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
            
            // Section 3: MacLoggerDX
            GroupBox(label: Text("MacLoggerDX").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(L10n.tr(lang, "Enable MacLoggerDX UDP Listener", "MacLoggerDX UDP-Empfänger aktivieren"), isOn: $appState.settings.macloggerEnabled)
                    
                    FormRow(label: "IP Address:") {
                        TextField("", text: $appState.settings.macloggerAddress)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                        
                        let isMC = AppSettings.isMulticast(address: appState.settings.macloggerAddress)
                        Text(isMC ? "Multicast (MC)" : "Unicast (UC)")
                            .font(.system(size: 11, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(isMC ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15))
                            .foregroundColor(isMC ? .blue : .orange)
                            .cornerRadius(4)
                        
                        Button("127.0.0.1 (UC)") { appState.settings.macloggerAddress = "127.0.0.1" }
                            .buttonStyle(.link)
                            .font(.caption2)
                        Button("224.0.0.1 (MC)") { appState.settings.macloggerAddress = "224.0.0.1" }
                            .buttonStyle(.link)
                            .font(.caption2)
                    }
                    
                    FormRow(label: "Port:") {
                        TextField("", value: $appState.settings.macloggerPort, format: .number.grouping(.never))
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 140)
                    }
                }
                .padding(8)
            }

            HStack {
                Button(L10n.tr(lang, "Restart Listeners", "Empfänger neu starten")) {
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
    
    // MARK: - Callbook Settings (QRZ.com & HamQTH)
    private var callbookSection: some View {
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Callbook Lookups (QRZ.com & HamQTH)", "Callbook-Abfragen (QRZ.com & HamQTH)"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "Retrieves recipient email addresses, QTH, names, and grid squares automatically from QRZ.com and/or HamQTH.com XML databases.", "Ermittelt E-Mail-Adressen, QTH, Namen und Grid-Locators automatisch aus den XML-Datenbanken von QRZ.com und/oder HamQTH.com."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Text(L10n.tr(lang, "Lookup Provider & Priority", "Callbook-Dienst & Priorität")).font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Provider:", selection: $appState.settings.callbookProvider) {
                        ForEach(CallbookProvider.allCases) { prov in
                            Text(prov.rawValue).tag(prov)
                        }
                    }
                    .pickerStyle(.radioGroup)
                }
                .padding(8)
            }
            
            // QRZ.com Configuration
            GroupBox(label: Label("QRZ.com XML Subscription", systemImage: "globe").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(L10n.tr(lang, "Enable QRZ.com Lookups", "QRZ.com-Abfragen aktivieren"), isOn: $appState.settings.qrzEnabled)
                    
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
                    
                    HStack {
                        Button(L10n.tr(lang, "Test QRZ Connection", "QRZ-Verbindung testen")) {
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
                .padding(8)
            }
            
            // HamQTH.com Configuration
            GroupBox(label: Label("HamQTH.com XML API (Free)", systemImage: "antenna.radiowaves.left.and.right").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle(L10n.tr(lang, "Enable HamQTH.com Lookups", "HamQTH.com-Abfragen aktivieren"), isOn: $appState.settings.hamqthEnabled)
                    
                    FormRow(label: "Username / Call:", labelWidth: 120) {
                        TextField("HamQTH Callsign / Login", text: $appState.settings.hamqthUsername)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }
                    
                    FormRow(label: "Password:", labelWidth: 120) {
                        SecureField("HamQTH Password", text: $appState.settings.hamqthPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 220)
                    }
                    
                    HStack {
                        Button(L10n.tr(lang, "Test HamQTH Connection", "HamQTH-Verbindung testen")) {
                            testHamQTH()
                        }
                        .buttonStyle(.bordered)
                        .disabled(appState.settings.hamqthUsername.isEmpty || appState.settings.hamqthPassword.isEmpty || isTestingHamQTH)
                        
                        if isTestingHamQTH {
                            ProgressView().scaleEffect(0.7)
                        }
                        
                        if let status = hamqthTestStatus {
                            Text(status)
                                .font(.caption)
                                .foregroundColor(status.contains("Success") ? .green : .red)
                        }
                    }
                }
                .padding(8)
            }
        }
    }
    
    // MARK: - Email Delivery Settings
    private var emailDeliverySection: some View {
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Email Delivery", "E-Mail-Versand"))
                .font(.title2.bold())
            Text(L10n.tr(lang, "Choose how outgoing QSL card emails are dispatched to contacts.", "Wähle, wie ausgehende QSL-Karten per E-Mail an Kontakte versendet werden."))
                .font(.caption)
                .foregroundColor(.secondary)
            
            GroupBox(label: Text(L10n.tr(lang, "Delivery Method", "Versandmethode")).font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Method", selection: $appState.settings.emailDeliveryMethod) {
                        ForEach(EmailDeliveryMethod.allCases) { method in
                            Text(method.rawValue).tag(method)
                        }
                    }
                    .pickerStyle(.radioGroup)
                    
                    Text(appState.settings.emailDeliveryMethod.localizedDescription(appState.settings.appLanguage))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }
                .padding(8)
            }
            
            if appState.settings.emailDeliveryMethod == .appleMail {
                GroupBox(label: Text(L10n.tr(lang, "Apple Mail Options", "Apple Mail Optionen")).font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle(L10n.tr(lang, "Send silently in background without opening Mail compose window", "Lautlos im Hintergrund senden (ohne Mail-Fenster zu öffnen)"), isOn: $appState.settings.appleMailSendImmediately)
                        
                        Text(L10n.tr(lang, "Uses your existing accounts configured in macOS Mail. No SMTP server configuration or app passwords required.", "Verwendet deine in macOS Mail eingerichteten Konten. Keine SMTP-Server-Konfiguration nötig."))
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
                    Button(L10n.tr(lang, "Test Apple Mail Integration", "Apple Mail Integration testen")) {
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
                    Button(L10n.tr(lang, "Test SMTP Connection", "SMTP-Verbindung testen")) {
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
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.tr(lang, "Email Subject & Body Templates", "E-Mail-Betreff & Nachrichtenvorlagen"))
                .font(.title2.bold())
            
            GroupBox(label: Text(L10n.tr(lang, "Subject Line Template", "Betreffzeilen-Vorlage")).font(.headline)) {
                FormRow(label: L10n.tr(lang, "Subject:", "Betreff:")) {
                    TextField("Subject Line", text: $appState.settings.emailSubjectTemplate)
                        .textFieldStyle(.roundedBorder)
                        .frame(maxWidth: .infinity)
                }
                .padding(8)
            }
            
            GroupBox(label: Text(L10n.tr(lang, "Body Message Template", "Nachrichtentext-Vorlage")).font(.headline)) {
                TextEditor(text: $appState.settings.emailBodyTemplate)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 180)
                    .padding(4)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.tr(lang, "Available Placeholders:", "Verfügbare Platzhalter:"))
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
        let lang = appState.settings.appLanguage
        return VStack(alignment: .leading, spacing: 18) {
            GroupBox {
                VStack(alignment: .leading, spacing: 12) {
                    Label(L10n.tr(lang, "Storage & Synchronization Engine", "Speicher & iCloud-Synchronisation"), systemImage: "icloud.and.arrow.up.fill")
                        .font(.headline)
                        .foregroundColor(.accentColor)
                    
                    Text(L10n.tr(lang, "Choose whether AutoQSL stores all configuration, card templates, QSO queue items, and rendered cards locally on this Mac, or syncs them seamlessly across all your Macs via iCloud Drive.", "Wähle, ob AutoQSL alle Einstellungen, Vorlagen, QSOs und gerenderten Karten lokal auf diesem Mac speichert oder nahtlos über iCloud Drive zwischen deinen Macs synchronisiert."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    FormRow(label: L10n.tr(lang, "Storage Location:", "Speicherort:"), labelWidth: 120) {
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
                    
                    FormRow(label: L10n.tr(lang, "Active Path:", "Aktueller Pfad:"), labelWidth: 120) {
                        Text(PersistenceService.shared.storageDirectory(for: appState.settings.storageLocation).path)
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .textSelection(.enabled)
                    }
                    
                    FormRow(label: L10n.tr(lang, "iCloud Status:", "iCloud-Status:"), labelWidth: 120) {
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
                    Label(L10n.tr(lang, "Data Migration & Finder Access", "Datenmigration & Finder-Zugriff"), systemImage: "arrow.triangle.2.circlepath.circle.fill")
                        .font(.headline)
                    
                    Text(L10n.tr(lang, "Easily transfer your existing data between Local storage and iCloud Drive, or inspect the stored JSON data and rendered card images.", "Übertrage vorhandene Daten einfach zwischen lokalem Speicher und iCloud Drive oder öffne das Datenverzeichnis im Finder."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Divider()
                    
                    HStack(spacing: 12) {
                        Button(action: {
                            migrateData(to: .iCloud)
                        }) {
                            Label(L10n.tr(lang, "Copy Local Data to iCloud", "Lokale Daten nach iCloud kopieren"), systemImage: "arrow.up.doc.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            migrateData(to: .local)
                        }) {
                            Label(L10n.tr(lang, "Restore from iCloud to Local", "Aus iCloud lokal wiederherstellen"), systemImage: "arrow.down.doc.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            PersistenceService.shared.revealInFinder(location: appState.settings.storageLocation)
                        }) {
                            Label(L10n.tr(lang, "Reveal in Finder", "Im Finder anzeigen"), systemImage: "folder.fill")
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
    
    private func testHamQTH() {
        isTestingHamQTH = true
        hamqthTestStatus = nil
        Task {
            let ok = await appState.hamqthService.authenticate(
                username: appState.settings.hamqthUsername,
                password: appState.settings.hamqthPassword
            )
            isTestingHamQTH = false
            if ok {
                hamqthTestStatus = "Success! Logged into HamQTH.com successfully."
            } else {
                hamqthTestStatus = appState.hamqthService.lastError ?? "Authentication failed"
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
