import SwiftUI

public enum ConfirmationTab: String, CaseIterable, Identifiable {
    case email = "Email Delivery"
    case editCard = "Edit Card Data"
    
    public var id: String { rawValue }
}

public struct QSLConfirmationSheet: View {
    @ObservedObject var appState: AppState
    let qso: QSO
    
    @State private var selectedTab: ConfirmationTab = .email
    
    // Email fields
    @State private var recipientEmail: String = ""
    @State private var emailSubject: String = ""
    @State private var emailBody: String = ""
    
    // Live Editable QSO parameters
    @State private var dxCall: String = ""
    @State private var band: String = "20m"
    @State private var mode: String = "FT8"
    @State private var rstSent: String = "59"
    @State private var rstRcvd: String = "59"
    @State private var comment: String = ""
    @State private var dxName: String = ""
    @State private var dxGrid: String = ""
    @State private var dxCountry: String = ""
    
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    @State private var isCardEditorPresented: Bool = false
    @State private var isCardZoomModalPresented: Bool = false
    
    private var activeCardTemplate: QSLCardTemplate {
        appState.template(for: currentWorkingQSO)
    }
    
    private var currentWorkingQSO: QSO {
        var q = qso
        q.dxCall = dxCall.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        q.band = band
        q.mode = mode
        q.rstSent = rstSent
        q.rstRcvd = rstRcvd
        q.comment = comment
        q.dxName = dxName
        q.dxGrid = dxGrid
        q.dxCountry = dxCountry
        q.dxEmail = recipientEmail
        return q
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "paperplane.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm & Send QSL Card")
                        .font(.headline)
                    Text("Review the generated QSL card and email message before dispatching to \(currentWorkingQSO.dxCall).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { isCardEditorPresented = true }) {
                    Label("Customize Card Layout...", systemImage: "paintbrush")
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content Body: Left Card, Right Controls
            HStack(alignment: .top, spacing: 24) {
                // Left: Card Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Live Card Preview")
                            .font(.headline)
                        Spacer()
                        if currentWorkingQSO.customTemplate != nil {
                            Text("Custom Layout")
                                .font(.caption2.bold())
                                .foregroundColor(.purple)
                        }
                    }
                    
                    // Card Visual Container
                    let previewWidth: CGFloat = 460
                    let previewHeight: CGFloat = previewWidth / CGFloat(activeCardTemplate.aspectRatio.aspectRatio)
                    
                    Button(action: {
                        CardZoomWindowManager.shared.present(template: activeCardTemplate, settings: appState.settings, qso: currentWorkingQSO)
                    }) {
                        ZStack(alignment: .bottomTrailing) {
                            CardCanvasView(
                                template: activeCardTemplate,
                                settings: appState.settings,
                                qso: currentWorkingQSO,
                                isInteractive: false
                            )
                            .frame(width: previewWidth, height: previewHeight)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(radius: 6)
                            
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                Text("Click to Zoom")
                            }
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial)
                            .cornerRadius(6)
                            .padding(8)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Click to open full original size card preview with zoom controls")
                    
                    HStack {
                        Label("Template: \(activeCardTemplate.name)", systemImage: "paintbrush")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("All edits reflect live")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 460)
                
                // Right: Tabs for Email Delivery & Live QSO Editing
                VStack(alignment: .leading, spacing: 12) {
                    Picker("", selection: $selectedTab) {
                        ForEach(ConfirmationTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 4)
                    .padding(.top, 4)
                    
                    ScrollView {
                        if selectedTab == .email {
                            emailDeliverySection
                        } else {
                            editCardDataSection
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            
            Divider()
            
            // Bottom Actions Bar
            HStack {
                Button("Skip / Discard") {
                    appState.skipQSO(qsoId: qso.id)
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Label(appState.settings.emailDeliveryMethod.rawValue, systemImage: "envelope")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.trailing, 8)
                
                if isSending {
                    ProgressView()
                        .scaleEffect(0.7)
                        .padding(.trailing, 8)
                    Text("Sending email...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: {
                    sendConfirmed()
                }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                        Text("Send QSL Card")
                    }
                    .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .disabled(recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
                .keyboardShortcut(.return, modifiers: [.command])
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 960, height: 600)
        .onAppear {
            loadInitialData()
        }

        .overlay {
            if isCardEditorPresented {
                QSLCardEditorModalView(
                    appState: appState,
                    qso: currentWorkingQSO,
                    isPresented: $isCardEditorPresented
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(NSColor.windowBackgroundColor))
                .transition(.opacity)
                .zIndex(90)
            }
        }
    }
    
    private var emailDeliverySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Contact Info Card
            GroupBox(label: Label("Contact Details", systemImage: "person.crop.circle")) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(currentWorkingQSO.dxCall)
                            .font(.title3.bold())
                            .foregroundColor(.accentColor)
                        if !currentWorkingQSO.dxName.isEmpty {
                            Text("(\(currentWorkingQSO.dxName))")
                                .font(.subheadline)
                        }
                        Spacer()
                        if currentWorkingQSO.qrzFound {
                            Label("QRZ Verified", systemImage: "checkmark.seal.fill")
                                .font(.caption.bold())
                                .foregroundColor(.green)
                        }
                    }
                    
                    if !currentWorkingQSO.dxGrid.isEmpty || !currentWorkingQSO.dxCountry.isEmpty {
                        HStack {
                            if !currentWorkingQSO.dxGrid.isEmpty {
                                Label("Grid: \(currentWorkingQSO.dxGrid)", systemImage: "square.grid.3x3.fill")
                                    .font(.caption)
                            }
                            if !currentWorkingQSO.dxCountry.isEmpty {
                                Label(currentWorkingQSO.dxCountry, systemImage: "globe")
                                    .font(.caption)
                            }
                        }
                        .foregroundColor(.secondary)
                    }
                }
                .padding(4)
            }
            
            // Email Recipient Field
            VStack(alignment: .leading, spacing: 4) {
                Text("Recipient Email Address")
                    .font(.caption.bold())
                HStack {
                    TextField("e.g. operator@example.com", text: $recipientEmail)
                        .textFieldStyle(.roundedBorder)
                    
                    if recipientEmail.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .help("Email address is required")
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Subject
            VStack(alignment: .leading, spacing: 4) {
                Text("Email Subject")
                    .font(.caption.bold())
                TextField("Subject", text: $emailSubject)
                    .textFieldStyle(.roundedBorder)
            }
            
            // Message Body
            VStack(alignment: .leading, spacing: 4) {
                Text("Message Body")
                    .font(.caption.bold())
                TextEditor(text: $emailBody)
                    .font(.system(size: 12, design: .monospaced))
                    .frame(height: 95)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            if let err = errorMessage {
                HStack {
                    Image(systemName: "xmark.octagon.fill")
                        .foregroundColor(.red)
                    Text(err)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
        }
        .padding()
    }
    
    private var editCardDataSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            GroupBox(label: Label("QSO Table Data", systemImage: "tablecells")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Callsign").font(.caption2.bold())
                            TextField("Call", text: $dxCall)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Band").font(.caption2.bold())
                            TextField("Band", text: $band)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mode").font(.caption2.bold())
                            TextField("Mode", text: $mode)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RST Sent").font(.caption2.bold())
                            TextField("RST Sent", text: $rstSent)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("RST Rcvd").font(.caption2.bold())
                            TextField("RST Rcvd", text: $rstRcvd)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Card Remarks / Comment").font(.caption2.bold())
                        TextField("Comment", text: $comment)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(4)
            }
            
            GroupBox(label: Label("Recipient Details", systemImage: "person.text.rectangle")) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Operator Name").font(.caption2.bold())
                            TextField("Name", text: $dxName)
                                .textFieldStyle(.roundedBorder)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Grid Square").font(.caption2.bold())
                            TextField("Grid", text: $dxGrid)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Country").font(.caption2.bold())
                        TextField("Country", text: $dxCountry)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(4)
            }
        }
        .padding()
    }
    
    private func loadInitialData() {
        recipientEmail = qso.dxEmail
        dxCall = qso.dxCall
        band = qso.band
        mode = qso.mode
        rstSent = qso.rstSent
        rstRcvd = qso.rstRcvd
        comment = qso.comment
        dxName = qso.dxName
        dxGrid = qso.dxGrid
        dxCountry = qso.dxCountry
        
        emailSubject = EmailTemplateEngine.render(
            template: appState.settings.emailSubjectTemplate,
            qso: qso,
            settings: appState.settings
        )
        emailBody = EmailTemplateEngine.render(
            template: appState.settings.emailBodyTemplate,
            qso: qso,
            settings: appState.settings
        )
    }
    
    private func sendConfirmed() {
        guard !recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please provide a valid recipient email address."
            return
        }
        
        // Save any edited QSO fields first
        let updatedQSO = currentWorkingQSO
        appState.updateQSO(updatedQSO, reRenderCard: true)
        
        isSending = true
        errorMessage = nil
        
        Task {
            await appState.executeSendQSO(
                qsoId: qso.id,
                customEmail: recipientEmail,
                customSubject: emailSubject,
                customBody: emailBody
            )
            isSending = false
        }
    }
}
