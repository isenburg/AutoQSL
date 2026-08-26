import Foundation

public enum AppLanguage: String, Codable, CaseIterable {
    case english = "en"
    case german = "de"
    
    public var displayName: String {
        switch self {
        case .english: return "English 🇬🇧"
        case .german: return "Deutsch 🇩🇪"
        }
    }
}

public struct L10n {
    @inline(__always)
    public static func tr(_ lang: AppLanguage, _ en: String, _ de: String) -> String {
        return lang == .german ? de : en
    }
    
    // MARK: - Navigation & Sidebar
    public struct Nav {
        public static func qsoQueue(_ l: AppLanguage) -> String { L10n.tr(l, "QSO Queue", "QSO-Warteschlange") }
        public static func cardDesigner(_ l: AppLanguage) -> String { L10n.tr(l, "Card Designer", "Karten-Designer") }
        public static func settings(_ l: AppLanguage) -> String { L10n.tr(l, "Settings", "Einstellungen") }
        public static func helpDocs(_ l: AppLanguage) -> String { L10n.tr(l, "Help & Docs", "Hilfe & Doku") }
        public static func udpActive(_ l: AppLanguage, port: Int) -> String { L10n.tr(l, "UDP Active (\(port))", "UDP Aktiv (\(port))") }
        public static func ready(_ l: AppLanguage) -> String { L10n.tr(l, "Ready", "Bereit") }
        public static func station(_ l: AppLanguage, call: String) -> String { L10n.tr(l, "Station: \(call)", "Station: \(call)") }
    }
    
    // MARK: - QSO Queue & Filters
    public struct Queue {
        public static func filterAll(_ l: AppLanguage) -> String { L10n.tr(l, "All", "Alle") }
        public static func filterAwaiting(_ l: AppLanguage) -> String { L10n.tr(l, "Action", "Aktion") }
        public static func filterSent(_ l: AppLanguage) -> String { L10n.tr(l, "Sent", "Gesendet") }
        public static func filterFailed(_ l: AppLanguage) -> String { L10n.tr(l, "Failed / Skip", "Fehler / Skip") }
        public static func searchPlaceholder(_ l: AppLanguage) -> String { L10n.tr(l, "Search callsign, band, mode...", "Suche Rufzeichen, Band, Mode...") }
        
        public static func emptyTitle(_ l: AppLanguage) -> String { L10n.tr(l, "No QSOs in Queue", "Keine QSOs in der Warteschlange") }
        public static func emptySubtitle(_ l: AppLanguage) -> String { L10n.tr(l, "Log contacts in WSJT-X / RUMlogNG or add manually to generate QSL cards.", "Logge QSOs in WSJT-X / RUMlogNG oder erstelle manuell QSL-Karten.") }
        public static func simulateSample(_ l: AppLanguage) -> String { L10n.tr(l, "Simulate Sample QSO (WSJT-X)", "Beispiel-QSO simulieren (WSJT-X)") }
        
        public static func addManual(_ l: AppLanguage) -> String { L10n.tr(l, "Add Manual", "Manuell loggen") }
        public static func grabRUMlog(_ l: AppLanguage) -> String { L10n.tr(l, "Grab RUMlog", "RUMlog holen") }
        public static func grabRUMlogHelp(_ l: AppLanguage) -> String { L10n.tr(l, "Fetch the last logged QSO from RUMlogNG via AppleScript and generate QSL card", "Holt das zuletzt geloggte QSO per AppleScript aus RUMlogNG und erzeugt die Karte") }
        public static func grabMacLoggerDX(_ l: AppLanguage) -> String { L10n.tr(l, "Grab MacLoggerDX", "MacLoggerDX holen") }
        public static func grabMacLoggerDXHelp(_ l: AppLanguage) -> String { L10n.tr(l, "Fetch the last logged QSO from MacLoggerDX via AppleScript and generate QSL card", "Holt das zuletzt geloggte QSO per AppleScript aus MacLoggerDX und erzeugt die Karte") }
        public static func simulate(_ l: AppLanguage) -> String { L10n.tr(l, "Simulate", "Simulieren") }
        
