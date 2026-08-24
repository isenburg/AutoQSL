import SwiftUI

public struct QSODetailView: View {
    @ObservedObject var appState: AppState
    let qso: QSO
    
    @State private var isEditQSOModalPresented: Bool = false
    @State private var isCardEditorPresented: Bool = false
    
    private var cardTemplate: QSLCardTemplate {
        appState.template(for: qso)
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 12) {
                            Text(qso.dxCall)
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(.primary)
                            
                            StatusBadgeView(status: qso.status)
                            
                            if qso.customTemplate != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "paintbrush.pointed.fill")
                                    Text("Customized Card")
                                }
                                .font(.caption2.bold())
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .cornerRadius(6)
                            }
                        }
                        
                        if !qso.dxName.isEmpty {
                            Text(qso.dxName)
                                .font(.title3)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    // Action Buttons
                    HStack(spacing: 10) {
                        Button(action: {
                            isEditQSOModalPresented = true
                        }) {
                            Label("Edit QSO Data", systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            isCardEditorPresented = true
                        }) {
                            Label("Customize Card", systemImage: "paintbrush")
                        }
                        .buttonStyle(.bordered)
                        
                        if qso.status == .awaitingConfirmation || qso.status == .readyToSend || qso.status == .failed || qso.status == .skipped {
                            Button(action: {
                                appState.qsoAwaitingConfirmation = qso
                                appState.isConfirmationSheetPresented = true
                            }) {
                                Label("Preview & Send", systemImage: "paperplane.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        } else if qso.status == .sent {
                            Button(action: {
                                appState.qsoAwaitingConfirmation = qso
                                appState.isConfirmationSheetPresented = true
                            }) {
                                Label("Resend Card", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.bottom, 6)
                
                Divider()
                
                // Generated Card Preview Box
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rendered QSL Card Preview")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Template Switcher Dropdown
                        Menu {
                            Button("Default Template (\(appState.activeTemplate.name))") {
                                appState.setTemplateId(for: qso.id, templateId: appState.activeTemplate.id)
                            }
                            Divider()
                            ForEach(appState.templates) { t in
                                Button(t.name) {
                                    appState.setTemplateId(for: qso.id, templateId: t.id)
                                }
                            }
                        } label: {
                            Label(cardTemplate.name, systemImage: "paintpalette")
                                .font(.caption)
                        }
                        
                        Button(action: { isCardEditorPresented = true }) {
                            Label("Edit Layout", systemImage: "pencil.and.outline")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                    }
                    
                    let previewWidth: CGFloat = 520
                    let previewHeight: CGFloat = previewWidth / CGFloat(cardTemplate.aspectRatio.aspectRatio)
                    
                    CardCanvasView(
                        template: cardTemplate,
                        settings: appState.settings,
                        qso: qso,
                        isInteractive: false
                    )
                    .frame(width: previewWidth, height: previewHeight)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(radius: 4)
                    .onTapGesture {
                        isCardEditorPresented = true
                    }
                    .help("Click to edit card layout and styling")
                }
                
                // 2 Column Grid for QSO & Contact Details
                HStack(alignment: .top, spacing: 20) {
                    // Left Column: QSO Parameters
                    GroupBox(label: Label("QSO Parameters", systemImage: "antenna.radiowaves.left.and.right")) {
                        VStack(alignment: .leading, spacing: 10) {
                            qsoRow(label: "Source", value: qso.source.rawValue)
                            qsoRow(label: "Date & Time", value: "\(qso.formattedDate(format: appState.settings.dateFormat))  \(qso.formattedUTCTime) UTC")
                            qsoRow(label: "Band / Mode", value: "\(qso.band) • \(qso.mode)")
                            if let freq = qso.frequencyHz {
                                qsoRow(label: "Frequency", value: String(format: "%.3f MHz", freq / 1_000_000.0))
                            }
                            qsoRow(label: "RST Sent / Rcvd", value: "\(qso.rstSent) / \(qso.rstRcvd)")
                            if let pwr = qso.txPowerWatts {
                                qsoRow(label: "TX Power", value: "\(Int(pwr)) W")
                            }
                            qsoRow(label: "Remarks", value: qso.comment)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column: Recipient Info (QRZ)
                    GroupBox(label: Label("Recipient Profile", systemImage: "person.crop.square")) {
                        VStack(alignment: .leading, spacing: 10) {
                            qsoRow(label: "Callsign", value: qso.dxCall)
                            qsoRow(label: "Email", value: qso.dxEmail.isEmpty ? "Not available" : qso.dxEmail)
                            qsoRow(label: "Grid Square", value: qso.dxGrid.isEmpty ? "—" : qso.dxGrid)
                            qsoRow(label: "Country", value: qso.dxCountry.isEmpty ? "—" : qso.dxCountry)
                            if !qso.dxAddress.isEmpty {
                                qsoRow(label: "Address", value: qso.dxAddress)
                            }
                            qsoRow(label: "QRZ Status", value: qso.qrzFound ? "Verified from QRZ.com" : "Not on QRZ / Manual")
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // Status History / Error Message if any
                if let msg = qso.statusMessage {
                    GroupBox(label: Label("Status Message", systemImage: "info.circle")) {
                        Text(msg)
                            .font(.callout)
                            .foregroundColor(qso.status == .failed ? .red : .secondary)
                            .padding(.top, 2)
                    }
                }
            }
            .padding(24)
        }
        .sheet(isPresented: $isEditQSOModalPresented) {
            EditQSOModalView(appState: appState, originalQSO: qso, isPresented: $isEditQSOModalPresented)
        }
        .sheet(isPresented: $isCardEditorPresented) {
            QSLCardEditorModalView(appState: appState, qso: qso, isPresented: $isCardEditorPresented)
        }
    }
    
    private func qsoRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 110, alignment: .leading)
            Text(value)
                .font(.callout.bold())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

public struct StatusBadgeView: View {
    public let status: QSOStatus
    
    public var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.iconName)
                .font(.caption)
            Text(status.rawValue)
                .font(.caption.bold())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor.opacity(0.15))
        .foregroundColor(backgroundColor)
        .cornerRadius(6)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .pending, .readyToSend: return .blue
        case .lookingUpQRZ: return .purple
        case .awaitingConfirmation: return .orange
        case .sending: return .indigo
        case .sent: return .green
        case .failed: return .red
        case .skipped: return .gray
        }
    }
}
