import SwiftUI

public struct QSOQueueView: View {
    @ObservedObject var appState: AppState
    
    @State private var filterMode: QueueFilter = .all
    @State private var searchText: String = ""
    @State private var isAddManualPresented: Bool = false
    
    enum QueueFilter: String, CaseIterable {
        case all = "All"
        case awaiting = "Awaiting Action"
        case sent = "Sent"
        case failed = "Failed / Skipped"
    }
    
    private var filteredQSOs: [QSO] {
        appState.qsoQueue.filter { qso in
            let matchesSearch = searchText.isEmpty ||
                qso.dxCall.localizedCaseInsensitiveContains(searchText) ||
                qso.dxName.localizedCaseInsensitiveContains(searchText) ||
                qso.band.localizedCaseInsensitiveContains(searchText) ||
                qso.mode.localizedCaseInsensitiveContains(searchText)
            
            guard matchesSearch else { return false }
            
            switch filterMode {
            case .all: return true
            case .awaiting: return qso.status == .awaitingConfirmation || qso.status == .readyToSend || qso.status == .lookingUpQRZ
            case .sent: return qso.status == .sent
            case .failed: return qso.status == .failed || qso.status == .skipped
            }
        }
    }
    
    public var body: some View {
        HSplitView {
            // Left: List of QSOs
            VStack(spacing: 0) {
                // Search & Filter Header
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        TextField("Search callsign, band, mode...", text: $searchText)
                            .textFieldStyle(.plain)
                        if !searchText.isEmpty {
                            Button(action: { searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    
                    // Filter Picker
                    Picker("Filter", selection: $filterMode) {
                        ForEach(QueueFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(10)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // List Items
                if filteredQSOs.isEmpty {
                    VStack(spacing: 12) {
                        Spacer()
                        Image(systemName: "antenna.radiowaves.left.and.right.slash")
                            .font(.system(size: 36))
                            .foregroundColor(.secondary)
                        Text("No QSOs in Queue")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("AutoQSL is listening for WSJT-X & RUMlog UDP packets on ports \(appState.settings.wsjtxPort) / \(appState.settings.rumlogPort)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                        
                        Button(action: simulateTestQSO) {
                            Label("Simulate Sample QSO (WSJT-X)", systemImage: "sparkles")
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(selection: $appState.selectedQSOId) {
                        ForEach(filteredQSOs) { qso in
                            qsoRowItem(qso)
                                .tag(qso.id)
                                .contextMenu {
                                    Button("Confirm & Send Card") {
                                        appState.qsoAwaitingConfirmation = qso
                                        appState.isConfirmationSheetPresented = true
                                    }
                                    Button("Delete Record", role: .destructive) {
                                        appState.deleteQSO(qsoId: qso.id)
                                    }
                                }
                        }
                    }
                    .listStyle(.inset)
                }
                
                Divider()
                
                // Bottom Bar with Quick Actions
                HStack(spacing: 12) {
                    Button(action: { isAddManualPresented = true }) {
                        Label("Add Manual", systemImage: "plus")
                    }
                    .buttonStyle(.borderless)
                    
                    Button(action: { appState.grabLastQSOFromRUMlog() }) {
                        Label("Grab RUMlog", systemImage: "arrow.triangle.2.circlepath.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .help("Fetch the last logged QSO from RUMlogNG via AppleScript and generate QSL card")
                    
                    Spacer()
                    
                    Button(action: simulateTestQSO) {
                        Label("Simulate", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.borderless)
                }
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
            }
            .frame(minWidth: 320, maxWidth: 450)
            
            // Right: Selected QSO Detail View
            if let selectedId = appState.selectedQSOId,
               let qso = appState.qsoQueue.first(where: { $0.id == selectedId }) {
                QSODetailView(appState: appState, qso: qso)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "envelope.badge")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select a QSO from the queue to view details and card preview")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .sheet(isPresented: $isAddManualPresented) {
            AddManualQSOView(appState: appState, isPresented: $isAddManualPresented)
        }
    }
    
    private func qsoRowItem(_ qso: QSO) -> some View {
        HStack(spacing: 10) {
            // Status Icon
            Image(systemName: qso.status.iconName)
                .foregroundColor(statusColor(qso.status))
                .font(.title3)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(qso.dxCall)
                        .font(.headline)
                    Spacer()
                    Text("\(qso.band) • \(qso.mode)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if !qso.dxName.isEmpty {
                        Text(qso.dxName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(qso.formattedUTCTime + " UTC")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(qso.status.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(statusColor(qso.status))
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(_ status: QSOStatus) -> Color {
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
    
    private func simulateTestQSO() {
        let sampleCalls = ["DJ6GI", "DL1ABC", "W1AW", "JA1QRZ", "G4XYZ", "F6KOP"]
        let call = sampleCalls.randomElement() ?? "DJ6GI"
        let qso = QSO(
            source: .wsjtx,
            dxCall: call,
            band: "20m",
            mode: "FT8",
            frequencyHz: 14074000,
            qsoDate: Date(),
            rstSent: "-12",
            rstRcvd: "-08",
            comment: "73, Thanks for the QSO. I hope to meet you further down the log.",
            txPowerWatts: 50,
            dxName: call == "DJ6GI" ? "Gerd Ihde" : "Amateur Radio Station",
            dxGrid: call == "DJ6GI" ? "JN58td" : "FN31pr",
            dxCountry: call == "DJ6GI" ? "Germany" : "United States",
            dxEmail: call == "DJ6GI" ? "dj6gi@example.com" : "dx@example.org",
            qrzFound: true
        )
        appState.handleIncomingQSO(qso)
    }
}

public struct AddManualQSOView: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var dxCall: String = ""
    @State private var band: String = "20m"
    @State private var mode: String = "FT8"
    @State private var rstSent: String = "59"
    @State private var rstRcvd: String = "59"
    @State private var comment: String = ""
    @State private var dxEmail: String = ""
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Log QSO Manually")
                    .font(.headline)
                Spacer()
                Button("Cancel") { isPresented = false }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            Form {
                Section("Contact Info") {
                    TextField("DX Callsign (e.g. DJ6GI)", text: $dxCall)
                    TextField("Recipient Email (optional, or looked up via QRZ)", text: $dxEmail)
                }
                
                Section("QSO Parameters") {
                    Picker("Band", selection: $band) {
                        ForEach(["160m", "80m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "2m", "70cm"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    Picker("Mode", selection: $mode) {
                        ForEach(["FT8", "FT4", "CW", "SSB", "RTTY", "PSK31", "FM", "MSK144"], id: \.self) {
                            Text($0).tag($0)
                        }
                    }
                    HStack {
                        TextField("RST Sent", text: $rstSent)
                        TextField("RST Rcvd", text: $rstRcvd)
                    }
                    TextField("Comment", text: $comment)
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            HStack {
                Spacer()
                Button("Add & Process QSL") {
                    appState.addManualQSO(
                        dxCall: dxCall,
                        band: band,
                        mode: mode,
                        rstSent: rstSent,
                        rstRcvd: rstRcvd,
                        comment: comment,
                        dxEmail: dxEmail
                    )
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(dxCall.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 440, height: 460)
    }
}