        public static func sendSelected(_ l: AppLanguage, count: Int) -> String { L10n.tr(l, "Send \(count) Selected", "\(count) Ausgewählte senden") }
        public static func deleteSelected(_ l: AppLanguage, count: Int) -> String { L10n.tr(l, "Delete \(count) Selected", "\(count) Ausgewählte löschen") }
        public static func setStatusBatch(_ l: AppLanguage, count: Int) -> String { L10n.tr(l, "Set Status for \(count) Selected", "Status für \(count) Ausgewählte setzen") }
        public static func setStatus(_ l: AppLanguage) -> String { L10n.tr(l, "Set Status", "Status setzen") }
        public static func confirmAndSend(_ l: AppLanguage) -> String { L10n.tr(l, "Confirm & Send Card", "Bestätigen & Karte senden") }
        public static func lookupInCallbook(_ l: AppLanguage, provider: String) -> String { L10n.tr(l, "Lookup in Callbook (\(provider))", "Im Callbook nachschlagen (\(provider))") }
        public static func deleteRecord(_ l: AppLanguage) -> String { L10n.tr(l, "Delete Record", "Eintrag löschen") }
        public static func queuedPrefix(_ l: AppLanguage) -> String { L10n.tr(l, "Queued:", "Eingereiht:") }
        public static func sentPrefix(_ l: AppLanguage) -> String { L10n.tr(l, "Sent:", "Gesendet:") }
    }
    
    // MARK: - QSO Detail Inspector
    public struct Detail {
        public static func selectQSOTitle(_ l: AppLanguage) -> String { L10n.tr(l, "Select a QSO", "Wähle ein QSO aus") }
        public static func selectQSOSubtitle(_ l: AppLanguage) -> String { L10n.tr(l, "Select a contact from the queue on the left to preview and dispatch its QSL card.", "Wähle links ein QSO aus, um die QSL-Karte zu prüfen und zu versenden.") }
        
        public static func qsoWith(_ l: AppLanguage, call: String) -> String { L10n.tr(l, "QSO with \(call)", "QSO mit \(call)") }
        public static func clickToZoom(_ l: AppLanguage) -> String { L10n.tr(l, "Click to Zoom", "Klicken zum Vergrößern") }
        public static func qslPreview(_ l: AppLanguage) -> String { L10n.tr(l, "QSL Card Preview", "QSL-Kartenvorschau") }
        public static func recipientStation(_ l: AppLanguage) -> String { L10n.tr(l, "Recipient & Station Details", "Empfänger- & Stationsdaten") }
        
        public static func callsign(_ l: AppLanguage) -> String { L10n.tr(l, "Callsign", "Rufzeichen") }
        public static func name(_ l: AppLanguage) -> String { L10n.tr(l, "Name", "Name") }
        public static func email(_ l: AppLanguage) -> String { L10n.tr(l, "Email", "E-Mail") }
        public static func gridSquare(_ l: AppLanguage) -> String { L10n.tr(l, "Grid Square", "Locator (Grid)") }
        public static func country(_ l: AppLanguage) -> String { L10n.tr(l, "Country", "Land") }
        public static func address(_ l: AppLanguage) -> String { L10n.tr(l, "Address", "Adresse") }
        public static func frequency(_ l: AppLanguage) -> String { L10n.tr(l, "Frequency", "Frequenz") }
        public static func rstSentRcvd(_ l: AppLanguage) -> String { L10n.tr(l, "RST Sent / Rcvd", "RST Gesendet / Empfangen") }
        public static func dateUTC(_ l: AppLanguage) -> String { L10n.tr(l, "Date / Time (UTC)", "Datum / Uhrzeit (UTC)") }
        public static func comment(_ l: AppLanguage) -> String { L10n.tr(l, "Comment", "Kommentar") }
        
        public static func editQSO(_ l: AppLanguage) -> String { L10n.tr(l, "Edit QSO...", "QSO bearbeiten...") }
        public static func lookupCallbook(_ l: AppLanguage, provider: String) -> String { L10n.tr(l, "\(provider) Lookup", "\(provider) Aufrufen") }
        public static func customizeCard(_ l: AppLanguage) -> String { L10n.tr(l, "Customize Card...", "Karte anpassen...") }
        public static func previewAndSend(_ l: AppLanguage) -> String { L10n.tr(l, "Preview & Send", "Vorschau & Senden") }
        public static func sendNow(_ l: AppLanguage) -> String { L10n.tr(l, "Send Now", "Jetzt Senden") }
        public static func missingEmailHelp(_ l: AppLanguage) -> String { L10n.tr(l, "Cannot send: Email address missing. Click 'Edit QSO' to enter one.", "Versand nicht möglich: E-Mail-Adresse fehlt. Klicke auf 'QSO bearbeiten'.") }
    }
    
