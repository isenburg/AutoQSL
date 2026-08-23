import SwiftUI

public struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTopic: HelpTopic = .overview
    @State private var isGerman: Bool = false

    public init() {}

    public enum HelpTopic: String, CaseIterable, Identifiable {
        case overview = "1. Introduction & Overview"
        case designer = "2. QSL Card Designer"
        case udpNetwork = "3. UDP & Logging Integration"
        case emailDelivery = "4. Email Dispatching"
        case templates = "5. Placeholders & Templates"
        case disclaimer = "6. Disclaimer & Privacy"
        case copyright = "7. Copyright & Credits"

        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .overview: return "info.circle.fill"
            case .designer: return "paintpalette.fill"
            case .udpNetwork: return "antenna.radiowaves.left.and.right"
            case .emailDelivery: return "paperplane.fill"
            case .templates: return "text.badge.checkmark"
            case .disclaimer: return "exclamationmark.shield.fill"
            case .copyright: return "c.circle.fill"
            }
        }
    }

    public var body: some View {
        NavigationSplitView {
            List(HelpTopic.allCases, selection: $selectedTopic) { topic in
                NavigationLink(value: topic) {
                    Label(isGerman ? topicTitleDe(topic) : topic.rawValue, systemImage: topic.icon)
                }
            }
            .navigationTitle(isGerman ? "Hilfe & Doku" : "Help & Documentation")
            .frame(minWidth: 240)
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Picker("Language", selection: $isGerman) {
                        Text("EN").tag(false)
                        Text("DE").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 80)
                }
            }
        } detail: {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailContent(for: selectedTopic)
                }
                .padding(28)
                .frame(maxWidth: 780, alignment: .leading)
            }
            .background(Color(NSColor.textBackgroundColor))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isGerman ? "Schließen" : "Close") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                }
            }
        }
        .frame(minWidth: 840, minHeight: 560)
    }

    private func topicTitleDe(_ topic: HelpTopic) -> String {
        switch topic {
        case .overview: return "1. Einführung & Übersicht"
        case .designer: return "2. QSL-Karten Designer"
        case .udpNetwork: return "3. UDP & Logger-Anbindung"
        case .emailDelivery: return "4. E-Mail Versand"
        case .templates: return "5. Platzhalter & Vorlagen"
        case .disclaimer: return "6. Haftungsausschluss & Datenschutz"
        case .copyright: return "7. Urheberrecht & Credits"
        }
    }

    @ViewBuilder
    private func detailContent(for topic: HelpTopic) -> some View {
        switch topic {
        case .overview:
            overviewSection
        case .designer:
            designerSection
        case .udpNetwork:
            udpNetworkSection
        case .emailDelivery:
            emailDeliverySection
        case .templates:
            templatesSection
        case .disclaimer:
            disclaimerSection
        case .copyright:
            copyrightSection
        }
    }

    // MARK: - 1. Overview
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isGerman ? "AutoQSL – Elektronische QSL-Karten Automatisierung" : "AutoQSL – Automated Electronic QSL Card Dispatcher")
                        .font(.title2.bold())
                    Text("Version \(APP_VERSION) (Build \(APP_BUILD_NUMBER))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Text(isGerman ?
                "AutoQSL ist eine spezialisierte native macOS-Applikation für Funkamateure zur vollautomatischen oder interaktiv bestätigten Generierung und Versendung personalisierter elektronischer QSL-Karten (eQSL)." :
                "AutoQSL is a dedicated native macOS application designed for amateur radio operators to automatically generate, render, and dispatch high-resolution electronic QSL cards (eQSL) via email in real time.")
                .font(.body)

            GroupBox(label: Label(isGerman ? "Hauptfunktionen auf einen Blick" : "Key Features at a Glance", systemImage: "sparkles")) {
                VStack(alignment: .leading, spacing: 8) {
                    featureRow(icon: "antenna.radiowaves.left.and.right", text: isGerman ?
                        "Live UDP-Listener: Empfängt geloggte QSOs in Echtzeit aus WSJT-X, JTDX, RUMlogNG und N1MM." :
                        "Live UDP Network Listener: Captures logged QSOs in real time from WSJT-X, JTDX, RUMlogNG, and N1MM.")
                    featureRow(icon: "person.text.rectangle.fill", text: isGerman ?
                        "QRZ.com XML API: Automatischer Abruf von Empfänger-Namen, E-Mail-Adressen, QTH und Maidenhead-Grid." :
                        "QRZ.com XML Integration: Automatic lookup of recipient name, email address, QTH, and Maidenhead grid.")
                    featureRow(icon: "paintpalette.fill", text: isGerman ?
                        "Visueller WYSIWYG Drag & Drop Designer: Individuelle Hintergründe, 3D-Präge-Effekte, Abzeichen und anpassbare QSO-Bestätigungstabellen." :
                        "Visual WYSIWYG Drag & Drop Designer: Custom backgrounds, 3D embossed text effects, club badges, and customizable QSO tables.")
                    featureRow(icon: "paperplane.fill", text: isGerman ?
                        "Flexible Versandwege: Nahtlose Apple Mail Integration (kein SMTP-Server nötig), Standard-Mail-Client oder direkter SMTP-Server." :
                        "Versatile Delivery: Seamless Apple Mail automation (no SMTP password required), default mail client, or direct SMTP dispatch.")
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 2. Card Designer
    private var designerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "QSL-Karten Designer & Layout-Werkzeuge" : "QSL Card Designer & Visual Layout Tools")
                .font(.title2.bold())
            
            Text(isGerman ?
                "Mit dem integrierten Designer erstellst du professionelle QSL-Karten im hochauflösenden 300-DPI Druckformat (Standard QSL 3.5 x 5.5 Zoll / 140x90mm oder Postkartenformat)." :
                "The built-in Card Designer lets you compose high-resolution (300 DPI print quality) QSL cards matching standard 3.5 x 5.5 inch / 140x90mm dimensions.")

            GroupBox(label: Label(isGerman ? "Bedienung & Gestaltungs-Optionen" : "Controls & Formatting Features", systemImage: "hand.draw.fill")) {
                VStack(alignment: .leading, spacing: 8) {
                    featureRow(icon: "cursorarrow.motionlines", text: isGerman ?
                        "Direktes Maus-Dragging: Klicke und ziehe beliebige Elemente direkt auf der Leinwand an ihre Wunschposition." :
                        "Direct Mouse Dragging: Click and drag any element directly on the canvas to reposition it smoothly.")
                    featureRow(icon: "textformat", text: isGerman ?
                        "Standard macOS Schriftarten-Auswahl (NSFontPanel): Zugriff auf alle installierten Schriftarten, Schriftschnitte und Größen." :
                        "Native macOS Font Panel (NSFontPanel): Access all system fonts, weights, styles, and sizes via 'Choose Font…'.")
                    featureRow(icon: "paintpalette", text: isGerman ?
                        "Standard macOS Farbwähler: Individuelle Farbauswahl für Texte, Tabellen-Hintergründe, Kopfzeilen und Gitterrahmen." :
                        "macOS Color Pickers: Precise color choices for text, table backgrounds, headers, and border lines.")
                    featureRow(icon: "shadow", text: isGerman ?
                        "Schatten-Schalter (Drop Shadow on/off): Schattenwurf für alle Textelemente separat aktivierbar mit Weichzeichnungs- und Abstandsreglern." :
                        "Shadow Toggles (on/off): Dedicated drop shadow switches with customizable blur radius, offsets, and opacity.")
                    featureRow(icon: "tablecells", text: isGerman ?
                        "QSO-Bestätigungstabelle: Konfigurierbare Spalten (QSO With, Date, UTC Time, Frequency, Report, Mode, Remarks) mit wählbarem Datumsformat." :
                        "QSO Confirmation Table: Configurable columns (QSO With, Date, UTC Time, Frequency, Report, Mode, Remarks) with custom date formats.")
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - 3. UDP & Logging
    private var udpNetworkSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "UDP Netzwerk-Listener & Logger-Einbindung" : "UDP Network Listener & Logging Integration")
                .font(.title2.bold())
            
            Text(isGerman ?
                "AutoQSL lauscht im Hintergrund auf eingehende UDP-Datenpakete deiner Logging- und Digimode-Software. Sobald ein QSO geloggt wird, übernimmt AutoQSL automatisch alle Kontaktdaten." :
                "AutoQSL runs background UDP listeners capturing QSO broadcast packets from your logging and digital mode software.")

            VStack(alignment: .leading, spacing: 10) {
                GroupBox(label: Text("WSJT-X / JTDX Setup")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isGerman ?
                            "1. Öffne in WSJT-X: Einstellungen > Reporting > UDP Server\n2. Aktiviere 'Accept UDP requests'\n3. Setze 'UDP Server' auf 127.0.0.1 und 'UDP Server Port' auf 2237" :
                            "1. Open WSJT-X Settings > Reporting > UDP Server\n2. Enable 'Accept UDP requests'\n3. Set 'UDP Server' to 127.0.0.1 and 'UDP Server Port' to 2237")
                            .font(.caption.monospaced())
                    }
                }

                GroupBox(label: Text("RUMlogNG Setup")) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(isGerman ?
                            "1. Öffne in RUMlogNG: Einstellungen > UDP\n2. Aktiviere 'Broadcast ADIF Data'\n3. Port: 2333 (Standard)" :
                            "1. Open RUMlogNG Preferences > UDP\n2. Enable 'Broadcast ADIF Data'\n3. Port: 2333 (Default)")
                            .font(.caption.monospaced())
                    }
                }
            }
        }
    }

    // MARK: - 4. Email Delivery
    private var emailDeliverySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "E-Mail Versandarten" : "Email Delivery Options")
                .font(.title2.bold())
            
            GroupBox(label: Label("1. Apple Mail (Empfohlen / Recommended)", systemImage: "applelogo")) {
                Text(isGerman ?
                    "Nutzt die native macOS Apple Mail App und deine dort bereits eingerichteten E-Mail-Konten. Kein Hinterlegen von Passwörtern oder SMTP-App-Passwörtern notwendig. Unterstützt wahlweise sofortigen Hintergrundversand oder das Öffnen des Mail-Verfassen-Fensters." :
                    "Dispatches directly via macOS Apple Mail using your existing configured accounts. No SMTP server setup or app passwords required. Supports silent instant dispatch or opening compose windows.")
                    .font(.caption)
            }

            GroupBox(label: Label("2. Standard macOS E-Mail Client", systemImage: "envelope.fill")) {
                Text(isGerman ?
                    "Öffnet beim Bestätigen das Verfassen-Fenster deines Standard-E-Mail-Programms (Mail, Outlook, Thunderbird, Spark etc.) inklusive Empfänger, Betreff, Text und angehängter QSL-Karte." :
                    "Opens your system default email client composer (Mail, Outlook, Thunderbird, Spark, etc.) pre-filled with recipient, body, and attached QSL card.")
                    .font(.caption)
            }

            GroupBox(label: Label("3. Direkter SMTP-Server", systemImage: "server.rack")) {
                Text(isGerman ?
                    "Sendet E-Mails direkt über einen SMTP-Server (Gmail, Outlook 365, eigener Mailhost). Unterstützt TLS/SSL-Verschlüsselung und Authentifizierung." :
                    "Sends directly via outbound SMTP server (Gmail, Outlook 365, custom host) with TLS/SSL encryption and authentication.")
                    .font(.caption)
            }
        }
    }

    // MARK: - 5. Templates
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "Platzhalter für E-Mail-Vorlagen & Texte" : "Email Template & Text Placeholders")
                .font(.title2.bold())
            
            Text(isGerman ?
                "Folgende Platzhalter werden in Betreff, Nachrichtentext und Freitext-Kartenfeldern automatisch durch die echten QSO- und Stationsdaten ersetzt:" :
                "The following tags are dynamically replaced with active QSO and station profile values:")

            VStack(alignment: .leading, spacing: 4) {
                placeholderRow(tag: "{DX_CALL}", desc: isGerman ? "Rufzeichen der Gegenstation" : "Recipient Callsign")
                placeholderRow(tag: "{DX_NAME}", desc: isGerman ? "Name der Gegenstation (aus QRZ)" : "Recipient Name (QRZ lookup)")
                placeholderRow(tag: "{DATE}", desc: isGerman ? "QSO-Datum nach gewähltem Format" : "QSO Date formatted per settings")
                placeholderRow(tag: "{TIME}", desc: isGerman ? "QSO-Uhrzeit in UTC (z. B. 14:05)" : "QSO Time in UTC (e.g. 14:05)")
                placeholderRow(tag: "{BAND}", desc: isGerman ? "Amateurfunkband (z. B. 20m)" : "Band (e.g. 20m)")
                placeholderRow(tag: "{MODE}", desc: isGerman ? "Betriebsart (z. B. FT8, CW, SSB)" : "Mode (e.g. FT8, CW, SSB)")
                placeholderRow(tag: "{FREQ}", desc: isGerman ? "Frequenz in MHz (z. B. 14.074 MHz)" : "Frequency in MHz")
                placeholderRow(tag: "{RST_SENT}", desc: isGerman ? "Gesendeter Signal-Report (z. B. -12, 599)" : "Sent RST Report")
                placeholderRow(tag: "{MY_CALL}", desc: isGerman ? "Eigenes Rufzeichen" : "Your Callsign")
                placeholderRow(tag: "{MY_GRID}", desc: isGerman ? "Eigener Maidenhead-Locator" : "Your Grid Square")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    // MARK: - 6. Disclaimer & Privacy
    private var disclaimerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.shield.fill")
                    .font(.title)
                    .foregroundColor(.orange)
                Text(isGerman ? "Haftungsausschluss & Datenschutz" : "Disclaimer & Privacy Notice")
                    .font(.title2.bold())
            }
            
            GroupBox(label: Text(isGerman ? "Haftungsausschluss (Disclaimer)" : "Warranty & Liability Disclaimer")) {
                Text(isGerman ?
                    "Die Software AutoQSL wird 'WIE BESEHEN' ('AS IS') und ohne Gewährleistung jeglicher Art bereitgestellt. Der Entwickler übernimmt keine Haftung für etwaige direkte oder indirekte Schäden, Datenverlust, Zustellfehler von E-Mails oder fehlerhafte Logbuch-Synchronisierungen, die aus der Nutzung der Software entstehen. Die Nutzung erfolgt auf eigenes Risiko des Funkamateurs." :
                    "AutoQSL is provided 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY ARISING FROM THE USE OF THIS SOFTWARE.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            GroupBox(label: Text(isGerman ? "Datenschutz & Lokale Speicherung" : "Privacy & Data Storage")) {
                Text(isGerman ?
                    "AutoQSL speichert alle Einstellungen, Vorlagen, Adressdaten und Logbücher ausschließlich lokal auf deinem Mac (~/Library/Application Support/AutoQSL/). Es werden keine Telemetriedaten, Zugangsdaten oder persönliche Informationen an externe Server übermittelt, mit Ausnahme der von dir konfigurierten QRZ.com-Abfragen und E-Mail-Empfänger." :
                    "AutoQSL operates entirely locally on your Mac. All credentials, settings, templates, and logs are stored locally (~/Library/Application Support/AutoQSL/). No telemetry or tracking data is collected or transmitted to external servers, except your direct queries to QRZ.com and outgoing email dispatches.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 7. Copyright & Credits
    private var copyrightSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "c.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("AutoQSL")
                        .font(.title2.bold())
                    Text("Copyright © 2024–2026 Georg Isenbürger · DJ6GI")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()

            Text(isGerman ?
                "Entwickelt für die weltweite Amateurfunk-Community als modernes, effizientes und elegantes macOS-Werkzeug für die elektronische QSL-Karten-Zustellung." :
                "Crafted for the global amateur radio community as a modern, high-speed, and elegant macOS utility for electronic QSL card delivery.")
                .font(.body)

            VStack(alignment: .leading, spacing: 6) {
                Text(isGerman ? "Autor & Funkstation:" : "Author & Amateur Station:")
                    .font(.caption.bold())
                Text("Georg Isenbürger (DJ6GI)")
                    .font(.subheadline)
                Text("DOK: M15 (Hohenlockstedt, Germany)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Link("GitHub Repository: isenburg/AutoQSL", destination: URL(string: "https://github.com/isenburg/AutoQSL")!)
                    .font(.caption.bold())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.body)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            Text(text)
                .font(.callout)
        }
    }

    private func placeholderRow(tag: String, desc: String) -> some View {
        HStack {
            Text(tag)
                .font(.caption.bold().monospaced())
                .foregroundColor(.accentColor)
                .frame(width: 130, alignment: .leading)
            Text(desc)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}
