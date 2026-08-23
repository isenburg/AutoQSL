import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public var settings: AppSettings {
        didSet {
            PersistenceService.shared.saveSettings(settings)
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
    
    @Published public var selectedQSOId: UUID? = nil
    
    // Confirmation Dialog / Modal State
    @Published public var qsoAwaitingConfirmation: QSO? = nil
    @Published public var isConfirmationSheetPresented: Bool = false
    
    // Status and Services
    @Published public var lastLogMessage: String = "Ready"
    
    public let udpListener = UDPListenerService()
    public let qrzService = QRZService()
    public let smtpService = SMTPService()
    public let appleMailService = AppleMailService.shared
    
    public init() {
        let loadedSettings = PersistenceService.shared.loadSettings()
        self.settings = loadedSettings
        
        let loadedTemplates = PersistenceService.shared.loadTemplates(myCall: loadedSettings.myCallsign)
        self.templates = loadedTemplates
        
        let initialTemplateId = loadedSettings.activeTemplateId ?? loadedTemplates.first?.id ?? UUID()
        self.selectedTemplateId = initialTemplateId
        
        self.qsoQueue = PersistenceService.shared.loadQSOQueue()
        
        setupUDPListener()
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
    
    public func startUDPListening() {
        var ports: [(port: Int, name: String)] = []
        if settings.wsjtxEnabled {
            ports.append((port: settings.wsjtxPort, name: "WSJT-X"))
        }
        if settings.rumlogEnabled {
            ports.append((port: settings.rumlogPort, name: "RUMlogNG"))
        }
        udpListener.startListening(ports: ports)
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
        if qso.myCall.isEmpty { qso.myCall = settings.myCallsign }
        if qso.myGrid.isEmpty { qso.myGrid = settings.myGrid }
        if qso.myName.isEmpty { qso.myName = settings.myName }
        if qso.myAddress.isEmpty { qso.myAddress = settings.fullMyAddress }
        if qso.myCQZone.isEmpty { qso.myCQZone = settings.myCQZone }
        if qso.myITUZone.isEmpty { qso.myITUZone = settings.myITUZone }
        if qso.comment.isEmpty { qso.comment = settings.defaultComment }
        
        // Add to queue at the top
        qsoQueue.insert(qso, at: 0)
        selectedQSOId = qso.id
        
        Task {
            await processQSO(qsoId: qso.id)
        }
    }
    
    public func processQSO(qsoId: UUID) async {
        guard let index = qsoQueue.firstIndex(where: { $0.id == qsoId }) else { return }
        qsoQueue[index].status = .lookingUpQRZ
        lastLogMessage = "Looking up QRZ info for \(qsoQueue[index].dxCall)..."
        
        // 1. QRZ Lookup if enabled
        if settings.qrzEnabled {
            if let profile = await qrzService.lookup(callsign: qsoQueue[index].dxCall, username: settings.qrzUsername, password: settings.qrzPassword) {
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
        }
        
        let currentQSO = qsoQueue[index]
        
        // 2. Render Card
        if let cardURL = CardRenderer.shared.saveCardToFile(
            template: activeTemplate,
            settings: settings,
            qso: currentQSO,
            targetDirectory: PersistenceService.shared.renderedCardsDirectory
        ) {
            qsoQueue[index].generatedCardPath = cardURL.path
        }
        
        // 3. Routing based on SendingMode
        switch settings.sendingMode {
        case .confirmBeforeSend:
            qsoQueue[index].status = .awaitingConfirmation
            qsoAwaitingConfirmation = qsoQueue[index]
            isConfirmationSheetPresented = true
            lastLogMessage = "Awaiting confirmation to send QSL card to \(currentQSO.dxCall)"
            
        case .autoSend:
            if !currentQSO.dxEmail.isEmpty {
                await executeSendQSO(qsoId: currentQSO.id)
            } else {
                qsoQueue[index].status = .awaitingConfirmation
                qsoQueue[index].statusMessage = "No email address found on QRZ. Please enter email manually."
                qsoAwaitingConfirmation = qsoQueue[index]
                isConfirmationSheetPresented = true
            }
            
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
        
        guard let cardData = CardRenderer.shared.renderCardToJPEGData(
            template: activeTemplate,
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
        let filename = "QSL_\(cleanCall)_\(qso.formattedDateYear)\(qso.formattedDateMonth)\(qso.formattedDateDay).jpg"
        
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
        if selectedQSOId == qsoId {
            selectedQSOId = qsoQueue.first?.id
        }
    }
    
    public func addManualQSO(
        dxCall: String,
        band: String,
        mode: String,
        rstSent: String,
        rstRcvd: String,
        comment: String,
        dxEmail: String
    ) {
        let qso = QSO(
            source: .manual,
            dxCall: dxCall,
            band: band,
            mode: mode,
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