    // MARK: - Confirmation Sheet
    public struct Confirm {
        public static func title(_ l: AppLanguage) -> String { L10n.tr(l, "Preview & Send QSL Card", "QSL-Karte prüfen & versenden") }
        public static func subtitle(_ l: AppLanguage, call: String) -> String { L10n.tr(l, "Review rendered card and dispatch confirmation for \(call)", "Prüfe die generierte Karte und versende die Bestätigung für \(call)") }
        public static func emailSubject(_ l: AppLanguage) -> String { L10n.tr(l, "Email Subject", "E-Mail-Betreff") }
        public static func emailBody(_ l: AppLanguage) -> String { L10n.tr(l, "Email Message Body", "E-Mail-Nachrichtentext") }
        public static func skip(_ l: AppLanguage) -> String { L10n.tr(l, "Skip (Esc)", "Überspringen (Esc)") }
        public static func send(_ l: AppLanguage) -> String { L10n.tr(l, "Send QSL Card (⌘↵)", "QSL-Karte senden (⌘↵)") }
        public static func sending(_ l: AppLanguage) -> String { L10n.tr(l, "Sending...", "Wird gesendet...") }
    }
    
    // MARK: - Card Designer
    public struct Designer {
        public static func template(_ l: AppLanguage) -> String { L10n.tr(l, "Template:", "Vorlage:") }
        public static func preview(_ l: AppLanguage) -> String { L10n.tr(l, "Preview:", "Vorschau:") }
        public static func sampleDJ6GI(_ l: AppLanguage) -> String { L10n.tr(l, "Sample (DJ6GI)", "Muster (DJ6GI)") }
        public static func newTemplate(_ l: AppLanguage) -> String { L10n.tr(l, "Create new template", "Neue Vorlage erstellen") }
        public static func deleteTemplate(_ l: AppLanguage) -> String { L10n.tr(l, "Delete active template", "Aktive Vorlage löschen") }
        public static func undo(_ l: AppLanguage) -> String { L10n.tr(l, "Undo (⌘Z)", "Rückgängig (⌘Z)") }
        public static func redo(_ l: AppLanguage) -> String { L10n.tr(l, "Redo (⇧⌘Z)", "Wiederholen (⇧⌘Z)") }
        public static func exportImage(_ l: AppLanguage) -> String { L10n.tr(l, "Export Image", "Bild exportieren") }
        public static func layers(_ l: AppLanguage) -> String { L10n.tr(l, "Layers", "Ebenen") }
        public static func addElement(_ l: AppLanguage) -> String { L10n.tr(l, "Add Element", "Element hinzufügen") }
        public static func addCustomText(_ l: AppLanguage) -> String { L10n.tr(l, "Custom Text", "Freier Text") }
        public static func addBadge(_ l: AppLanguage) -> String { L10n.tr(l, "Badge / Sticker", "Sticker / Abzeichen") }
    }
    
