import SwiftUI

public struct EditQSOModalView: View {
    @ObservedObject var appState: AppState
    let originalQSO: QSO
    @Binding var isPresented: Bool
    
    // Editable State Variables
    @State private var dxCall: String = ""
    @State private var band: String = "20m"
    @State private var mode: String = "FT8"
    @State private var frequencyMHzText: String = ""
    @State private var qsoDate: Date = Date()
    @State private var utcHour: Int = 12
    @State private var utcMinute: Int = 0
    @State private var rstSent: String = "59"
    @State private var rstRcvd: String = "59"
    @State private var txPowerWattsText: String = ""
    @State private var comment: String = ""
    
    // Contact Info
    @State private var dxName: String = ""
    @State private var dxEmail: String = ""
    @State private var dxGrid: String = ""
    @State private var dxCountry: String = ""
    @State private var dxAddress: String = ""
    
    // Card Template Option
    @State private var selectedTemplateId: UUID?
    @State private var isCustomCardDesignerPresented: Bool = false
    
    private let availableBands = ["160m", "80m", "60m", "40m", "30m", "20m", "17m", "15m", "12m", "10m", "6m", "4m", "2m", "70cm", "23cm"]
    private let availableModes = ["FT8", "FT4", "CW", "SSB", "RTTY", "PSK31", "FM", "AM", "MSK144", "JS8", "Olivia", "SSTV"]
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Image(systemName: "pencil.and.outline")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.accentColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Edit QSO & QSL Card Details")
                        .font(.headline)
                    Text("Modify contact information, QSO parameters, and card layout for \(originalQSO.dxCall)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Cancel") {
                    isPresented = false
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Form Body
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Section 1: Call & Recipient Info
                    GroupBox(label: Text("Station & Recipient Profile").font(.headline)) {
                        VStack(alignment: .leading, spacing: 10) {
                            FormRow(label: "Callsign:") {
                                TextField("DX Callsign", text: $dxCall)
                                    .font(.body.bold())
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 140)
                                    .onChange(of: dxCall) { _, newCall in
                                        let matchedCountry = PrefixMatcher.shared.country(for: newCall)
                                        if matchedCountry != "OTHER" && !matchedCountry.isEmpty {
                                            dxCountry = matchedCountry
                                        }
                                    }
                            }
                            
                            FormRow(label: "Name:") {
                                TextField("DX Name / Operator", text: $dxName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 240)
                            }
                            
                            FormRow(label: "Email:") {
                                TextField("Recipient Email Address", text: $dxEmail)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 260)
                            }
                            
                            FormRow(label: "Grid:") {
                                TextField("Grid Square (e.g. JO31)", text: $dxGrid)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 140)
                            }
                            
                            FormRow(label: "Country:") {
                                TextField("Country / DXCC", text: $dxCountry)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                            }
                            
