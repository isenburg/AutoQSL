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
        case callbooks = "4. Callbook Lookups (QRZ & HamQTH)"
        case emailDelivery = "5. Email Dispatching"
        case automationModes = "6. Automation & Modes"
        case templates = "7. Placeholders & Templates"
        case storageSync = "8. iCloud Storage & Sync"
        case disclaimer = "9. Disclaimer & Privacy"
        case copyright = "10. Copyright & Credits"
        case changelog = "11. Changelog & Versions"

        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .overview: return "info.circle.fill"
            case .designer: return "paintpalette.fill"
            case .udpNetwork: return "antenna.radiowaves.left.and.right"
            case .callbooks: return "person.text.rectangle.fill"
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
        case .callbooks: return "4. Callbook-Abfragen (QRZ & HamQTH)"
        case .emailDelivery: return "5. E-Mail Versand"
        case .automationModes: return "6. Automatisierung & Modi"
        case .templates: return "7. Platzhalter & Vorlagen"
        case .storageSync: return "8. iCloud-Speicher & Sync"
        case .disclaimer: return "9. Haftungsausschluss & Datenschutz"
        case .copyright: return "10. Urheberrecht & Credits"
        case .changelog: return "11. Versionsgeschichte & Changelog"
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
        case .callbooks:
            callbooksSection
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

    // MARK: - 1. Overview & Quick Start
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.system(size: 32))
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(isGerman ? "AutoQSL – Schritt-für-Schritt Anleitung" : "AutoQSL – Operating Guide & Manual")
                        .font(.title2.bold())
                    Text("Version \(APP_VERSION) (Build \(APP_BUILD_NUMBER))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            Text(isGerman ?
                "AutoQSL verbindet deine Logprogramme (WSJT-X, JTDX, RUMlogNG) mit einer automatischen eQSL-Generierung, QRZ.com-E-Mail-Abfrage und Versand via Apple Mail oder SMTP." :
                "AutoQSL connects your logging software (WSJT-X, JTDX, RUMlogNG) with automated eQSL generation, QRZ.com email lookup, and email dispatch.")
                .font(.body)

            GroupBox(label: Label(isGerman ? "Ersteinrichtung in 4 einfachen Schritten" : "Quick Start Setup (4 Steps)", systemImage: "flag.checkered")) {
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(icon: "1.circle.fill", text: isGerman ?
                        "1. Stationsprofil ausfüllen: Öffne Settings (⌘,) und trage dein Rufzeichen, Namen, QTH-Adresse und Locator ein." :
                        "1. Fill in Station Profile: Open Settings (⌘,) and enter your callsign, name, postal address, and grid square.")
                    featureRow(icon: "2.circle.fill", text: isGerman ?
                        "2. Callbook-Zugangsdaten hinterlegen (QRZ.com & HamQTH): Trage QRZ- und/oder kostenlose HamQTH-Zugangsdaten ein für automatische E-Mail- und Namensabfragen." :
                        "2. Set Callbook Credentials (QRZ.com & HamQTH): Enter QRZ and/or free HamQTH XML logins to automatically retrieve recipient emails and QTH.")
                    featureRow(icon: "3.circle.fill", text: isGerman ?
                        "3. Versandart wählen: Wähle 'Apple Mail' (empfohlen, ohne Passwörter) oder trage deine SMTP-Serverdaten ein." :
                        "3. Choose Email Method: Select 'Apple Mail' (recommended, no passwords needed) or configure direct SMTP.")
                    featureRow(icon: "4.circle.fill", text: isGerman ?
                        "4. Betriebsmodus wählen: 'Preview & Confirm' zeigt vor jedem Versand eine Kartenvorschau (Taste ⌘+Return zum Senden)." :
                        "4. Select Mode: 'Preview & Confirm' shows a high-res card preview before sending (press ⌘+Return to send).")
                }
                .padding(.vertical, 4)
            }

            GroupBox(label: Label(isGerman ? "Täglicher Betrieb: Wie funktioniert der Ablauf?" : "Daily Operating Workflow", systemImage: "arrow.triangle.2.circlepath")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isGerman ?
                        "• Automatischer Empfang: Sobald ein QSO in WSJT-X oder RUMlogNG geloggt wird, empfängt AutoQSL das Datenpaket via UDP, fragt QRZ.com ab und rendert die Karte.\n• Manuelles Loggen: Über die Schaltfläche 'Log QSO Manually' kannst du jederzeit QSOs nachträglich eingeben (mit automatischer Band/Frequenzerkennung und beliebigen Betriebsarten).\n• Letztes QSO holen: Klicke auf 'Grab RUMlog', um das letzte QSO direkt per AppleScript aus RUMlogNG zu importieren.\n• Massenversand: Wähle mehrere QSOs mit Shift + Pfeiltasten aus und klicke auf 'Send Selected'." :
                        "• Automated Capture: When a QSO is logged in WSJT-X or RUMlogNG, AutoQSL captures it over UDP, fetches QRZ info, and renders the card.\n• Manual Logging: Click 'Log QSO Manually' to enter ad-hoc contacts (with dynamic Band/Freq synchronization and custom mode support).\n• One-Click Grab: Click 'Grab RUMlog' to pull the latest QSO directly from RUMlogNG via AppleScript.\n• Batch Processing: Select multiple QSOs with Shift + Arrow Keys and click 'Send Selected'.")
                        .font(.callout)
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

            GroupBox(label: Label(isGerman ? "Direkte Canvas-Bearbeitung vs. Seitenleisten-Inspektor" : "Direct Canvas Editing vs. Sidebar Inspector", systemImage: "pencil.and.outline")) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(isGerman ?
                        "Welche Elemente können direkt auf der Karte bearbeitet werden?" :
                        "Which elements can be edited directly on the canvas?")
                        .font(.subheadline.bold())

                    VStack(alignment: .leading, spacing: 6) {
                        featureRow(icon: "checkmark.circle.fill", text: isGerman ?
                            "✅ Direkt auf der Karte editierbar: Rufzeichen (Callsign), Adressblock (Address) und freier Text (Custom Text). Klicke einfach auf das Element auf der Leinwand, um den Text direkt einzutippen." :
                            "✅ Directly editable on canvas: Callsign Block, Address Block, and Custom Text. Simply click the element on the canvas to type and edit its text inline.")
                        featureRow(icon: "gearshape.fill", text: isGerman ?
                            "⚙️ Über die rechte Seitenleiste konfiguriert: QSO-Bestätigungstabelle (Spalten, Header, Datumsformate, Farben), Standort-Zeile (Location Footer), Abzeichen/Sticker (Badges) sowie Hintergrundbilder und Kartenmaße." :
                            "⚙️ Configured via right sidebar inspector: QSO Confirmation Table (columns, headers, date formats, colors), Location Footer (dynamic station data), Badges & Stickers, and Background image / Card aspect ratio.")
                    }
                }
                .padding(.vertical, 4)
            }

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

    // MARK: - 4. Callbooks (QRZ & HamQTH)
    private var callbooksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "Callbook-Abfragen (QRZ.com & HamQTH.com)" : "Callbook Lookups (QRZ.com & HamQTH.com)")
                .font(.title2.bold())
            
            Text(isGerman ?
                "AutoQSL fragt bei jedem empfangenen QSO automatisch die Kontaktdaten der Gegenstation über standardisierte XML-Schnittstellen ab, um die E-Mail-Adresse für den Kartenversand, den vollen Namen, den Maidenhead-Locator und das Land zu ermitteln." :
                "AutoQSL automatically queries recipient contact details via standardized XML APIs upon logging, retrieving email addresses for card delivery, names, Maidenhead grid squares, and DXCC entities.")
                .font(.body)

            GroupBox(label: Label(isGerman ? "Unterstützte Callbook-Dienste" : "Supported Callbook Services", systemImage: "person.2.badge.gearshape.fill")) {
                VStack(alignment: .leading, spacing: 10) {
                    featureRow(
                        icon: "globe",
                        text: isGerman ?
                            "QRZ.com XML API: Weltweit größtes Callbook. Erfordert ein QRZ-Konto mit aktivem XML-Logbook-Abonnement. Zuverlässig und umfangreich." :
                            "QRZ.com XML API: Global standard callbook database. Requires an active QRZ XML subscription. Very comprehensive and up-to-date."
                    )
                    featureRow(
                        icon: "antenna.radiowaves.left.and.right",
                        text: isGerman ?
                            "HamQTH.com XML API (100% Kostenlos): Community-Callbook von Petr (OK2CQR). Erfordert lediglich eine kostenlose Registrierung auf hamqth.com – kein bezahltes Abo nötig!" :
                            "HamQTH.com XML API (100% Free): Community-driven callbook by OK2CQR. Requires only a free registration at hamqth.com – no paid subscription required!"
                    )
                }
                .padding(4)
            }

            GroupBox(label: Label(isGerman ? "Abfrage-Strategien & Prioritäten" : "Lookup Priority & Fallback Strategies", systemImage: "arrow.triangle.branch")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(isGerman ?
                        "In den Einstellungen unter 'Callbook Lookups' kannst du festlegen, wie AutoQSL vorgehen soll:" :
                        "In Settings under 'Callbook Lookups', select your preferred lookup strategy:")
                        .font(.subheadline.bold())

                    VStack(alignment: .leading, spacing: 6) {
                        featureRow(icon: "1.circle.fill", text: isGerman ?
                            "QRZ.com (Primary) + HamQTH (Fallback) [Empfohlen]: Fragt zuerst QRZ.com ab. Fehlt die E-Mail oder existiert kein Profil, wird automatisch HamQTH.com angefragt." :
                            "QRZ.com (Primary) + HamQTH (Fallback) [Recommended]: Queries QRZ first. If no email is found, seamlessly falls back to HamQTH.com.")
                        featureRow(icon: "2.circle.fill", text: isGerman ?
                            "HamQTH (Primary) + QRZ.com (Fallback): Nutzt primär das kostenlose HamQTH und fragt bei Lücken QRZ.com an." :
                            "HamQTH (Primary) + QRZ.com (Fallback): Uses free HamQTH first, querying QRZ only when needed.")
                        featureRow(icon: "checkmark.circle", text: isGerman ?
                            "QRZ.com Only oder HamQTH Only: Beschränkt alle Abfragen ausschließlich auf den gewählten Dienst." :
                            "QRZ.com Only or HamQTH Only: Restricts lookups exclusively to a single chosen provider.")
                    }
                }
                .padding(4)
            }

            GroupBox(label: Label(isGerman ? "In-Memory Caching & Geschwindigkeit" : "In-Memory Caching & Performance", systemImage: "bolt.badge.clock.fill")) {
                Text(isGerman ?
                    "Erfolgreich abgerufene Profile werden während der Programmlaufzeit im Arbeitsspeicher zwischengespeichert. Wiederholte QSOs mit derselben Station erfordern keine erneute Netzwerkanfrage, schonen API-Limits und ermöglichen sofortiges Rendern." :
                    "Successfully fetched profiles are cached in memory during runtime. Repeated contacts with the same station require no network requests, preserving API limits and enabling instant rendering.")
                    .font(.caption)
            }
        }
    }

    // MARK: - 5. Email Delivery
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

    // MARK: - 6. Templates & Dynamic Placeholders
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(isGerman ? "Dynamische Platzhalter & Vorlagen-Anleitung" : "Dynamic Placeholders & Template Guide")
                .font(.title2.bold())
            
            Text(isGerman ?
                "AutoQSL unterstützt dynamische Platzhalter in geschweiften Klammern {TAG}. Diese können flexibel in E-Mail-Betreffzeilen, E-Mail-Nachrichtentexten, Freitext-Kartenfeldern ('Custom Text') und der Standort-Zeile ('Location Footer') verwendet werden." :
                "AutoQSL supports dynamic {TAG} placeholders. You can use them in Email Subject lines, Email Body messages, Custom Text card elements, and the Location Footer line.")
                .font(.body)

            GroupBox(label: Label(isGerman ? "Wo können Platzhalter verwendet werden?" : "Where Can You Use Placeholders?", systemImage: "sparkles")) {
                VStack(alignment: .leading, spacing: 6) {
                    featureRow(icon: "envelope.fill", text: isGerman ?
                        "E-Mail Betreff & Nachrichtentext: In den Einstellungen unter 'Email Template' für persönliche Anschreiben." :
                        "Email Subject & Body: In Settings under 'Email Template' for customized email delivery.")
                    featureRow(icon: "paintpalette.fill", text: isGerman ?
                        "QSL-Kartendesigner (Custom Text): Füge Freitextfelder auf der Karte ein (z. B. 'Confirming 2-way {MODE} QSO with {DX_CALL}')." :
                        "Card Designer (Custom Text): Add text elements directly onto your card (e.g. 'Confirming 2-way {MODE} QSO with {DX_CALL}').")
                    featureRow(icon: "mappin.and.ellipse", text: isGerman ?
                        "Standort-Zeile (Location Footer): Automatische Anzeige von Locator und Zonen ('ITU {MY_ITU} • CQ {MY_CQ} • Grid {MY_GRID}')." :
                        "Location Footer: Automatic display of zones and locators ('ITU {MY_ITU} • CQ {MY_CQ} • Grid {MY_GRID}').")
                }
                .padding(.vertical, 4)
            }

            GroupBox(label: Text(isGerman ? "1. Empfänger- & DX-Informationen (aus Log & QRZ)" : "1. DX Contact & Recipient Data")) {
                VStack(alignment: .leading, spacing: 4) {
                    placeholderRow(tag: "{DX_CALL}", desc: isGerman ? "Rufzeichen der Gegenstation (z. B. DJ6GI)" : "Recipient Callsign (e.g. DJ6GI)")
                    placeholderRow(tag: "{DX_NAME}", desc: isGerman ? "Name der Gegenstation aus QRZ (oder Rufzeichen)" : "Recipient Name (from QRZ lookup)")
                    placeholderRow(tag: "{DX_GRID}", desc: isGerman ? "Maidenhead-Locator der Gegenstation" : "Recipient Maidenhead Grid (e.g. JN58td)")
                    placeholderRow(tag: "{DX_EMAIL}", desc: isGerman ? "E-Mail-Adresse des Empfängers" : "Recipient Email Address")
                    placeholderRow(tag: "{DX_COUNTRY}", desc: isGerman ? "Land / DXCC-Gebiet" : "Recipient Country / DXCC")
                }
                .padding(4)
            }

            GroupBox(label: Text(isGerman ? "2. QSO-Parameter" : "2. QSO Parameters")) {
                VStack(alignment: .leading, spacing: 4) {
                    placeholderRow(tag: "{BAND}", desc: isGerman ? "Amateurfunkband (z. B. 20m)" : "Operating Band (e.g. 20m)")
                    placeholderRow(tag: "{MODE}", desc: isGerman ? "Betriebsart (z. B. FT8, CW, SSB, VARAC)" : "Operating Mode (e.g. FT8, CW, SSB)")
                    placeholderRow(tag: "{FREQ}", desc: isGerman ? "Genaue Frequenz in MHz (z. B. 14.074 MHz)" : "Exact Frequency in MHz (e.g. 14.074 MHz)")
                    placeholderRow(tag: "{RST_SENT}", desc: isGerman ? "Gesendeter Signal-Report (z. B. -12, 599)" : "Sent RST Signal Report (e.g. -12, 599)")
                    placeholderRow(tag: "{RST_RCVD}", desc: isGerman ? "Empfangener Signal-Report" : "Received RST Signal Report")
                    placeholderRow(tag: "{DATE}", desc: isGerman ? "QSO-Datum nach gewähltem Format" : "QSO Date formatted per settings")
                    placeholderRow(tag: "{TIME}", desc: isGerman ? "QSO-Uhrzeit in UTC (z. B. 14:05)" : "QSO Time in UTC (e.g. 14:05)")
                    placeholderRow(tag: "{COMMENT}", desc: isGerman ? "QSO-Bemerkung / Grußtext" : "QSO Comment / Remarks")
                }
                .padding(4)
            }

            GroupBox(label: Text(isGerman ? "3. Eigene Stationsdaten (aus den Einstellungen)" : "3. My Station Data (from Settings)")) {
                VStack(alignment: .leading, spacing: 4) {
                    placeholderRow(tag: "{MY_CALL}", desc: isGerman ? "Eigenes Rufzeichen" : "Your Station Callsign")
                    placeholderRow(tag: "{MY_NAME}", desc: isGerman ? "Eigener Name" : "Your Operator Name")
                    placeholderRow(tag: "{MY_GRID}", desc: isGerman ? "Eigener Maidenhead-Locator" : "Your Grid Square")
                    placeholderRow(tag: "{MY_CITY}", desc: isGerman ? "Stadt / QTH" : "Your City / QTH")
                    placeholderRow(tag: "{MY_COUNTRY}", desc: isGerman ? "Land" : "Your Country")
                    placeholderRow(tag: "{MY_CQ}", desc: isGerman ? "CQ-Zone (z. B. 14)" : "Your CQ Zone (e.g. 14)")
                    placeholderRow(tag: "{MY_ITU}", desc: isGerman ? "ITU-Zone (z. B. 28)" : "Your ITU Zone (e.g. 28)")
                }
                .padding(4)
            }

            GroupBox(label: Label(isGerman ? "Praktisches E-Mail-Beispiel" : "Example Outgoing Email Template", systemImage: "doc.text.fill")) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(isGerman ?
                        "Hallo {DX_NAME},\n\nvielen Dank für das nette {MODE}-QSO auf {BAND} ({FREQ}) am {DATE} um {TIME} UTC!\nDein Signalreport war {RST_SENT} an meinen Standort in {MY_GRID}.\n\nIm Anhang findest du meine elektronische QSL-Karte.\n\n73 de {MY_NAME} ({MY_CALL})" :
                        "Hello {DX_NAME},\n\nThank you for the {MODE} QSO on {BAND} ({FREQ}) on {DATE} at {TIME} UTC!\nYour signal report was {RST_SENT} in grid {MY_GRID}.\n\nPlease find my electronic QSL card attached.\n\nBest 73 & Good DX,\n{MY_NAME} ({MY_CALL})")
                        .font(.caption.monospaced())
                        .padding(8)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                }
                .padding(4)
            }
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
                        icon: "antenna.radiowaves.left.and.right",
                        text: isGerman ?
                            "HamQTH.com Callbook-Integration: Vollständige Unterstützung für HamQTH XML-Abfragen mit konfigurierbarer Priorität (QRZ Primary + HamQTH Fallback, HamQTH Primary, QRZ Only, HamQTH Only)." :
                            "HamQTH.com Callbook Integration: Full support for free HamQTH XML lookups with configurable fallback priority (QRZ Primary + HamQTH Fallback, HamQTH Primary, QRZ Only, HamQTH Only)."
                    )
                    featureRow(
                        icon: "cursorarrow.click.2",
                        text: isGerman ?
                            "Doppelklick-Callbook: Doppelklick auf einen Warteschlangen-Eintrag öffnet das Rufzeichen direkt im konfigurierten Callbook (QRZ.com oder HamQTH) im Browser." :
                            "Double-Click Callbook Lookup: Double-click any queue entry to open the callsign in your configured callbook (QRZ.com or HamQTH) in the default browser."
                    )
                    featureRow(
                        icon: "checkmark.circle",
                        text: isGerman ?
                            "Native Listenauswahl: Einfachklick selektiert mit Standard-macOS-Hervorhebung; ⌘A wählt alle; ⌘+Klick / Umschalt+Klick für Mehrfachauswahl." :
                            "Native Queue Selection: Single-click selects with standard macOS highlight; ⌘A selects all; ⌘+click / Shift+click for multi-select."
                    )
                    featureRow(
                        icon: "wave.3.right",
                        text: isGerman ?
                            "Verbessertes RUMlogNG UDP-Parsing: Vollständige Unterstützung für N1MM XML-Kontaktformat (CDATA, 10-Hz-Frequenzeinheiten, UTF-8/Latin-1-Encoding)." :
                            "Improved RUMlogNG UDP Parsing: Full N1MM XML contact format support (CDATA, 10 Hz frequency units, UTF-8/Latin-1 multi-encoding)."
                    )
                    featureRow(
                        icon: "lock.shield",
                        text: isGerman ?
                            "Port-Isolation: AutoQSL bindet nur explizit konfigurierte UDP-Ports – keine automatischen Fallback-Ports, die andere Apps stören könnten." :
                            "Port Isolation: AutoQSL only binds explicitly configured UDP ports — no background fallback ports that could conflict with other apps."
                    )
                    featureRow(
                        icon: "command",
                        text: isGerman ?
                            "Natives Einstellungen-Tastaturkürzel (⌘,): Öffnet die Einstellungen direkt aus jedem Fenster und über das macOS-Anwendungsmenü." :
                            "Native Settings Shortcut (⌘,): Open Settings instantly from any window and via standard macOS App menu."
                    )
                    featureRow(
                        icon: "pencil.line",
                        text: isGerman ?
                            "Direkte Canvas-Textbearbeitung: Rufzeichen, Adressblock und benutzerdefinierter Text können direkt auf der Karte im Designer bearbeitet werden." :
                            "Direct On-Canvas Editing: Edit Callsign, Address Block, and Custom Text directly on the interactive card canvas."
                    )
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
                        icon: "cylinder.split.1x2.fill",
                        text: isGerman ?
                            "SQLite Queue-Synchronisation & 10/10 Unit Tests: Dauerhafte Lösch-Synchronisation, Schutz vor doppelten Legacy-Reimporten und vollständige Test-Suite." :
                            "SQLite Queue Synchronization & 10/10 Unit Tests: Permanent deletion sync, duplicate import protection, and full parser test suite (ADIF, RUMlog, WSJT-X, QRZ, HamQTH)."
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
