import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public var settings: AppSettings {
        didSet {
            PersistenceService.shared.saveSettings(settings)
            startUDPListening()
        }
    }
    
    @Published public var templates: [QSLCardTemplate] {
        didSet {
            PersistenceService.shared.saveTemplates(templates)
        }
    }
    
    @Published public var selectedTemplateId: UUID {
        didSet {
            settings.activeTemplateId = selectedTemplateId
        }
    }
    
    @Published public var qsoQueue: [QSO] = [] {
        didSet {
            PersistenceService.shared.saveQSOQueue(qsoQueue)
        }
    }
    
    @Published public var selectedQSOIds: Set<UUID> = []
    @Published public var navigationSection: NavigationSection = .queue
    
    // Confirmation Dialog / Modal State
    @Published public var qsoAwaitingConfirmation: QSO? = nil
    @Published public var isConfirmationSheetPresented: Bool = false
    
    // Status and Services
    @Published public var lastLogMessage: String = "Ready"
    
    public let udpListener = UDPListenerService()
    public let qrzService = QRZService()
    public let hamqthService = HamQTHService()
    public let smtpService = SMTPService()
    public let appleMailService = AppleMailService.shared
    
    public init() {
        let loadedSettings = PersistenceService.shared.loadSettings()
        self.settings = loadedSettings
        
        let loadedTemplates = PersistenceService.shared.loadTemplates(myCall: loadedSettings.myCallsign, myAddress: loadedSettings.fullMyAddress)
        self.templates = loadedTemplates
        
        let initialTemplateId = loadedSettings.activeTemplateId ?? loadedTemplates.first?.id ?? UUID()
        self.selectedTemplateId = initialTemplateId
        
        self.qsoQueue = PersistenceService.shared.loadQSOQueue()
        
        PrefixMatcher.shared.loadCtyDatabase()
        if settings.myCQZone.isEmpty || settings.myITUZone.isEmpty || settings.myCountry.isEmpty {
            settings.autofillStationZonesAndCountry(for: settings.myCallsign, overwriteNonEmpty: false)
        }
        
        setupUDPListener()
    }
    
    public func switchStorageLocation(to newLocation: StorageLocation, migrateCurrentData: Bool = true) {
        let oldLocation = settings.storageLocation
        guard oldLocation != newLocation else { return }
        
        if migrateCurrentData {
            do {
                try PersistenceService.shared.migrateData(from: oldLocation, to: newLocation)
                lastLogMessage = "Successfully migrated all data to \(newLocation.rawValue)."
            } catch {
                lastLogMessage = "Migration warning: \(error.localizedDescription)"
            }
        }
        
        settings.storageLocation = newLocation
        PersistenceService.shared.saveSettings(settings, to: newLocation)
        
        // Reload from new storage location
        let loadedTemplates = PersistenceService.shared.loadTemplates(from: newLocation, myCall: settings.myCallsign, myAddress: settings.fullMyAddress)
        self.templates = loadedTemplates
        self.qsoQueue = PersistenceService.shared.loadQSOQueue(from: newLocation)
        
        if let activeId = settings.activeTemplateId, templates.contains(where: { $0.id == activeId }) {
            self.selectedTemplateId = activeId
        } else {
            self.selectedTemplateId = templates.first?.id ?? UUID()
        }
    }
    
    public var activeTemplate: QSLCardTemplate {
        get {
            templates.first(where: { $0.id == selectedTemplateId }) ?? templates.first ?? QSLCardTemplate.createDefaultTemplate(myCall: settings.myCallsign)
        }
        set {
            if let idx = templates.firstIndex(where: { $0.id == newValue.id }) {
                templates[idx] = newValue
            }
        }
    }
    
    public func template(for qso: QSO) -> QSLCardTemplate {
        if let custom = qso.customTemplate {
            return custom
        }
        if let tid = qso.templateId, let t = templates.first(where: { $0.id == tid }) {
            return t
        }
        return activeTemplate
    }
    
    public func updateQSO(_ updatedQSO: QSO, reRenderCard: Bool = true) {
        guard let index = qsoQueue.firstIndex(where: { $0.id == updatedQSO.id }) else { return }
        var qso = updatedQSO
        
        if reRenderCard {
            let cardTmpl = template(for: qso)
            if let cardURL = CardRenderer.shared.saveCardToFile(
                template: cardTmpl,
                settings: settings,
                qso: qso,
                targetDirectory: PersistenceService.shared.renderedCardsDirectory
            ) {
                qso.generatedCardPath = cardURL.path
            }
        }
        
        qsoQueue[index] = qso
        if qsoAwaitingConfirmation?.id == qso.id {
            qsoAwaitingConfirmation = qso
        }
        lastLogMessage = "Updated QSL card for \(qso.dxCall)."
    }
    
    public func setCustomTemplate(for qsoId: UUID, template: QSLCardTemplate?) {
        guard let index = qsoQueue.firstIndex(where: { $0.id == qsoId }) else { return }
        var qso = qsoQueue[index]
        qso.customTemplate = template
        updateQSO(qso, reRenderCard: true)
    }
    
    public func setTemplateId(for qsoId: UUID, templateId: UUID) {
        guard let index = qsoQueue.firstIndex(where: { $0.id == qsoId }) else { return }
        var qso = qsoQueue[index]
        qso.templateId = templateId
        qso.customTemplate = nil
        updateQSO(qso, reRenderCard: true)
    }
    
    public func deleteTemplate(id: UUID) {
        guard templates.count > 1 else { return }
        guard let templateToDelete = templates.first(where: { $0.id == id }) else { return }
        
        // Preserve a snapshot of this template on any QSOs that currently reference it,
        // so deleting the template NEVER destroys or changes previously sent or queued cards!
        for i in 0..<qsoQueue.count {
            if qsoQueue[i].templateId == id && qsoQueue[i].customTemplate == nil {
                qsoQueue[i].customTemplate = templateToDelete
            }
        }
        
        templates.removeAll(where: { $0.id == id })
        if selectedTemplateId == id {
            selectedTemplateId = templates.first?.id ?? UUID()
        }
        lastLogMessage = "Deleted template '\(templateToDelete.name)'. Existing sent and queued cards are safely preserved."
    }
    
    public func startUDPListening() {
        var listeners: [(port: Int, address: String, name: String)] = []
        
        if settings.wsjtxEnabled {
            let isMC = AppSettings.isMulticast(address: settings.wsjtxAddress)
            let mode = isMC ? "MC" : "UC"
            listeners.append((port: settings.wsjtxPort, address: settings.wsjtxAddress, name: "WSJT-X etc. (\(mode))"))
        }
        
        if settings.rumlogEnabled {
            let isMC = AppSettings.isMulticast(address: settings.rumlogAddress)
            let mode = isMC ? "MC" : "UC"
            listeners.append((port: settings.rumlogPort, address: settings.rumlogAddress, name: "RL (RUMlog) (\(mode))"))
        }
        
        udpListener.startListening(listeners: listeners)
    }
    
    private func setupUDPListener() {
        udpListener.onQSORecordReceived = { [weak self] incomingQSO in
            Task { @MainActor [weak self] in
                self?.handleIncomingQSO(incomingQSO)
            }
        }
        startUDPListening()
    }
    
    public func handleIncomingQSO(_ incoming: QSO) {
        var qso = incoming
        lastLogMessage = "Received QSO from \(qso.source.rawValue.uppercased()): \(qso.dxCall) on \(qso.band) (\(qso.mode))" 
        if qso.myCall.isEmpty { qso.myCall = settings.myCallsign }
        if qso.myGrid.isEmpty { qso.myGrid = settings.myGrid }
        if qso.myName.isEmpty { qso.myName = settings.myName }
        if qso.myAddress.isEmpty { qso.myAddress = settings.fullMyAddress }
        if qso.myCQZone.isEmpty {
            if let cq = PrefixMatcher.shared.cqZone(for: qso.myCall) {
                qso.myCQZone = "\(cq)"
            } else {
                qso.myCQZone = settings.myCQZone
            }
        }
        if qso.myITUZone.isEmpty {
            if let itu = PrefixMatcher.shared.ituZone(for: qso.myCall) {
                qso.myITUZone = "\(itu)"
            } else {
                qso.myITUZone = settings.myITUZone
            }
        }
        if qso.dxCountry.isEmpty || qso.dxCountry == "OTHER" {
            let matched = PrefixMatcher.shared.country(for: qso.dxCall)
            if matched != "OTHER" && !matched.isEmpty {
                qso.dxCountry = matched
            }
        }
        if qso.comment.isEmpty { qso.comment = settings.defaultComment }
        
        qsoQueue.insert(qso, at: 0)
        selectedQSOIds = [qso.id]
        
        Task {
            await processQSO(qsoId: qso.id)
        }
    }
    
    public func processQSO(qsoId: UUID) async {
        guard let index = qsoQueue.firstIndex(where: { $0.id == qsoId }) else { return }
        qsoQueue[index].status = .lookingUpQRZ
        lastLogMessage = "Looking up QRZ info for \(qsoQueue[index].dxCall)..."
        
        // 1. Callbook Lookup (QRZ.com & HamQTH)
        let callsign = qsoQueue[index].dxCall
        var foundProfile: QRZProfile? = nil
        
        switch settings.callbookProvider {
        case .qrzPrimary:
            if settings.qrzEnabled {
                lastLogMessage = "Looking up QRZ info for \(callsign)..."
                foundProfile = await qrzService.lookup(callsign: callsign, username: settings.qrzUsername, password: settings.qrzPassword)
            }
            if (foundProfile == nil || (foundProfile?.email?.isEmpty ?? true)) && settings.hamqthEnabled {
                lastLogMessage = "Looking up HamQTH info for \(callsign)..."
                if let hProfile = await hamqthService.lookup(callsign: callsign, username: settings.hamqthUsername, password: settings.hamqthPassword) {
                    if foundProfile == nil {
                        foundProfile = hProfile
                    } else if let hEmail = hProfile.email, !hEmail.isEmpty {
                        foundProfile?.email = hEmail
                    }
                }
            }
            
        case .hamqthPrimary:
            if settings.hamqthEnabled {
                lastLogMessage = "Looking up HamQTH info for \(callsign)..."
                foundProfile = await hamqthService.lookup(callsign: callsign, username: settings.hamqthUsername, password: settings.hamqthPassword)
            }
            if (foundProfile == nil || (foundProfile?.email?.isEmpty ?? true)) && settings.qrzEnabled {
                lastLogMessage = "Looking up QRZ info for \(callsign)..."
                if let qProfile = await qrzService.lookup(callsign: callsign, username: settings.qrzUsername, password: settings.qrzPassword) {
                    if foundProfile == nil {
                        foundProfile = qProfile
                    } else if let qEmail = qProfile.email, !qEmail.isEmpty {
                        foundProfile?.email = qEmail
                    }
                }
            }
            
        case .qrzOnly:
            if settings.qrzEnabled {
                lastLogMessage = "Looking up QRZ info for \(callsign)..."
                foundProfile = await qrzService.lookup(callsign: callsign, username: settings.qrzUsername, password: settings.qrzPassword)
            }
            
        case .hamqthOnly:
            if settings.hamqthEnabled {
                lastLogMessage = "Looking up HamQTH info for \(callsign)..."
                foundProfile = await hamqthService.lookup(callsign: callsign, username: settings.hamqthUsername, password: settings.hamqthPassword)
            }
        }
        
        if let profile = foundProfile {
            if let email = profile.email, !email.isEmpty {
                qsoQueue[index].dxEmail = email
            }
            if let name = profile.fname ?? profile.name, !name.isEmpty {
                qsoQueue[index].dxName = profile.fullName
            }
            if let grid = profile.grid, !grid.isEmpty {
                qsoQueue[index].dxGrid = grid
            }
            if let country = profile.country, !country.isEmpty {
                qsoQueue[index].dxCountry = country
            }
            qsoQueue[index].dxAddress = profile.fullAddressFormatted
            qsoQueue[index].qrzFound = true
        }
        
        let currentQSO = qsoQueue[index]
        let cardTemplate = template(for: currentQSO)
        
        // 2. Render Card
        if let cardURL = CardRenderer.shared.saveCardToFile(
            template: cardTemplate,
            settings: settings,
            qso: currentQSO,
            targetDirectory: PersistenceService.shared.renderedCardsDirectory
        ) {
            qsoQueue[index].generatedCardPath = cardURL.path
        }
        
        if qsoQueue[index].dxEmail.isEmpty {
            qsoQueue[index].status = .failed
            qsoQueue[index].statusMessage = "Email missing"
            lastLogMessage = "QSO with \(currentQSO.dxCall) failed: Email missing"
            return
        }
        
        // 3. Routing based on SendingMode
        switch settings.sendingMode {
        case .confirmBeforeSend:
            qsoQueue[index].status = .awaitingConfirmation
            qsoAwaitingConfirmation = qsoQueue[index]
            isConfirmationSheetPresented = true
            lastLogMessage = "Awaiting confirmation to send QSL card to \(currentQSO.dxCall)"
            NSApp.activate(ignoringOtherApps: true)
            
        case .autoSend:
            await executeSendQSO(qsoId: currentQSO.id)
            
        case .manualQueue:
            qsoQueue[index].status = .readyToSend
            lastLogMessage = "QSO with \(currentQSO.dxCall) queued for manual review."
        }
    }
    
    public func executeSendQSO(
        qsoId: UUID,
        customEmail: String? = nil,
        customSubject: String? = nil,
        customBody: String? = nil
    ) async {
        guard let index = qsoQueue.firstIndex(where: { $0.id == qsoId }) else { return }
        
        if let customEmail = customEmail, !customEmail.isEmpty {
            qsoQueue[index].dxEmail = customEmail
        }
        
        let qso = qsoQueue[index]
        guard !qso.dxEmail.isEmpty else {
            qsoQueue[index].status = .failed
            qsoQueue[index].statusMessage = "Recipient email address is missing"
            return
        }
        
        qsoQueue[index].status = .sending
        lastLogMessage = "Sending QSL card to \(qso.dxCall) (\(qso.dxEmail))..."
        
        let cardTemplate = template(for: qso)
        
        guard let cardData = CardRenderer.shared.renderCardToJPEGData(
            template: cardTemplate,
            settings: settings,
            qso: qso
        ) else {
            qsoQueue[index].status = .failed
            qsoQueue[index].statusMessage = "Failed to render QSL card image"
            return
        }
        
        let subject = customSubject ?? EmailTemplateEngine.render(template: settings.emailSubjectTemplate, qso: qso, settings: settings)
        let body = customBody ?? EmailTemplateEngine.render(template: settings.emailBodyTemplate, qso: qso, settings: settings)
        let cleanCall = qso.dxCall.replacingOccurrences(of: "/", with: "_")
        let timeStr = qso.formattedUTCTime.replacingOccurrences(of: ":", with: "")
        let filename = "QSL_\(cleanCall)_\(qso.formattedDateYear)\(qso.formattedDateMonth)\(qso.formattedDateDay)_\(timeStr)_\(qso.id.uuidString.prefix(6)).jpg"
        
        // Always write fresh rendered card image to disk
        let cardDir = PersistenceService.shared.renderedCardsDirectory
        let cardFileURL = cardDir.appendingPathComponent(filename)
        try? cardData.write(to: cardFileURL)
        let cardPath = cardFileURL.path
        qsoQueue[index].generatedCardPath = cardPath

        do {
            switch settings.emailDeliveryMethod {
            case .appleMail:
                try await AppleMailService.shared.sendViaAppleMail(
                    recipientEmail: qso.dxEmail,
                    recipientName: qso.dxName.isEmpty ? qso.dxCall : qso.dxName,
                    subject: subject,
                    bodyText: body,
                    attachmentPath: cardPath,
                    sendImmediately: settings.appleMailSendImmediately
                )
                qsoQueue[index].status = .sent
                qsoQueue[index].sentAt = Date()
                qsoQueue[index].statusMessage = settings.appleMailSendImmediately ? "Sent via Apple Mail" : "Draft created in Apple Mail"
                lastLogMessage = "QSL Card dispatched via Apple Mail to \(qso.dxCall)!"
                
            case .defaultClient:
                AppleMailService.shared.openComposeWindow(
                    recipientEmail: qso.dxEmail,
                    subject: subject,
                    bodyText: body,
                    attachmentPath: cardPath
                )
                qsoQueue[index].status = .sent
                qsoQueue[index].sentAt = Date()
                qsoQueue[index].statusMessage = "Opened in Default Mail Client"
                lastLogMessage = "Opened email composer for \(qso.dxCall)!"
                
            case .directSMTP:
                try await smtpService.sendQSLCard(
                    recipientEmail: qso.dxEmail,
                    recipientCall: qso.dxCall,
                    subject: subject,
                    bodyText: body,
                    cardImageData: cardData,
                    imageFilename: filename,
                    settings: settings
                )
                qsoQueue[index].status = .sent
                qsoQueue[index].sentAt = Date()
                qsoQueue[index].statusMessage = "Successfully emailed via SMTP to \(qso.dxEmail)"
                lastLogMessage = "QSL Card sent to \(qso.dxCall) via SMTP successfully!"
            }
            
            if qsoAwaitingConfirmation?.id == qso.id {
                isConfirmationSheetPresented = false
                qsoAwaitingConfirmation = nil
            }
        } catch {
            qsoQueue[index].status = .failed
            qsoQueue[index].statusMessage = error.localizedDescription
            lastLogMessage = "Failed sending to \(qso.dxCall): \(error.localizedDescription)"
        }
    }
    
    /// Sequentially dispatches multiple queued QSOs with safe pacing to avoid Apple Mail / SMTP concurrency lockups
    public func executeBatchSendQSOs(qsoIds: [UUID]) async {
        for (index, id) in qsoIds.enumerated() {
            await executeSendQSO(qsoId: id)
            if index < qsoIds.count - 1 {
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms spacing between batch emails
            }
        }
    }
    
    public func skipQSO(qsoId: UUID) {
        if let index = qsoQueue.firstIndex(where: { $0.id == qsoId }) {
            qsoQueue[index].status = .skipped
            qsoQueue[index].statusMessage = "Skipped by user"
        }
        if qsoAwaitingConfirmation?.id == qsoId {
            isConfirmationSheetPresented = false
            qsoAwaitingConfirmation = nil
        }
    }
    
    public func deleteQSO(qsoId: UUID) {
        qsoQueue.removeAll(where: { $0.id == qsoId })
        selectedQSOIds.remove(qsoId)
        QSODatabaseService.shared.delete(qsoId: qsoId)
    }
    
    public func deleteQSOs(qsoIds: Set<UUID>) {
        qsoQueue.removeAll(where: { qsoIds.contains($0.id) })
        selectedQSOIds.subtract(qsoIds)
        QSODatabaseService.shared.deleteBatch(ids: Array(qsoIds))
    }
    
    public func addManualQSO(
        dxCall: String,
        band: String,
        mode: String,
        frequencyHz: Double? = nil,
        rstSent: String,
        rstRcvd: String,
        comment: String,
        dxEmail: String
    ) {
        let finalFreq: Double?
        if let f = frequencyHz, f > 0 {
            finalFreq = f
        } else if let defMHz = RadioUtils.defaultFrequencyMHz(for: band) {
            finalFreq = defMHz * 1_000_000.0
        } else {
            finalFreq = nil
        }
        
        let qso = QSO(
            source: .manual,
            dxCall: dxCall,
            band: band,
            mode: mode,
            frequencyHz: finalFreq,
            rstSent: rstSent,
            rstRcvd: rstRcvd,
            comment: comment.isEmpty ? settings.defaultComment : comment,
            dxEmail: dxEmail
        )
        handleIncomingQSO(qso)
    }
    
    public func grabLastQSOFromRUMlog() {
        lastLogMessage = "Querying RUMlogNG for last logged QSO via AppleScript..."
        Task {
            do {
                let qso = try await RUMlogAppleScriptService.shared.fetchLastQSO()
                await MainActor.run {
                    self.lastLogMessage = "Grabbed last QSO \(qso.dxCall) from RUMlogNG."
                    self.handleIncomingQSO(qso)
                }
            } catch {
                await MainActor.run {
                    self.lastLogMessage = "Error querying RUMlogNG: \(error.localizedDescription)"
                }
            }
        }
    }
}
