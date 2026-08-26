import SwiftUI

public struct QSODetailView: View {
    @ObservedObject var appState: AppState
    let qso: QSO
    
    @State private var isEditQSOModalPresented: Bool = false
    @State private var isCardEditorPresented: Bool = false
    @State private var isCardZoomModalPresented: Bool = false
    
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
                                .help("Double-click to open in Callbook")
                                .onTapGesture(count: 2) {
                                    openCallbook(for: qso.dxCall)
                                }
                            
                            Button(action: {
                                openCallbook(for: qso.dxCall)
                            }) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 16))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Open \(callbookProviderName) profile in browser")
                            
                            StatusBadgeView(status: qso.status)
                            
                            if qso.customTemplate != nil {
                                HStack(spacing: 4) {
                                    Image(systemName: "paintbrush.pointed.fill")
                                    Text(L10n.tr(appState.settings.appLanguage, "Customized Card", "Individuelle Karte"))
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
                            Label(L10n.Detail.editQSO(appState.settings.appLanguage), systemImage: "pencil")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            isCardEditorPresented = true
                        }) {
                            Label(L10n.Detail.customizeCard(appState.settings.appLanguage), systemImage: "paintbrush")
                        }
                        .buttonStyle(.bordered)
                        
                        if qso.status == .awaitingConfirmation || qso.status == .readyToSend || qso.status == .failed || qso.status == .skipped {
                            Button(action: {
                                appState.qsoAwaitingConfirmation = qso
                                appState.isConfirmationSheetPresented = true
                            }) {
                                Label(L10n.Detail.previewAndSend(appState.settings.appLanguage), systemImage: "paperplane.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        } else if qso.status == .sent {
                            Button(action: {
                                appState.qsoAwaitingConfirmation = qso
                                appState.isConfirmationSheetPresented = true
                            }) {
                                Label(L10n.tr(appState.settings.appLanguage, "Resend Card", "Erneut senden"), systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
                .padding(.bottom, 6)
                
                Divider()
                
                // Generated Card Preview Box
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(L10n.Detail.qslPreview(appState.settings.appLanguage))
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
                        

                    }
                    
                    let previewWidth: CGFloat = 520
                    let previewHeight: CGFloat = previewWidth / CGFloat(cardTemplate.aspectRatio.aspectRatio)
                    
                    Button(action: {
                        CardZoomWindowManager.shared.present(template: cardTemplate, settings: appState.settings, qso: qso)
                    }) {
                        ZStack(alignment: .bottomTrailing) {
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
                            
                            HStack(spacing: 4) {
                                Image(systemName: "magnifyingglass")
                                Text(L10n.Detail.clickToZoom(appState.settings.appLanguage))
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
                }
                

                // Dispatch History (if resent)
                if !qso.dispatchHistory.isEmpty {
                    GroupBox(label: Label(L10n.tr(appState.settings.appLanguage, "Dispatch History (Previous Sends)", "Sendehistorie (Vorherige Sendungen)"), systemImage: "clock.arrow.circlepath")) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(qso.dispatchHistory) { rec in
                                HStack(alignment: .center, spacing: 10) {
                                    Image(systemName: "checkmark.circle")
                                        .foregroundColor(.green)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(rec.sentAt.formatted(date: .abbreviated, time: .shortened))
                                            .font(.caption.bold())
                                        if let tName = rec.templateName {
                                            Text(L10n.tr(appState.settings.appLanguage, "Template: \(tName)", "Vorlage: \(tName)"))
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        if let method = rec.deliveryMethod {
                                            Text(method)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Spacer()
                                    if let path = rec.cardImagePath, FileManager.default.fileExists(atPath: path) {
                                        Button(action: {
                                            NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                                        }) {
                                            Label(L10n.tr(appState.settings.appLanguage, "Show Card", "Karte anzeigen"), systemImage: "photo")
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                                .padding(.vertical, 4)
                                if rec.id != qso.dispatchHistory.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .padding(4)
                    }
                }

                // 2 Column Grid for QSO & Contact Details
                HStack(alignment: .top, spacing: 20) {
                    // Left Column: QSO Parameters
                    GroupBox(label: Label(L10n.tr(appState.settings.appLanguage, "QSO Parameters", "QSO-Parameter"), systemImage: "antenna.radiowaves.left.and.right")) {
                        VStack(alignment: .leading, spacing: 10) {
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Source", "Quelle"), value: qso.source.rawValue)
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Date & Time", "Datum & Zeit"), value: "\(qso.formattedDate(format: appState.settings.dateFormat))  \(qso.formattedUTCTime) UTC")
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Band / Mode", "Band / Mode"), value: "\(qso.band) • \(qso.mode)")
                            if let freq = qso.frequencyHz {
                                qsoRow(label: L10n.tr(appState.settings.appLanguage, "Frequency", "Frequenz"), value: String(format: "%.3f MHz", freq / 1_000_000.0))
                            }
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "RST Sent / Rcvd", "RST Gesendet / Empf."), value: "\(qso.rstSent) / \(qso.rstRcvd)")
                            if let pwr = qso.txPowerWatts {
                                qsoRow(label: L10n.tr(appState.settings.appLanguage, "TX Power", "Sendeleistung"), value: "\(Int(pwr)) W")
                            }
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Remarks", "Kommentar"), value: qso.comment)
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right Column: Recipient Info (QRZ)
                    GroupBox(label: Label(L10n.tr(appState.settings.appLanguage, "Recipient Profile", "Empfängerprofil"), systemImage: "person.crop.square")) {
                        VStack(alignment: .leading, spacing: 10) {
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Callsign", "Rufzeichen"), value: qso.dxCall)
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Email", "E-Mail"), value: qso.dxEmail.isEmpty ? L10n.tr(appState.settings.appLanguage, "Not available", "Nicht verfügbar") : qso.dxEmail)
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Grid Square", "Locator (Grid)"), value: qso.dxGrid.isEmpty ? "—" : qso.dxGrid)
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Country", "Land / DXCC"), value: qso.dxCountry.isEmpty ? "—" : qso.dxCountry)
                            if !qso.dxAddress.isEmpty {
                                qsoRow(label: L10n.tr(appState.settings.appLanguage, "Address", "Adresse"), value: qso.dxAddress)
                            }
                            qsoRow(label: L10n.tr(appState.settings.appLanguage, "Callbook Status", "Callbook-Status"), value: qso.qrzFound ? L10n.tr(appState.settings.appLanguage, "Verified from Callbook", "Verifiziert aus Callbook") : L10n.tr(appState.settings.appLanguage, "Manual / Not verified", "Manuell / Nicht verifiziert"))
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
    
    private var callbookProviderName: String {
        switch appState.settings.callbookProvider {
        case .hamqthOnly, .hamqthPrimary: return "HamQTH"
        case .qrzOnly, .qrzPrimary: return "QRZ.com"
        }
    }
    
    private func openCallbook(for callsign: String) {
        let cleanCall = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCall.isEmpty, let encodedCall = cleanCall.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
        
        let urlString: String
        switch appState.settings.callbookProvider {
        case .hamqthOnly, .hamqthPrimary:
            urlString = "https://www.hamqth.com/\(encodedCall)"
        case .qrzOnly, .qrzPrimary:
            urlString = "https://www.qrz.com/db/\(encodedCall)"
        }
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
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
            Text(status.localizedName(Locale.current.language.languageCode?.identifier == "de" ? .german : .english))
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
        case .failed, .failedEmailMissing: return .red
        case .skipped: return .gray
        }
    }
}