    // MARK: - Inspector Panel
    public struct Inspector {
        public static func properties(_ l: AppLanguage) -> String { L10n.tr(l, "Properties", "Eigenschaften") }
        public static func textContent(_ l: AppLanguage) -> String { L10n.tr(l, "Text Content", "Textinhalt") }
        public static func typography(_ l: AppLanguage) -> String { L10n.tr(l, "Typography", "Typografie") }
        public static func chooseFont(_ l: AppLanguage) -> String { L10n.tr(l, "Choose Font...", "Schrift wählen...") }
        public static func textColor(_ l: AppLanguage) -> String { L10n.tr(l, "Text Color", "Textfarbe") }
        public static func alignment(_ l: AppLanguage) -> String { L10n.tr(l, "Alignment", "Ausrichtung") }
        public static func effects(_ l: AppLanguage) -> String { L10n.tr(l, "Visual Effects", "Visuelle Effekte") }
        public static func gold3D(_ l: AppLanguage) -> String { L10n.tr(l, "Gold 3D Extrusion", "3D-Gold-Prägung") }
        public static func neonGlow(_ l: AppLanguage) -> String { L10n.tr(l, "Neon Glow", "Neon-Leuchten") }
        public static func dropShadow(_ l: AppLanguage) -> String { L10n.tr(l, "Drop Shadow", "Schlagschatten") }
        public static func positionAndSize(_ l: AppLanguage) -> String { L10n.tr(l, "Position & Size", "Position & Größe") }
        public static func tableColumns(_ l: AppLanguage) -> String { L10n.tr(l, "Table Columns", "Tabellenspalten") }
        public static func tableStyle(_ l: AppLanguage) -> String { L10n.tr(l, "Table Style", "Tabellen-Stil") }
        public static func headerBackground(_ l: AppLanguage) -> String { L10n.tr(l, "Header Background", "Kopfzeilen-Hintergrund") }
        public static func tableBackground(_ l: AppLanguage) -> String { L10n.tr(l, "Table Background", "Tabellen-Hintergrund") }
        public static func borderColor(_ l: AppLanguage) -> String { L10n.tr(l, "Border Color", "Rahmenfarbe") }
        public static func borderWidth(_ l: AppLanguage) -> String { L10n.tr(l, "Border Width", "Rahmenbreite") }
        public static func greetingRow(_ l: AppLanguage) -> String { L10n.tr(l, "Remarks / Greeting Row", "Gruß- & Bemerkungszeile") }
        public static func backgroundPicture(_ l: AppLanguage) -> String { L10n.tr(l, "Background Picture", "Hintergrundbild") }
        public static func selectImage(_ l: AppLanguage) -> String { L10n.tr(l, "Select Image...", "Bild auswählen...") }
        public static func removeImage(_ l: AppLanguage) -> String { L10n.tr(l, "Remove Image", "Bild entfernen") }
        public static func darkenOverlay(_ l: AppLanguage) -> String { L10n.tr(l, "Darken Overlay", "Abdunkeln / Tönung") }
        public static func cardFormat(_ l: AppLanguage) -> String { L10n.tr(l, "Card Format & Aspect Ratio", "Kartenformat & Seitenverhältnis") }
    }
    
    // MARK: - Settings View
    public struct Settings {
        public static func title(_ l: AppLanguage) -> String { L10n.tr(l, "AutoQSL Settings", "AutoQSL Einstellungen") }
        public static func tabGeneral(_ l: AppLanguage) -> String { L10n.tr(l, "General", "Allgemein") }
        public static func tabStation(_ l: AppLanguage) -> String { L10n.tr(l, "Station Profile", "Stationsprofil") }
        public static func tabCallbook(_ l: AppLanguage) -> String { L10n.tr(l, "Callbook Lookup", "Callbook-Abfrage") }
        public static func tabSending(_ l: AppLanguage) -> String { L10n.tr(l, "Sending Mode", "Betriebsmodus") }
        public static func tabEmailTemplate(_ l: AppLanguage) -> String { L10n.tr(l, "Email Template", "E-Mail-Vorlage") }
        public static func tabEmailDelivery(_ l: AppLanguage) -> String { L10n.tr(l, "Email Delivery", "E-Mail-Versand") }
        public static func tabStorage(_ l: AppLanguage) -> String { L10n.tr(l, "Storage & DB", "Speicher & DB") }
        public static func tabNetwork(_ l: AppLanguage) -> String { L10n.tr(l, "Log & Network", "Log & Netzwerk") }
        
        public static func languageLabel(_ l: AppLanguage) -> String { L10n.tr(l, "Application Language", "Sprache der Anwendung") }
        public static func languageHelp(_ l: AppLanguage) -> String { L10n.tr(l, "Choose the interface language for AutoQSL. Changes apply immediately.", "Wähle die Sprache der Benutzeroberfläche. Änderungen werden sofort wirksam.") }
        public static func saveSettings(_ l: AppLanguage) -> String { L10n.tr(l, "Save Settings", "Einstellungen speichern") }
        public static func done(_ l: AppLanguage) -> String { L10n.tr(l, "Done", "Fertig") }
    }
}
