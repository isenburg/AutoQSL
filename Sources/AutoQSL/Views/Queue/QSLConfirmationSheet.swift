import SwiftUI

public struct QSLConfirmationSheet: View {
    @ObservedObject var appState: AppState
    let qso: QSO
    
    @State private var recipientEmail: String
    @State private var emailSubject: String
    @State private var emailBody: String
    @State private var isSending: Bool = false
    @State private var errorMessage: String? = nil
    
    public init(appState: AppState, qso: QSO) {
        self.appState = appState
        self.qso = qso
        _recipientEmail = State(initialValue: qso.dxEmail)
        _emailSubject = State(initialValue: EmailTemplateEngine.render(template: appState.settings.emailSubjectTemplate, qso: qso, settings: appState.settings))
        _emailBody = State(initialValue: EmailTemplateEngine.render(template: appState.settings.emailBodyTemplate, qso: qso, settings: appState.settings))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "envelope.badge.shield.half.filled")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Confirm QSL Card Delivery")
                        .font(.title3.bold())
                    Text("Review the generated card and contact details for \(qso.dxCall) before emailing.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                Button(action: {
                    appState.skipQSO(qsoId: qso.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Content
            HSplitView {
                // Left: Live Card Preview
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Card Preview")
                            .font(.headline)
                        Spacer()
                        Text("\(qso.band) • \(qso.mode) • \(qso.formattedUTCTime) UTC")
                            .font(.caption.monospaced())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(6)
                    }
                    
                    // Card Visual Container
                    CardCanvasView(
                        template: appState.activeTemplate,
                        settings: appState.settings,
                        qso: qso,
                        isInteractive: false
                    )
                    .frame(width: 440, height: 280)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(radius: 6)
                    
                    HStack {
                        Label("Template: \(appState.activeTemplate.name)", systemImage: "paintbrush")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding()
                .frame(minWidth: 460)
                
                // Right: Recipient & Email Details
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Contact Info Card
                        GroupBox(label: Label("Contact Details", systemImage: "person.crop.circle")) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(qso.dxCall)
                                        .font(.title2.bold())
                                        .foregroundColor(.accentColor)
                                    if !qso.dxName.isEmpty {
                                        Text("(\(qso.dxName))")
                                            .font(.headline)
                                    }
                                    Spacer()
                                    if qso.qrzFound {
                                        Label("QRZ Verified", systemImage: "checkmark.seal.fill")
                                            .font(.caption.bold())
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                if !qso.dxGrid.isEmpty || !qso.dxCountry.isEmpty {
                                    HStack {
                                        if !qso.dxGrid.isEmpty {
                                            Label("Grid: \(qso.dxGrid)", systemImage: "square.grid.3x3.fill")
                                                .font(.caption)
                                        }
                                        if !qso.dxCountry.isEmpty {
                                            Label(qso.dxCountry, systemImage: "globe")
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
                                .frame(height: 110)
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
                .frame(minWidth: 360)
            }
            
            Divider()
            
            // Footer Action Bar
            HStack {
                Button("Skip / Discard") {
                    appState.skipQSO(qsoId: qso.id)
                }
                .keyboardShortcut(.escape, modifiers: [])
                
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
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 860, height: 560)
    }
    
    private func sendConfirmed() {
        guard !recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please provide a valid recipient email address."
            return
        }
        
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