                            FormRow(label: "Address:") {
                                TextField("Full Postal Address", text: $dxAddress)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 320)
                            }
                        }
                        .padding(8)
                    }
                    
                    // Section 2: QSO Details
                    GroupBox(label: Text("QSO Parameters (Printed on Card)").font(.headline)) {
                        VStack(alignment: .leading, spacing: 10) {
                            FormRow(label: "Band / Mode:") {
                                HStack(spacing: 12) {
                                    Picker("", selection: $band) {
                                        ForEach(availableBands, id: \.self) {
                                            Text($0).tag($0)
                                        }
                                    }
                                    .frame(width: 90)
                                    
                                    Picker("", selection: $mode) {
                                        ForEach(availableModes, id: \.self) {
                                            Text($0).tag($0)
                                        }
                                    }
                                    .frame(width: 90)
                                    
                                    Text("Freq:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("MHz", text: $frequencyMHzText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 90)
                                }
                            }
                            
                            FormRow(label: "Date & Time:") {
                                HStack(spacing: 12) {
                                    DatePicker("", selection: $qsoDate, displayedComponents: [.date])
                                        .datePickerStyle(.compact)
                                        .labelsHidden()
                                        .frame(width: 120)
                                    
                                    Text("UTC:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("HH", selection: $utcHour) {
                                        ForEach(0..<24, id: \.self) { h in
                                            Text(String(format: "%02d", h)).tag(h)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 60)
                                    
                                    Text(":")
                                    
                                    Picker("MM", selection: $utcMinute) {
                                        ForEach(0..<60, id: \.self) { m in
                                            Text(String(format: "%02d", m)).tag(m)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 60)
                                }
                            }
                            
                            FormRow(label: "RST / Power:") {
                                HStack(spacing: 12) {
                                    TextField("Sent", text: $rstSent)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                    
                                    Text("/")
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Rcvd", text: $rstRcvd)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 60)
                                    
                                    Text("Power:")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Watts", text: $txPowerWattsText)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 70)
                                    
                                    Text("W")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            FormRow(label: "Comment:") {
                                VStack(alignment: .leading, spacing: 6) {
                                    TextField("Comment printed on QSL Card table", text: $comment)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 380)
                                    
                                    HStack(spacing: 8) {
                                        Button("73 tnx QSO") { comment = "73, Thanks for the QSO." }.buttonStyle(.link).font(.caption2)
                                        Button("Nice contact!") { comment = "Thanks for the nice contact! Best 73." }.buttonStyle(.link).font(.caption2)
                                        Button("HPE CUAGN") { comment = "73, Hope to meet you again down the log." }.buttonStyle(.link).font(.caption2)
                                    }
                                }
                            }
                        }
                        .padding(8)
                    }
                    
                    // Section 3: Card Template & Customization
                    GroupBox(label: Text("Card Template & Customization").font(.headline)) {
                        VStack(alignment: .leading, spacing: 10) {
                            FormRow(label: "Template:") {
                                HStack(spacing: 12) {
                                    Picker("", selection: $selectedTemplateId) {
                                        Text("Global Active (\(appState.activeTemplate.name))").tag(nil as UUID?)
                                        ForEach(appState.templates) { t in
                                            Text(t.name).tag(t.id as UUID?)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(width: 200)
                                    
                                    Button(action: {
                                        isCustomCardDesignerPresented = true
                                    }) {
                                        Label("Customize Card...", systemImage: "paintbrush")
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            
                            if originalQSO.customTemplate != nil {
                                HStack {
                                    Text("")
                                        .frame(width: 110)
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Custom layout applied to this QSO")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Button("Reset") {
                                        appState.setCustomTemplate(for: originalQSO.id, template: nil)
                                    }
                                    .buttonStyle(.link)
                                    .font(.caption)
                                }
                            }
                        }
                        .padding(8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Footer Action Bar
            HStack {
                Button("Discard Changes") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button(action: saveChanges) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save & Update QSL Card")
                    }
                    .padding(.horizontal, 6)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(dxCall.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 620, height: 600)
        .onAppear {
            loadInitialData()
        }
        .sheet(isPresented: $isCustomCardDesignerPresented) {
            QSLCardEditorModalView(
                appState: appState,
                qso: currentEditedQSO,
                isPresented: $isCustomCardDesignerPresented
            )
        }
    }
    
    private var currentEditedQSO: QSO {
        var q = originalQSO
        q.dxCall = dxCall.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        q.dxName = dxName
        q.dxEmail = dxEmail
        q.dxGrid = dxGrid
        q.dxCountry = dxCountry
        q.dxAddress = dxAddress
        q.band = band
        q.mode = mode
        if let fMhz = Double(frequencyMHzText.replacingOccurrences(of: ",", with: ".")) {
            q.frequencyHz = fMhz * 1_000_000.0
        }
        q.qsoDate = constructUTCDate()
        q.rstSent = rstSent
        q.rstRcvd = rstRcvd
        if let pwr = Double(txPowerWattsText) {
            q.txPowerWatts = pwr
        }
        q.comment = comment
        q.templateId = selectedTemplateId
        return q
    }
    
    private func loadInitialData() {
        dxCall = originalQSO.dxCall
        dxName = originalQSO.dxName
        dxEmail = originalQSO.dxEmail
        dxGrid = originalQSO.dxGrid
        dxCountry = originalQSO.dxCountry
        dxAddress = originalQSO.dxAddress
        band = originalQSO.band
        mode = originalQSO.mode
        
        if let freq = originalQSO.frequencyHz {
            frequencyMHzText = String(format: "%.3f", freq / 1_000_000.0)
        }
        
        qsoDate = originalQSO.qsoDate
        
        let cal = Calendar(identifier: .gregorian)
        var utcCal = cal
        utcCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        utcHour = utcCal.component(.hour, from: originalQSO.qsoDate)
        utcMinute = utcCal.component(.minute, from: originalQSO.qsoDate)
        
        rstSent = originalQSO.rstSent
        rstRcvd = originalQSO.rstRcvd
        
        if let pwr = originalQSO.txPowerWatts {
            txPowerWattsText = String(format: "%.0f", pwr)
        }
        
        comment = originalQSO.comment
        selectedTemplateId = originalQSO.templateId
    }
    
    private func constructUTCDate() -> Date {
        var utcCal = Calendar(identifier: .gregorian)
        utcCal.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        
        var comp = utcCal.dateComponents([.year, .month, .day], from: qsoDate)
        comp.hour = utcHour
        comp.minute = utcMinute
        comp.second = 0
        return utcCal.date(from: comp) ?? qsoDate
    }
    
    private func saveChanges() {
        let updated = currentEditedQSO
        appState.updateQSO(updated, reRenderCard: true)
        isPresented = false
    }
}
