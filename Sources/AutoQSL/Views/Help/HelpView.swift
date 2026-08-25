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
        case automationModes = "5. Automation & Modes"
        case templates = "6. Placeholders & Templates"
        case storageSync = "7. iCloud Storage & Sync"
        case disclaimer = "8. Disclaimer & Privacy"
        case copyright = "9. Copyright & Credits"
        case changelog = "10. Changelog & Versions"

        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .overview: return "info.circle.fill"
            case .designer: return "paintpalette.fill"
            case .udpNetwork: return "antenna.radiowaves.left.and.right"
            case .emailDelivery: return "paperplane.fill"
            case .automationModes: return "gearshape.2"
            case .templates: return "text.badge.checkmark"
            case .storageSync: return "icloud.circle.fill"
            case .disclaimer: return "exclamationmark.shield.fill"
            case .copyright: return "c.circle.fill"
            case .changelog: return "clock.arrow.circlepath"
            }
        }
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Help Topics Sidebar
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(isGerman ? "Hilfe & Doku" : "Help & Docs")
                        .font(.headline)
                    Spacer()
                    Picker("", selection: $isGerman) {
                        Text("EN").tag(false)
                        Text("DE").tag(true)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 75)
                }
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 8)
                
                List(HelpTopic.allCases, selection: $selectedTopic) { topic in
                    Label(isGerman ? topicTitleDe(topic) : topic.rawValue, systemImage: topic.icon)
                        .tag(topic)
                }
                .listStyle(.sidebar)
            }
            .frame(width: 220)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Detail Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    detailContent(for: selectedTopic)
                }
                .padding(28)
                .frame(maxWidth: 800, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    private func topicTitleDe(_ topic: HelpTopic) -> String {
        switch topic {
        case .overview: return "1. Einführung & Übersicht"
        case .designer: return "2. QSL-Karten Designer"
        case .udpNetwork: return "3. UDP & Logger-Anbindung"
        case .emailDelivery: return "4. E-Mail Versand"
        case .automationModes: return "5. Automatisierung & Modi"
        case .templates: return "6. Platzhalter & Vorlagen"
        case .storageSync: return "7. iCloud-Speicher & Sync"
        case .disclaimer: return "8. Haftungsausschluss & Datenschutz"
        case .copyright: return "9. Urheberrecht & Credits"
        case .changelog: return "10. Versionsgeschichte & Changelog"
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
        case .automationModes:
            automationModesSection
        case .templates:
            templatesSection
        case .storageSync:
            storageSyncSection
        case .disclaimer:
            disclaimerSection
        case .copyright:
            copyrightSection
        case .changelog:
            changelogSection
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
                    featureRow(icon: "square.stack.3d.up.fill", text: isGerman ?
                        "Massenverarbeitung: Wähle mehrere QSOs mit Shift + Pfeiltasten aus, um sie alle auf einmal zu versenden oder zu löschen." :
                        "Batch Processing: Select multiple QSOs using Shift + Arrow Keys to dispatch or delete them all at once.")
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
                    featureRow(icon: "arrow.uturn.backward.circle.fill", text: isGerman ?
                        "Rückgängig-Funktion (Undo ⌘Z): Alle Änderungen an Elementen, Positionen, Farben und Schriftarten lassen sich jederzeit mit ⌘Z oder der Undo-Schaltfläche schrittweise zurücknehmen." :
                        "Undo Support (⌘Z): Revert design changes, movements, font edits, and color adjustments step-by-step using ⌘Z or the toolbar Undo button.")
                    featureRow(icon: "cursorarrow.motionlines", text: isGerman ?
                        "Direktes Maus-Dragging: Klicke und ziehe beliebige Elemente direkt auf der Leinwand an ihre Wunschposition." :
                        "Direct Mouse Dragging: Click and drag any element directly on the canvas to reposition it smoothly.")
                    featureRow(icon: "textformat", text: isGerman ?
                        "Standard macOS Schriftarten-Auswahl (NSFontPanel): Zugriff auf alle installierten Schriftarten, Schriftschnitte und Größen." :
                        "Native macOS Font Panel (NSFontPanel): Access all system fonts, weights, styles, and sizes via 'Choose Font…'.")
                    featureRow(icon: "paintpalette", text: isGerman ?
                        "macOS Farbwähler mit Transparenz/Deckkraft (Alpha-Kanal): Alle Texte, Hintergründe, Tabellen und Rahmen unterstützen stufenlose Deckkraft." :
                        "macOS Color Pickers with Opacity (Alpha Channel): Full support for opacity and transparency across all fonts, backgrounds, tables, and borders.")
                    featureRow(icon: "shadow", text: isGerman ?
                        "Schatten-Schalter (Drop Shadow on/off): Schattenwurf für alle Textelemente separat aktivierbar mit Weichzeichnungs- und Abstandsreglern." :
                        "Shadow Toggles (on/off): Dedicated drop shadow switches with customizable blur radius, offsets, and opacity.")
                    featureRow(icon: "tablecells", text: isGerman ?
                        "QSO-Bestätigungstabelle: Konfigurierbare Spalten (QSO With, Date, UTC Time, Frequency, Report, Mode, Remarks) mit wählbarem Datumsformat." :
                        "QSO Confirmation Table: Configurable columns (QSO With, Date, UTC Time, Frequency, Report, Mode, Remarks) with custom date formats.")
                    featureRow(icon: "square.on.square", text: isGerman ?
                        "Ebenen-Verwaltung & Duplizieren: Rechtsklick auf Ebenen in der linken Seitenleiste zum Duplizieren oder Löschen von Elementen." :
                        "Layer Management & Duplication: Right-click layers in the sidebar to duplicate or delete elements.")
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
                            "1. Öffne in WSJT-X: Einstellungen > Reporting > UDP Server\n2. Aktiviere 'Accept UDP requests'\n3. Setze 'UDP Server' auf 224.0.0.1 und 'UDP Server Port' auf 2237" :
                            "1. Open WSJT-X Settings > Reporting > UDP Server\n2. Enable 'Accept UDP requests'\n3. Set 'UDP Server' to 224.0.0.1 and 'UDP Server Port' to 2237")
                            .font(.caption.monospaced())
                    }
                }

                GroupBox(label: Text("RUMlogNG Setup")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(isGerman ?
                            "RUMlogNG nutzt den 'Contact info N1MM' Broadcast. So konfigurierst du zwei separate Broadcasts (z. B. für QSO Upload Utility auf Port 12063 und AutoQSL auf Port 12064 parallel):" :
                            "RUMlogNG uses the 'Contact info N1MM' broadcast. Here is how to configure two separate broadcasts (e.g., for QSO Upload Utility on port 12063 and AutoQSL on port 12064 simultaneously):")
                            .font(.subheadline)
                            
                        Text(isGerman ?
                            "1. Öffne RUMlogNG > Einstellungen > UDP\n2. 'App Info' und 'DX Spot' Haken setzen (falls benötigt)\n3. Ersten 'Contact info N1MM' Broadcast auf Port 12063 setzen (z.B. für QSO Upload Utility)\n4. Zweiten 'Contact info N1MM' Broadcast auf Port 12064 (oder 2333) setzen (für AutoQSL)" :
                            "1. Open RUMlogNG > Preferences > UDP\n2. Enable 'App Info' and 'DX Spot' (if needed)\n3. Set first 'Contact info N1MM' broadcast to Port 12063 (e.g. for QSO Upload Utility)\n4. Set second 'Contact info N1MM' broadcast to Port 12064 or 2333 (for AutoQSL)")
                            .font(.caption.monospaced())
                            
                        #if SWIFT_PACKAGE
                        if let path = Bundle.module.path(forResource: "rumlog_settings", ofType: "png"),
                           let nsImage = NSImage(contentsOfFile: path) {
                            Image(nsImage: nsImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 600)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        } else {
                            Image("rumlog_settings")
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 600)
                                .cornerRadius(8)
                                .shadow(radius: 3)
                        }
                        #else
                        Image("rumlog_settings")
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: 600)
                            .cornerRadius(8)
                            .shadow(radius: 3)
                        #endif
                    }
                }
                
                GroupBox(label: Label(isGerman ? "Direkter RUMlogNG-Import (AppleScript)" : "Direct RUMlogNG Import (AppleScript)", systemImage: "arrow.down.doc.fill")) {
                    Text(isGerman ?
                        "Über die Schaltfläche 'Grab RUMlog' in der Queue-Ansicht kann jederzeit das zuletzt geloggte QSO direkt über AppleScript aus RUMlogNG ausgelesen und als QSL-Karte generiert werden – ganz ohne UDP-Broadcast." :
                        "The 'Grab RUMlog' button in the Queue view allows you to instantly pull the most recent QSO from RUMlogNG via native AppleScript and generate a QSL card without requiring UDP broadcasts.")
                        .font(.caption)
                }
                
                GroupBox(label: Label(isGerman ? "Wichtiger Hinweis zu Duplikaten" : "Important Note on Duplicates", systemImage: "exclamationmark.triangle.fill").foregroundColor(.orange)) {
                    Text(isGerman ?
                        "Wenn du in AutoQSL UDP für WSJTX und RumLog eingeschaltet hast, erhältst du abhängig von der RumLog-Konfiguration doppelte QSLs. Es wird empfohlen, entweder das eine oder das andere zu verwenden." :
                        "If you have switched on UDP for WSJTX and RumLog in AutoQSL you will get duplicate QSLs depending on RumLog's configuration. It is recommended to use either or.")
                        .font(.caption)
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

    // MARK: - 5. Automation Modes
    private var automationModesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "Automatisierung & Versand-Modi" : "Automation & Dispatch Modes")
                .font(.title2.bold())
            
            Text(isGerman ?
                "AutoQSL bietet drei Automatisierungs-Modi, passend zu deinem Betriebsablauf. Konfigurierbar in den Einstellungen unter 'Automation & Modes':" :
                "AutoQSL offers three automation modes to suit your operating style. These can be configured in the Settings under 'Automation & Modes':")
                .font(.body)

            GroupBox(label: Label(isGerman ? "Preview & Confirm (Empfohlen)" : "Preview & Confirm (Recommended)", systemImage: "eye.fill")) {
                Text(isGerman ?
                    "Sobald ein QSO empfangen wird, erscheint eine hochauflösende Vorschau der QSL-Karte. Du kannst alle Daten überprüfen, die E-Mail anpassen und den Versand bestätigen." :
                    "Whenever a QSO is received, a high-resolution preview of the QSL card is presented. You can verify all details, edit the email message, and click to dispatch.")
                    .font(.caption)
            }

            GroupBox(label: Label("Fully Automatic", systemImage: "bolt.fill")) {
                Text(isGerman ?
                    "AutoQSL rendert und versendet die QSL-Karte völlig lautlos im Hintergrund, sobald ein QSO geloggt wird. Ideal für FT8 oder Contests." :
                    "AutoQSL will silently render and email the QSL card in the background immediately upon logging a QSO. This mode is ideal for hands-free FT8 or contesting.")
                    .font(.caption)
            }

            GroupBox(label: Label("Manual Queue", systemImage: "tray.full.fill")) {
                Text(isGerman ?
                    "Eingehende QSOs werden ohne Nachfrage in deine Warteschlange gelegt. Du kannst sie später überprüfen und mit der Massenverarbeitung (Shift + Pfeiltasten) mehrere Karten auf einmal senden." :
                    "Incoming QSOs are added to your queue without prompting you. You can review the queue later and use Batch Processing (Shift + Arrow Keys) to send multiple cards at once.")
                    .font(.caption)
            }
        }
    }

    // MARK: - 6. Templates
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

    // MARK: - 7. iCloud Storage & Multi-Mac Sync
    private var storageSyncSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: "icloud.circle.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                Text(isGerman ? "iCloud-Speicher & Multi-Mac Synchronisation" : "iCloud Storage & Multi-Mac Synchronization")
                    .font(.title2.bold())
            }
            
            Text(isGerman ?
                "AutoQSL bietet Ihnen die Wahl, alle Daten lokal auf Ihrem Mac zu halten oder über iCloud Drive automatisch mit weiteren Macs (z. B. Shack-Desktop und Mobil-MacBook) abzugleichen." :
                "AutoQSL provides the flexibility to store all data locally on this Mac or synchronize seamlessly across multiple Macs (e.g. Shack desktop and laptop) via iCloud Drive.")
                .font(.body)
            
            GroupBox(label: Text(isGerman ? "Speicherorte & Datenbank im Überblick" : "Storage Locations & Database Overview")) {
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(
                        icon: "cylinder.split.1x2.fill",
                        text: isGerman ?
                            "High-Speed SQLite-Datenbank: Alle QSOs werden in 'autoqsl.sqlite' gespeichert und indiziert – für blitzschnelle Suchen und minimale Ladezeiten selbst bei 100.000+ Kontakten." :
                            "High-Speed SQLite Database: All QSOs are stored and indexed in 'autoqsl.sqlite' for instant searches and low memory usage even with 100,000+ contacts."
                    )
                    
                    featureRow(
                        icon: "laptopcomputer",
                        text: isGerman ?
                            "Lokaler Speicher: ~/Library/Application Support/AutoQSL – Ideal für Einzelplatz-Installationen ohne Cloud-Abhängigkeit." :
                            "Local Storage: ~/Library/Application Support/AutoQSL – Ideal for single-Mac setups without cloud dependence."
                    )
                    
                    featureRow(
                        icon: "icloud.fill",
                        text: isGerman ?
                            "iCloud Drive: iCloud Drive/AutoQSL – Synchronisiert Einstellungen, gestaltete Kartenvorlagen, QSO-Warteschlangen und gerenderte QSL-Karten automatisch." :
                            "iCloud Drive: iCloud Drive/AutoQSL – Automatically synchronizes settings, card templates, QSO queues, and rendered card images."
                    )
                }
                .padding(4)
            }
            
            GroupBox(label: Text(isGerman ? "1-Klick-Datenmigration & Finder" : "1-Click Migration & Finder Access")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isGerman ?
                        "In den Einstellungen unter 'Storage & iCloud' können Sie mit einem Klick bestehende lokale Einstellungen und Vorlagen in die iCloud kopieren ('Copy Local Data to iCloud') oder aus der iCloud auf Ihren lokalen Mac wiederherstellen." :
                        "In Settings under 'Storage & iCloud', you can migrate your existing data to iCloud with a single click ('Copy Local Data to iCloud') or restore from iCloud to local disk.")
                        .font(.caption)
                    
                    Text(isGerman ?
                        "Über 'Reveal in Finder' öffnet sich der aktive Datenordner direkt in macOS Finder für Backups oder manuelle Bilddateien." :
                        "Use 'Reveal in Finder' to instantly open your active storage folder in macOS Finder for manual backups or asset management.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(4)
            }
        }
    }

    // MARK: - 8. Disclaimer & Privacy
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
                    "AutoQSL speichert alle Einstellungen, Vorlagen, Adressdaten und Logbücher ausschließlich lokal auf Ihrem Mac bzw. in Ihrem persönlichen, verschlüsselten iCloud Drive. Es werden keine Telemetriedaten, Zugangsdaten oder persönliche Informationen an Server Dritter übermittelt, mit Ausnahme der von Ihnen konfigurierten QRZ.com-Abfragen und E-Mail-Empfänger." :
                    "AutoQSL stores all credentials, settings, templates, and logs exclusively locally on your Mac or inside your private encrypted iCloud Drive. No telemetry or tracking data is collected or transmitted to third-party servers, except your direct queries to QRZ.com and outgoing email dispatches.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - 9. Copyright & Credits
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
                
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
    }


    // MARK: - 10. Changelog & Versions
    private var changelogSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.title)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isGerman ? "Versionsgeschichte & Changelog" : "Changelog & Version History")
                        .font(.title2.bold())
                    Text("AutoQSL Updates & Release Notes")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            GroupBox(label: Text("Version 1.1.0").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    featureRow(
                        icon: "waveform.path",
                        text: isGerman ?
                            "Dynamische Band- & Frequenzeingabe: Automatische Synchronisation zwischen Band-Dropdown und Frequenzfeld in 'Manuell loggen' und 'QSO bearbeiten'." :
                            "Dynamic Band & Frequency Selection: 2-way sync between Band dropdown and Frequency field in Manual Log and Edit QSO modals."
                    )
                    featureRow(
                        icon: "character.cursor.ibeam",
                        text: isGerman ?
                            "Benutzerdefinierte Modi: Freie Texteingabe für beliebige Betriebsarten (z.B. VARAC, JT65, DMR, C4FM, WSPR) bei Auswahl von 'Other...'." :
                            "Custom Modes: Text entry for any custom digital or voice mode (e.g. VARAC, JT65, DMR, C4FM, WSPR) when selecting 'Other...'."
                    )
                    featureRow(
                        icon: "antenna.radiowaves.left.and.right",
                        text: isGerman ?
                            "Erweiterte Band-Erkennung: Zentralisiertes RadioUtils-Modul mit automatischer Zuordnung und Einheitenumrechnung." :
                            "Enhanced Band Detection: Centralized RadioUtils engine with automatic band matching and unit parsing."
                    )
                }
                .padding(8)
            }

            GroupBox(label: Text("Version 1.0.0").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    featureRow(
                        icon: "sparkles",
                        text: isGerman ?
                            "Erstveröffentlichung: Echtzeit UDP-Erfassung für WSJT-X, JTDX und RUMlogNG." :
                            "Initial Release: Real-time UDP capture for WSJT-X, JTDX, and RUMlogNG."
                    )
                    featureRow(
                        icon: "paintpalette.fill",
                        text: isGerman ?
                            "Visueller WYSIWYG QSL-Kartendesigner mit Ebenenverwaltung, Transparenzen und Undo (⌘Z)." :
                            "Visual WYSIWYG QSL Card Designer with layer management, alpha opacity, and undo support (⌘Z)."
                    )
                    featureRow(
                        icon: "paperplane.fill",
                        text: isGerman ?
                            "Automatischer Versand über Apple Mail, Standard-Mailclient oder direktes SMTP mit QRZ.com-Abfrage." :
                            "Multi-channel dispatch via Apple Mail, default email client, or direct SMTP with QRZ.com lookup."
                    )
                    featureRow(
                        icon: "internaldrive.fill",
                        text: isGerman ?
                            "Native SQLite-Datenbank und duale lokale / iCloud Drive Synchronisation." :
                            "Native SQLite database engine and dual Local / iCloud Drive sync."
                    )
                }
                .padding(8)
            }
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
