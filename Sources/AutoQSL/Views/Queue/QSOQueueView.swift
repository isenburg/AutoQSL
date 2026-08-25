import SwiftUI

public struct QSOQueueView: View {
    @ObservedObject var appState: AppState
    
    @AppStorage("AutoQSL_QueueSidebarWidth") private var queueSidebarWidth: Double = 420.0
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
            // Left: List of QSOs (Resizable, Min 340)
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
                    Picker("", selection: $filterMode) {
                        ForEach(QueueFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
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
                        Text(verbatim: "AutoQSL is listening for WSJT-X & RUMlog UDP packets on ports \(appState.settings.wsjtxPort) / \(appState.settings.rumlogPort)")
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
                    List(selection: $appState.selectedQSOIds) {
                        ForEach(filteredQSOs) { qso in
                            qsoRowItem(qso)
                                .tag(qso.id)
                                .listRowInsets(EdgeInsets(top: 0, leading: 8, bottom: 0, trailing: 8))
                                .contextMenu {
                                    if appState.selectedQSOIds.contains(qso.id) && appState.selectedQSOIds.count > 1 {
                                        Button("Send \(appState.selectedQSOIds.count) Selected") {
                                            sendSelectedQSOs()
                                        }
                                        Button("Delete \(appState.selectedQSOIds.count) Selected", role: .destructive) {
                                            appState.deleteQSOs(qsoIds: appState.selectedQSOIds)
                                        }
                                    } else {
                                        Button("Confirm & Send Card") {
                                            appState.qsoAwaitingConfirmation = qso
                                            appState.isConfirmationSheetPresented = true
                                        }
                                        Button("Lookup in Callbook (\(callbookProviderName))") {
                                            openCallbook(for: qso.dxCall)
                                        }
                                        Button("Delete Record", role: .destructive) {
                                            appState.deleteQSO(qsoId: qso.id)
                                        }
                                    }
                                }
                        }
                    }
                    .listStyle(.inset)
                    .onDeleteCommand {
                        appState.deleteQSOs(qsoIds: appState.selectedQSOIds)
                    }
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
            }
            .frame(minWidth: 340, idealWidth: CGFloat(queueSidebarWidth), maxWidth: 650)
            .layoutPriority(0)
            .background(SplitViewAutosaver(name: "AutoQSL_Queue_SplitView"))
            
            // Right: Selected QSO Detail View (Single stable root view to prevent NSSplitView collapse)
            ZStack {
                Color(NSColor.windowBackgroundColor)
                
                if appState.selectedQSOIds.count > 1 {
                    VStack(spacing: 14) {
                        Image(systemName: "square.stack.3d.up")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("\(appState.selectedQSOIds.count) QSOs selected")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Button(action: {
                                appState.deleteQSOs(qsoIds: appState.selectedQSOIds)
                            }) {
                                Label("Delete Selected", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            .tint(.red)
                            
                            Button(action: {
                                sendSelectedQSOs()
                            }) {
                                Label("Send Selected", systemImage: "paperplane.fill")
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.top, 16)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let selectedId = appState.selectedQSOIds.first,
                   let qso = appState.qsoQueue.first(where: { $0.id == selectedId }) {
                    QSODetailView(appState: appState, qso: qso)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
            .frame(minWidth: 420, maxWidth: .infinity, maxHeight: .infinity)
            .layoutPriority(1)
        }
        .sheet(isPresented: $isAddManualPresented) {
            AddManualQSOView(appState: appState, isPresented: $isAddManualPresented)
        }
    }
    
    private func qsoRowItem(_ qso: QSO) -> some View {
        HStack(alignment: .center, spacing: 10) {
            // Status Icon with Circle Background
            ZStack {
                Circle()
                    .fill(statusColor(qso.status).opacity(0.12))
                    .frame(width: 32, height: 32)
                Image(systemName: qso.status.iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(statusColor(qso.status))
            }
            
            VStack(alignment: .leading, spacing: 3) {
                // Top Row: Callsign & Band/Mode
                HStack(alignment: .firstTextBaseline) {
                    Text(qso.dxCall)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Text("\(qso.band) • \(qso.mode)")
                        .font(.system(size: 11, weight: .semibold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.primary.opacity(0.08))
                        )
                        .foregroundColor(.secondary)
                }
                
                // Middle Row: Name or UTC Time & Status Text
                HStack(alignment: .center) {
                    if !qso.dxName.isEmpty {
                        Text(qso.dxName)
                            .font(.subheadline)
                            .foregroundColor(.primary.opacity(0.85))
                            .lineLimit(1)
                    } else {
                        Text(qso.formattedUTCTime + " UTC")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text(qso.status.rawValue)
                        .font(.caption2.bold())
                        .foregroundColor(statusColor(qso.status))
                }
                
                // Bottom Row: Timestamp & Failure badge if any
                HStack(alignment: .center) {
                    Text(timestampString(for: qso))
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                    
                    Spacer()
                    
                    if qso.status == .failed, let msg = qso.statusMessage {
                        Text(msg)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 1)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 6)
        .onDoubleClick {
            openCallbook(for: qso.dxCall)
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
    
    private func timestampString(for qso: QSO) -> String {
        let order = appState.settings.dateOrder
        let sep = appState.settings.dateSeparator.symbol
        
        let df = DateFormatter()
        if order == .ddMMyyyy {
            df.dateFormat = "dd'\(sep)'MM'\(sep)'yyyy HH:mm"
        } else {
            df.dateFormat = "yyyy'\(sep)'MM'\(sep)'dd HH:mm"
        }
        
        var timeStr = "Queued: \(df.string(from: qso.timestamp))"
        if let sent = qso.sentAt {
            timeStr += " • Sent: \(df.string(from: sent))"
        }
        return timeStr
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
    
    private func sendSelectedQSOs() {
        let ids = Array(appState.selectedQSOIds)
        appState.selectedQSOIds.removeAll()
        Task {
            await appState.executeBatchSendQSOs(qsoIds: ids)
        }
    }
}

public struct AddManualQSOView: View {
    @ObservedObject var appState: AppState
    @Binding var isPresented: Bool
    
    @State private var dxCall: String = ""
    @State private var bandSelection: String = "20m"
    @State private var customBand: String = ""
    @State private var frequencyMHzText: String = "14.074"
    @State private var modeSelection: String = "FT8"
    @State private var customMode: String = ""
    @State private var rstSent: String = "59"
    @State private var rstRcvd: String = "59"
    @State private var comment: String = ""
    @State private var dxEmail: String = ""
    
    private var effectiveBand: String {
        if bandSelection == "Custom" {
            let trimmed = customBand.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "20m" : trimmed
        }
        return bandSelection
    }
    
    private var effectiveMode: String {
        if modeSelection == "Other" {
            let trimmed = customMode.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "FT8" : trimmed.uppercased()
        }
        return modeSelection
    }
    
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
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    GroupBox(label: Text("Contact Info").font(.headline)) {
                        VStack(alignment: .leading, spacing: 10) {
                            FormRow(label: "Callsign:", labelWidth: 90) {
                                TextField("e.g. DJ6GI", text: $dxCall)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 140)
                            }
                            
                            FormRow(label: "Email:", labelWidth: 90) {
                                TextField("Optional, or looked up via QRZ", text: $dxEmail)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 220)
                            }
                        }
                        .padding(8)
                    }
                    
                    GroupBox(label: Text("QSO Parameters").font(.headline)) {
                        VStack(alignment: .leading, spacing: 10) {
                            FormRow(label: "Band / Freq:", labelWidth: 90) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Picker("", selection: $bandSelection) {
                                            ForEach(RadioUtils.standardBands, id: \.self) {
                                                Text($0).tag($0)
                                            }
                                            Text("Custom...").tag("Custom")
                                        }
                                        .labelsHidden()
                                        .frame(width: 95)
                                        .onChange(of: bandSelection) { _, newBand in
                                            if newBand != "Custom", let defFreq = RadioUtils.defaultFrequencyMHz(for: newBand) {
                                                frequencyMHzText = String(format: "%.3f", defFreq)
                                            }
                                        }
                                        
                                        Text("Freq:")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        TextField("MHz", text: $frequencyMHzText)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 85)
                                            .onChange(of: frequencyMHzText) { _, newFreq in
                                                if let mhz = RadioUtils.parseFrequencyMHz(from: newFreq),
                                                   let detectedBand = RadioUtils.band(forFrequencyMHz: mhz) {
                                                    if bandSelection != detectedBand {
                                                        bandSelection = detectedBand
                                                    }
                                                }
                                            }
                                        
                                        Text("MHz")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    if bandSelection == "Custom" {
                                        HStack(spacing: 6) {
                                            Text("Custom Band:")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            TextField("e.g. 70cm / 3cm / SAT", text: $customBand)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 140)
                                        }
                                    }
                                }
                            }
                            
                            FormRow(label: "Mode:", labelWidth: 90) {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack(spacing: 8) {
                                        Picker("", selection: $modeSelection) {
                                            ForEach(RadioUtils.standardModes, id: \.self) {
                                                Text($0).tag($0)
                                            }
                                            Text("Other...").tag("Other")
                                        }
                                        .labelsHidden()
                                        .frame(width: 110)
                                        
                                        if modeSelection == "Other" {
                                            TextField("Custom Mode (e.g. VARAC)", text: $customMode)
                                                .textFieldStyle(.roundedBorder)
                                                .frame(width: 170)
                                        }
                                    }
                                }
                            }
                            
                            FormRow(label: "RST:", labelWidth: 90) {
                                HStack(spacing: 8) {
                                    TextField("Sent", text: $rstSent)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                    Text("/")
                                        .foregroundColor(.secondary)
                                    TextField("Rcvd", text: $rstRcvd)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                }
                            }
                            
                            FormRow(label: "Comment:", labelWidth: 90) {
                                TextField("Greeting / Comment", text: $comment)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 260)
                            }
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                Button("Cancel") { isPresented = false }
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("Add & Process QSL") {
                    let freqHz = RadioUtils.parseFrequencyMHz(from: frequencyMHzText).map { $0 * 1_000_000.0 }
                    appState.addManualQSO(
                        dxCall: dxCall,
                        band: effectiveBand,
                        mode: effectiveMode,
                        frequencyHz: freqHz,
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
        .frame(width: 480, height: 500)
    }
}

// MARK: - Native Double Click Handler
struct DoubleClickHandler: NSViewRepresentable {
    var onDoubleClick: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.autoresizingMask = [.width, .height]
        let recognizer = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        recognizer.numberOfClicksRequired = 2
        recognizer.delaysPrimaryMouseButtonEvents = false
        recognizer.delegate = context.coordinator
        view.addGestureRecognizer(recognizer)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onDoubleClick = onDoubleClick
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDoubleClick: onDoubleClick)
    }

    class Coordinator: NSObject, NSGestureRecognizerDelegate {
        var onDoubleClick: () -> Void
        
        init(onDoubleClick: @escaping () -> Void) {
            self.onDoubleClick = onDoubleClick
        }
        
        @objc func handleClick(_ sender: NSClickGestureRecognizer) {
            if sender.state == .ended {
                onDoubleClick()
            }
        }
        
        func gestureRecognizer(_ gestureRecognizer: NSGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: NSGestureRecognizer) -> Bool {
            return true
        }
    }
}

extension View {
    func onDoubleClick(perform action: @escaping () -> Void) -> some View {
        self.background(
            DoubleClickHandler(onDoubleClick: action)
        )
    }
}
