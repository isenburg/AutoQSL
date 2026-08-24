import SwiftUI

public struct ElementInspectorView: View {
    @Binding var element: CardElement
    
    private var textColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.textColorHex) },
            set: { element.textColorHex = $0.toHex() }
        )
    }
    
    private var secondaryColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.secondaryColorHex) },
            set: { element.secondaryColorHex = $0.toHex() }
        )
    }
    
    private var shadowColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.shadowColorHex) },
            set: { element.shadowColorHex = $0.toHex() }
        )
    }
    
    private var tableBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.tableBackgroundColorHex).opacity(element.tableBackgroundOpacity) },
            set: { newColor in
                element.tableBackgroundOpacity = newColor.opacityValue
                element.tableBackgroundColorHex = newColor.toHex()
            }
        )
    }
    
    private var tableHeaderBackgroundColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.tableHeaderBackgroundHex).opacity(element.tableHeaderBackgroundOpacity) },
            set: { newColor in
                element.tableHeaderBackgroundOpacity = newColor.opacityValue
                element.tableHeaderBackgroundHex = newColor.toHex()
            }
        )
    }
    
    private var tableBorderColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.tableBorderColorHex) },
            set: { element.tableBorderColorHex = $0.toHex() }
        )
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header & Name
                HStack {
                    Text(element.name)
                        .font(.headline)
                    Spacer()
                    Button(action: { element.isLocked.toggle() }) {
                        Image(systemName: element.isLocked ? "lock.fill" : "lock.open")
                            .foregroundColor(element.isLocked ? .orange : .secondary)
                    }
                    .buttonStyle(.plain)
                    .help(element.isLocked ? "Locked - Position is fixed" : "Unlocked - Can drag on canvas")
                }
                
                Divider()
                
                // Content based on element type
                switch element.type {
                case .callsign:
                    callsignInspector
                case .address:
                    addressInspector
                case .table:
                    tableInspector
                case .locationFooter:
                    locationInspector
                case .sticker:
                    stickerInspector
                case .text:
                    textInspector
                }
                
                Divider()
                
                // Position & Dimensions (Geometry)
                Section("Position & Size (Normalized)") {
                    VStack(spacing: 8) {
                        HStack {
                            Text("X Position: \(Int(element.normalizedX * 100))%")
                                .font(.caption)
                            Slider(value: $element.normalizedX, in: 0...1)
                        }
                        HStack {
                            Text("Y Position: \(Int(element.normalizedY * 100))%")
                                .font(.caption)
                            Slider(value: $element.normalizedY, in: 0...1)
                        }
                        HStack {
                            Text("Width: \(Int(element.normalizedWidth * 100))%")
                                .font(.caption)
                            Slider(value: $element.normalizedWidth, in: 0.05...1.0)
                        }
                        HStack {
                            Text("Height: \(Int(element.normalizedHeight * 100))%")
                                .font(.caption)
                            Slider(value: $element.normalizedHeight, in: 0.05...1.0)
                        }
                        HStack {
                            Text("Layer (Z):")
                                .font(.caption)
                            Stepper("\(element.zIndex)", value: $element.zIndex, in: 0...100)
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    // MARK: - Font Picker Section Helper (Native macOS NSFontPanel)
    @ViewBuilder
    private var fontSelectionGroup: some View {
        Group {
            Text("Typography (Standard macOS Font Picker)")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(element.fontName)
                        .font(.body.bold())
                    Text("\(Int(element.fontSize)) pt" + (element.isBold ? " • Bold" : "") + (element.isItalic ? " • Italic" : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: openMacOSFontPicker) {
                    Label("Choose Font…", systemImage: "textformat")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            HStack {
                Text("Quick Size: \(Int(element.fontSize)) pt")
                    .font(.caption)
                Slider(value: $element.fontSize, in: 8...120, step: 1)
            }
            
            HStack(spacing: 16) {
                Toggle("Bold", isOn: $element.isBold)
                Toggle("Italic", isOn: $element.isItalic)
                Spacer()
            }
        }
    }
    
    // MARK: - Reusable Aligned Color Row
    private func colorRow(title: String, selection: Binding<Color>) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
            Spacer()
            ColorPicker("", selection: selection, supportsOpacity: true)
                .labelsHidden()
        }
    }
    
    // MARK: - Reusable Shadow Controls
    @ViewBuilder
    private var shadowControlSection: some View {
        Group {
            HStack {
                Text("Drop Shadow")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $element.isShadowEnabled)
                    .labelsHidden()
            }
            
            if element.isShadowEnabled {
                colorRow(title: "Shadow Color", selection: shadowColorBinding)
                
                HStack {
                    Text("Blur: \(Int(element.shadowRadius)) pt")
                        .font(.caption)
                    Slider(value: $element.shadowRadius, in: 0...20, step: 1)
                }
                HStack {
                    Text("Offset X / Y:")
                        .font(.caption)
                    Slider(value: $element.shadowX, in: -15...15, step: 1)
                    Slider(value: $element.shadowY, in: -15...15, step: 1)
                }
                HStack {
                    Text("Opacity: \(Int(element.shadowOpacity * 100))%")
                        .font(.caption)
                    Slider(value: $element.shadowOpacity, in: 0.0...1.0)
                }
            }
        }
    }
    
    private func openMacOSFontPicker() {
        FontPanelBridge.shared.present(
            fontName: element.fontName,
            fontSize: element.fontSize,
            isBold: element.isBold,
            isItalic: element.isItalic
        ) { name, size, isBold, isItalic in
            element.fontName = name
            element.fontSize = size
            element.isBold = isBold
            element.isItalic = isItalic
        }
    }
    
    // MARK: - Callsign Inspector
    @ViewBuilder
    private var callsignInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Callsign Typography & Style")
                .font(.subheadline.bold())
            
            TextField("Callsign Override", text: $element.textContent)
                .textFieldStyle(.roundedBorder)
            
            fontSelectionGroup
            
            Picker("Visual Style Effect", selection: $element.effectType) {
                ForEach(TextEffectType.allCases, id: \.self) { effect in
                    Text(effect.rawValue).tag(effect)
                }
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Group {
                Text("Colors (macOS Color Picker)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: "Face / Text Color", selection: textColorBinding)
                colorRow(title: "Secondary / Accent Color", selection: secondaryColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Address Inspector
    @ViewBuilder
    private var addressInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Address Text & Style")
                .font(.subheadline.bold())
            
            Text("Content (Multi-line):")
                .font(.caption)
            TextEditor(text: $element.textContent)
                .font(.caption.monospaced())
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            
            fontSelectionGroup
            
            Picker("Alignment", selection: $element.textAlignment) {
                Text("Left").tag("left")
                Text("Center").tag("center")
                Text("Right").tag("right")
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            Group {
                Text("Colors (macOS Color Picker)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: "Text Color", selection: textColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Table Inspector
    @ViewBuilder
    private var tableInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("QSO Confirmation Table")
                .font(.subheadline.bold())
            
            Group {
                Text("Table Columns & Headers")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                // 1. QSO With
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("QSO With Column", isOn: $element.tableShowCallsign)
                    if element.tableShowCallsign {
                        TextField("Header Label", text: $element.tableCallsignHeader)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // 2. Date
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Date Column", isOn: $element.tableShowDate)
                    if element.tableShowDate {
                        TextField("Header Label", text: $element.tableDateHeader)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // 3. UTC Time
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("UTC Time Column", isOn: $element.tableShowTime)
                    if element.tableShowTime {
                        TextField("Header Label", text: $element.tableTimeHeader)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // 4. Frequency / Band
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Frequency / Band Column", isOn: $element.tableShowFreq)
                    if element.tableShowFreq {
                        TextField("Header Label", text: $element.tableFreqHeader)
                            .textFieldStyle(.roundedBorder)
                        Picker("Data Format", selection: $element.tableFreqDisplayMode) {
                            ForEach(TableFreqDisplayMode.allCases) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                    }
                }
                
                // 5. RST / Report
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("RST / Report Column", isOn: $element.tableShowRST)
                    if element.tableShowRST {
                        TextField("Header Label", text: $element.tableRSTHeader)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // 6. Mode
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Mode Column", isOn: $element.tableShowMode)
                    if element.tableShowMode {
                        TextField("Header Label", text: $element.tableModeHeader)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                // 7. Remarks / Greeting Row
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Remarks / Greeting Row", isOn: $element.tableShowCommentRow)
                    if element.tableShowCommentRow {
                        TextField("Greeting / Remarks Text", text: $element.tableComment)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            Divider()
            
            fontSelectionGroup
            
            Divider()
            
            Group {
                Text("Colors (macOS Color Picker)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: "Font / Text Color", selection: textColorBinding)
                colorRow(title: "Table Background Color", selection: tableBackgroundColorBinding)
                colorRow(title: "Header Background Color", selection: tableHeaderBackgroundColorBinding)
                colorRow(title: "Grid Border Color", selection: tableBorderColorBinding)
            }
            
            Divider()
            
            Group {
                Text("Grid Layout & Opacity")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                HStack {
                    Text("Border Width: \(String(format: "%.1f", element.tableBorderWidth)) pt")
                    Slider(value: $element.tableBorderWidth, in: 0.5...5.0, step: 0.5)
                }
                
                HStack {
                    Text("Background Opacity: \(Int(element.tableBackgroundOpacity * 100))%")
                    Slider(value: $element.tableBackgroundOpacity, in: 0.0...1.0)
                }
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Location Footer Inspector
    @ViewBuilder
    private var locationInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Location Line")
                .font(.subheadline.bold())
            
            TextField("Template", text: $element.textContent)
                .textFieldStyle(.roundedBorder)
            
            Text("Placeholders: {MY_ITU}, {MY_CQ}, {MY_GRID}, {MY_COUNTY}")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            fontSelectionGroup
            
            Divider()
            
            Group {
                Text("Colors (macOS Color Picker)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: "Text Color", selection: textColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Sticker Inspector
    @ViewBuilder
    private var stickerInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Sticker / Badge")
                .font(.subheadline.bold())
            
            Picker("Badge Type", selection: $element.stickerType) {
                ForEach(StickerType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            
            HStack {
                Text("Rotation: \(Int(element.rotationDegrees))°")
                Slider(value: $element.rotationDegrees, in: -180...180, step: 5)
            }
        }
    }
    
    // MARK: - Text Inspector
    @ViewBuilder
    private var textInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Custom Text Element")
                .font(.subheadline.bold())
            
            TextField("Text", text: $element.textContent)
                .textFieldStyle(.roundedBorder)
            
            fontSelectionGroup
            
            Divider()
            
            Group {
                Text("Colors (macOS Color Picker)")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: "Text Color", selection: textColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
}
