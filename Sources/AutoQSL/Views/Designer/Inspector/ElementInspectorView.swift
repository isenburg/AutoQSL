import SwiftUI
import UniformTypeIdentifiers

public struct ElementInspectorView: View {
    @Binding var element: CardElement
    public var lang: AppLanguage = .english
    
    @State private var draggingColumn: TableColumnType? = nil
    
    private var tableColumnOrderBinding: Binding<[TableColumnType]> {
        Binding(
            get: { element.effectiveTableColumnOrder },
            set: { element.tableColumnOrder = $0 }
        )
    }
    
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
    
    private var tableHeaderTextColorBinding: Binding<Color> {
        Binding(
            get: { Color(hex: element.effectiveHeaderTextColorHex) },
            set: { element.tableHeaderTextColorHex = $0.toHex() }
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
                        HStack(spacing: 4) {
                            Image(systemName: element.isLocked ? "lock.fill" : "lock.open")
                            Text(element.isLocked ? (lang == .german ? "Gesperrt" : "Locked") : (lang == .german ? "Frei beweglich" : "Unlocked"))
                                .font(.caption2)
                        }
                        .foregroundColor(element.isLocked ? .orange : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(element.isLocked ? Color.orange.opacity(0.12) : Color.secondary.opacity(0.1))
                        .cornerRadius(5)
                    }
                    .buttonStyle(.plain)
                    .help(element.isLocked ? (lang == .german ? "Element ist gesperrt – Klicke zum Entsperren" : "Element is locked – Click to unlock") : (lang == .german ? "Element ist frei beweglich" : "Element can be moved and resized"))
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
                Section(L10n.tr(lang, "Position & Size", "Position & Größe")) {
                    VStack(spacing: 8) {
                        HStack {
                            Text(L10n.tr(lang, "X Position: \(Int(element.normalizedX * 100))%", "X-Position: \(Int(element.normalizedX * 100))%"))
                                .font(.caption)
                            Slider(value: $element.normalizedX, in: 0...1)
                        }
                        HStack {
                            Text(L10n.tr(lang, "Y Position: \(Int(element.normalizedY * 100))%", "Y-Position: \(Int(element.normalizedY * 100))%"))
                                .font(.caption)
                            Slider(value: $element.normalizedY, in: 0...1)
                        }
                        HStack {
                            Text(L10n.tr(lang, "Width: \(Int(element.normalizedWidth * 100))%", "Breite: \(Int(element.normalizedWidth * 100))%"))
                                .font(.caption)
                            Slider(value: $element.normalizedWidth, in: 0.05...1.0)
                        }
                        HStack {
                            Text(L10n.tr(lang, "Height: \(Int(element.normalizedHeight * 100))%", "Höhe: \(Int(element.normalizedHeight * 100))%"))
                                .font(.caption)
                            Slider(value: $element.normalizedHeight, in: 0.05...1.0)
                        }
                        HStack {
                            Text(L10n.tr(lang, "Layer (Z):", "Ebene (Z):"))
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
            Text(L10n.tr(lang, "Typography", "Typografie"))
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
                    Label(L10n.tr(lang, "Choose Font…", "Schrift wählen…"), systemImage: "textformat")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            HStack {
                Text(L10n.tr(lang, "Quick Size: \(Int(element.fontSize)) pt", "Schriftgröße: \(Int(element.fontSize)) pt"))
                    .font(.caption)
                Slider(value: $element.fontSize, in: 8...120, step: 1)
            }
            
            HStack(spacing: 16) {
                Toggle(L10n.tr(lang, "Bold", "Fett"), isOn: $element.isBold)
                Toggle(L10n.tr(lang, "Italic", "Kursiv"), isOn: $element.isItalic)
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
                Text(L10n.tr(lang, "Drop Shadow", "Schattenwurf"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                Spacer()
                Toggle("", isOn: $element.isShadowEnabled)
                    .labelsHidden()
            }
            
            if element.isShadowEnabled {
                colorRow(title: L10n.tr(lang, "Shadow Color", "Schattenfarbe"), selection: shadowColorBinding)
                
                HStack {
                    Text(L10n.tr(lang, "Blur: \(Int(element.shadowRadius)) pt", "Weichzeichnung: \(Int(element.shadowRadius)) pt"))
                        .font(.caption)
                    Slider(value: $element.shadowRadius, in: 0...20, step: 1)
                }
                HStack {
                    Text(L10n.tr(lang, "Offset X / Y:", "Versatz X / Y:"))
                        .font(.caption)
                    Slider(value: $element.shadowX, in: -15...15, step: 1)
                    Slider(value: $element.shadowY, in: -15...15, step: 1)
                }
                HStack {
                    Text(L10n.tr(lang, "Opacity: \(Int(element.shadowOpacity * 100))%", "Deckkraft: \(Int(element.shadowOpacity * 100))%"))
                        .font(.caption)
                    Slider(value: $element.shadowOpacity, in: 0.0...1.0)
                }
            }
        }
    }
    
    private func openMacOSHeaderFontPicker() {
        FontPanelBridge.shared.present(
            fontName: element.effectiveHeaderFontName,
            fontSize: element.effectiveHeaderFontSize,
            isBold: element.effectiveHeaderIsBold,
            isItalic: element.effectiveHeaderIsItalic
        ) { name, size, isBold, isItalic in
            element.tableHeaderFontName = name
            element.tableHeaderFontSize = size
            element.tableHeaderIsBold = isBold
            element.tableHeaderIsItalic = isItalic
        }
    }
    
    @ViewBuilder
    private var headerFontSelectionGroup: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.tr(lang, "Header Typography", "Header-Typografie"))
                .font(.caption.bold())
                .foregroundColor(.secondary)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(element.effectiveHeaderFontName)
                        .font(.body.bold())
                    Text("\(Int(element.effectiveHeaderFontSize)) pt" + (element.effectiveHeaderIsBold ? " • Bold" : "") + (element.effectiveHeaderIsItalic ? " • Italic" : ""))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: openMacOSHeaderFontPicker) {
                    Label(L10n.tr(lang, "Choose Header Font…", "Header-Schrift wählen…"), systemImage: "textformat")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            HStack {
                Text(L10n.tr(lang, "Header Size: \(Int(element.effectiveHeaderFontSize)) pt", "Header-Größe: \(Int(element.effectiveHeaderFontSize)) pt"))
                    .font(.caption)
                Slider(value: Binding(
                    get: { element.effectiveHeaderFontSize },
                    set: { element.effectiveHeaderFontSize = $0 }
                ), in: 8...60, step: 1)
            }
            
            HStack(spacing: 16) {
                Toggle(L10n.tr(lang, "Bold", "Fett"), isOn: Binding(
                    get: { element.effectiveHeaderIsBold },
                    set: { element.effectiveHeaderIsBold = $0 }
                ))
                Toggle(L10n.tr(lang, "Italic", "Kursiv"), isOn: Binding(
                    get: { element.effectiveHeaderIsItalic },
                    set: { element.effectiveHeaderIsItalic = $0 }
                ))
                Spacer()
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
            Text(L10n.tr(lang, "Callsign Typography & Style", "Rufzeichen-Typografie & Stil"))
                .font(.subheadline.bold())
            
            TextField(L10n.tr(lang, "Callsign Override", "Rufzeichen überschreiben"), text: $element.textContent)
                .textFieldStyle(.roundedBorder)
            
            fontSelectionGroup
            
            Picker(L10n.tr(lang, "Visual Style Effect", "Visueller Stileffekt"), selection: $element.effectType) {
                ForEach(TextEffectType.allCases, id: \.self) { effect in
                    Text(effect.rawValue).tag(effect)
                }
            }
            .pickerStyle(.menu)
            
            Divider()
            
            Group {
                Text(L10n.tr(lang, "Colors (macOS Color Picker)", "Farben (macOS Farbwähler)"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: L10n.tr(lang, "Face / Text Color", "Vordergrund- / Textfarbe"), selection: textColorBinding)
                colorRow(title: L10n.tr(lang, "Secondary / Accent Color", "Akzent- / 3D-Farbe"), selection: secondaryColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Address Inspector
    @ViewBuilder
    private var addressInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr(lang, "Address Text & Style", "Adresstext & Stil"))
                .font(.subheadline.bold())
            
            Text(L10n.tr(lang, "Content (Multi-line):", "Inhalt (mehrzeilig):"))
                .font(.caption)
            TextEditor(text: $element.textContent)
                .font(.caption.monospaced())
                .frame(height: 80)
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.secondary.opacity(0.3)))
            
            fontSelectionGroup
            
            Picker(L10n.tr(lang, "Alignment", "Ausrichtung"), selection: $element.textAlignment) {
                Text(L10n.tr(lang, "Left", "Links")).tag("left")
                Text(L10n.tr(lang, "Center", "Zentriert")).tag("center")
                Text(L10n.tr(lang, "Right", "Rechts")).tag("right")
            }
            .pickerStyle(.segmented)
            
            Divider()
            
            Group {
                Text(L10n.tr(lang, "Colors (macOS Color Picker)", "Farben (macOS Farbwähler)"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: L10n.tr(lang, "Text Color", "Textfarbe"), selection: textColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Table Inspector
    @ViewBuilder
    private var tableInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr(lang, "QSO Confirmation Table", "QSO-Bestätigungstabelle"))
                .font(.subheadline.bold())
            
            Group {
                HStack {
                    Text(L10n.tr(lang, "Table Columns & Order", "Tabellenspalten & Reihenfolge"))
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(L10n.tr(lang, "Reorder: ▲ / ▼", "Reihenfolge: ▲ / ▼"))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                
                let order = element.effectiveTableColumnOrder
                ForEach(0..<order.count, id: \.self) { idx in
                    let colType = order[idx]
                    columnRow(for: colType, index: idx, total: order.count)
                        .opacity(draggingColumn == colType ? 0.35 : 1.0)
                        .onDrag {
                            self.draggingColumn = colType
                            return NSItemProvider(object: colType.rawValue as NSString)
                        }
                        .onDrop(of: [.plainText, .text], delegate: TableColumnDropDelegate(targetColumn: colType, currentOrder: tableColumnOrderBinding, draggingColumn: $draggingColumn))
                }
                
                // Remarks / Greeting Row
                VStack(alignment: .leading, spacing: 4) {
                    Toggle(L10n.tr(lang, "Remarks / Greeting Row", "Gruß- / Bemerkungszeile"), isOn: $element.tableShowCommentRow)
                    if element.tableShowCommentRow {
                        TextField(L10n.tr(lang, "Greeting / Remarks Text", "Gruß- / Bemerkungstext"), text: $element.tableComment)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.06))
                .cornerRadius(8)
            }
            
            Divider()
            
            headerFontSelectionGroup
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.tr(lang, "Table Data Typography", "Tabellendaten-Typografie"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                fontSelectionGroup
            }
            
            Divider()
            
            Group {
                Text(L10n.tr(lang, "Colors (macOS Color Picker)", "Farben (macOS Farbwähler)"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: L10n.tr(lang, "Header Text Color", "Kopfzeilen-Textfarbe"), selection: tableHeaderTextColorBinding)
                colorRow(title: L10n.tr(lang, "Data Text Color", "Datenzellen-Textfarbe"), selection: textColorBinding)
                colorRow(title: L10n.tr(lang, "Header Background Color", "Kopfzeilen-Hintergrundfarbe"), selection: tableHeaderBackgroundColorBinding)
                colorRow(title: L10n.tr(lang, "Table Background Color", "Tabellen-Hintergrundfarbe"), selection: tableBackgroundColorBinding)
                colorRow(title: L10n.tr(lang, "Grid Border Color", "Rahmenfarbe"), selection: tableBorderColorBinding)
            }
            
            Divider()
            
            Group {
                Text(L10n.tr(lang, "Grid Layout & Opacity", "Gitter-Layout & Deckkraft"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                HStack {
                    let widthStr = String(format: "%.1f", element.tableBorderWidth)
Text(L10n.tr(lang, "Border Width: \(widthStr) pt", "Rahmenbreite: \(widthStr) pt"))
                    Slider(value: $element.tableBorderWidth, in: 0.5...5.0, step: 0.5)
                }
                
                HStack {
                    Text(L10n.tr(lang, "Background Opacity: \(Int(element.tableBackgroundOpacity * 100))%", "Hintergrund-Deckkraft: \(Int(element.tableBackgroundOpacity * 100))%"))
                    Slider(value: $element.tableBackgroundOpacity, in: 0.0...1.0)
                }
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    @ViewBuilder
    private func columnRow(for colType: TableColumnType, index: Int, total: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                switch colType {
                case .call:
                    Toggle(L10n.tr(lang, "QSO With Column", "Spalte: QSO With"), isOn: $element.tableShowCallsign)
                case .date:
                    Toggle(L10n.tr(lang, "Date Column", "Spalte: Date"), isOn: $element.tableShowDate)
                case .time:
                    Toggle(L10n.tr(lang, "UTC Time Column", "Spalte: UTC Time"), isOn: $element.tableShowTime)
                case .freq:
                    Toggle(L10n.tr(lang, "Frequency / Band Column", "Spalte: Frequency / Band"), isOn: $element.tableShowFreq)
                case .rst:
                    Toggle(L10n.tr(lang, "RST / Report Column", "Spalte: RST / Report"), isOn: $element.tableShowRST)
                case .mode:
                    Toggle(L10n.tr(lang, "Mode Column", "Spalte: Mode"), isOn: $element.tableShowMode)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                        .help(L10n.tr(lang, "Drag to reorder", "Mit der Maus ziehen zum Sortieren"))
                        .padding(.trailing, 2)
                    
                    Button(action: {
                        var order = element.effectiveTableColumnOrder
                        if index > 0 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                order.swapAt(index, index - 1)
                                element.tableColumnOrder = order
                            }
                        }
                    }) {
                        Image(systemName: "chevron.up")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == 0)
                    .foregroundColor(index == 0 ? .secondary.opacity(0.3) : .primary)
                    .help(L10n.tr(lang, "Move Column Left / Up", "Spalte nach links / oben verschieben"))
                    
                    Button(action: {
                        var order = element.effectiveTableColumnOrder
                        if index < total - 1 {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                order.swapAt(index, index + 1)
                                element.tableColumnOrder = order
                            }
                        }
                    }) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .disabled(index == total - 1)
                    .foregroundColor(index == total - 1 ? .secondary.opacity(0.3) : .primary)
                    .help(L10n.tr(lang, "Move Column Right / Down", "Spalte nach rechts / unten verschieben"))
                }
            }
            
            switch colType {
            case .call:
                if element.tableShowCallsign {
                    TextField(L10n.tr(lang, "Header Label", "Spaltentitel"), text: $element.tableCallsignHeader)
                        .textFieldStyle(.roundedBorder)
                }
            case .date:
                if element.tableShowDate {
                    TextField(L10n.tr(lang, "Header Label", "Spaltentitel"), text: $element.tableDateHeader)
                        .textFieldStyle(.roundedBorder)
                }
            case .time:
                if element.tableShowTime {
                    TextField(L10n.tr(lang, "Header Label", "Spaltentitel"), text: $element.tableTimeHeader)
                        .textFieldStyle(.roundedBorder)
                }
            case .freq:
                if element.tableShowFreq {
                    TextField(L10n.tr(lang, "Header Label", "Spaltentitel"), text: $element.tableFreqHeader)
                        .textFieldStyle(.roundedBorder)
                    Picker(L10n.tr(lang, "Data Format", "Datenformat"), selection: $element.tableFreqDisplayMode) {
                        ForEach(TableFreqDisplayMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                }
            case .rst:
                if element.tableShowRST {
                    TextField(L10n.tr(lang, "Header Label", "Spaltentitel"), text: $element.tableRSTHeader)
                        .textFieldStyle(.roundedBorder)
                }
            case .mode:
                if element.tableShowMode {
                    TextField(L10n.tr(lang, "Header Label", "Spaltentitel"), text: $element.tableModeHeader)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(8)
        .background(Color.secondary.opacity(0.06))
        .cornerRadius(8)
    }
    
    // MARK: - Location Footer Inspector
    @ViewBuilder
    private var locationInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr(lang, "Location Line", "Standortzeile"))
                .font(.subheadline.bold())
            
            TextField(L10n.tr(lang, "Template", "Vorlage"), text: $element.textContent)
                .textFieldStyle(.roundedBorder)
            
            Text(L10n.tr(lang, "Placeholders: {MY_ITU}, {MY_CQ}, {MY_GRID}, {MY_COUNTY}", "Platzhalter: {MY_ITU}, {MY_CQ}, {MY_GRID}, {MY_COUNTY}"))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            fontSelectionGroup
            
            Divider()
            
            Group {
                Text(L10n.tr(lang, "Colors (macOS Color Picker)", "Farben (macOS Farbwähler)"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: L10n.tr(lang, "Text Color", "Textfarbe"), selection: textColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
    
    // MARK: - Sticker Inspector
    @ViewBuilder
    private var stickerInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr(lang, "Sticker / Badge", "Sticker / Abzeichen"))
                .font(.subheadline.bold())
            
            Picker(L10n.tr(lang, "Badge Type", "Abzeichentyp"), selection: $element.stickerType) {
                ForEach(StickerType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            
            HStack {
                Text(L10n.tr(lang, "Rotation: \(Int(element.rotationDegrees))°", "Drehung: \(Int(element.rotationDegrees))°"))
                Slider(value: $element.rotationDegrees, in: -180...180, step: 5)
            }
        }
    }
    
    // MARK: - Text Inspector
    @ViewBuilder
    private var textInspector: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.tr(lang, "Custom Text Element", "Freies Textelement"))
                .font(.subheadline.bold())
            
            TextField(L10n.tr(lang, "Text", "Text"), text: $element.textContent)
                .textFieldStyle(.roundedBorder)
            
            fontSelectionGroup
            
            Divider()
            
            Group {
                Text(L10n.tr(lang, "Colors (macOS Color Picker)", "Farben (macOS Farbwähler)"))
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                
                colorRow(title: L10n.tr(lang, "Text Color", "Textfarbe"), selection: textColorBinding)
            }
            
            Divider()
            
            shadowControlSection
        }
    }
}

// MARK: - Table Column Drag & Drop Reordering Delegate
struct TableColumnDropDelegate: DropDelegate {
    let targetColumn: TableColumnType
    let currentOrder: Binding<[TableColumnType]>
    @Binding var draggingColumn: TableColumnType?
    
    func dropEntered(info: DropInfo) {
        guard let dragging = draggingColumn, dragging != targetColumn,
              let fromIndex = currentOrder.wrappedValue.firstIndex(of: dragging),
              let toIndex = currentOrder.wrappedValue.firstIndex(of: targetColumn) else { return }
        
        if currentOrder.wrappedValue[toIndex] != dragging {
            withAnimation(.easeInOut(duration: 0.2)) {
                var order = currentOrder.wrappedValue
                order.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
                currentOrder.wrappedValue = order
            }
        }
    }
    
    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
    
    func performDrop(info: DropInfo) -> Bool {
        draggingColumn = nil
        return true
    }
}
