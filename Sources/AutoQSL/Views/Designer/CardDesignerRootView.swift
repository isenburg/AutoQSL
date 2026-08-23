import SwiftUI
import AppKit

public struct CardDesignerRootView: View {
    @ObservedObject var appState: AppState
    
    @State private var selectedElementId: UUID? = nil
    @State private var isStickerPickerPresented: Bool = false
    @State private var zoomScale: Double = 0.85
    @State private var sampleQSO: QSO = {
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 8
        dateComponents.day = 20
        dateComponents.hour = 20
        dateComponents.minute = 11
        dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
        let sampleDate = Calendar(identifier: .gregorian).date(from: dateComponents) ?? Date()
        
        return QSO(
            dxCall: "DJ6GI",
            band: "20m",
            mode: "FT4",
            frequencyHz: 14074000,
            qsoDate: sampleDate,
            rstSent: "-13",
            rstRcvd: "-10",
            comment: "",
            dxName: "Gerd Ihde",
            dxGrid: "JN58td",
            dxCountry: "Germany",
            dxEmail: "dj6gi@example.com",
            qrzFound: true
        )
    }()
    
    public var body: some View {
        HSplitView {
            // Left: Layers & Add Element Sidebar
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Layers")
                        .font(.headline)
                    Spacer()
                    
                    Menu {
                        Button("Callsign") { addElement(type: .callsign) }
                        Button("Address Block") { addElement(type: .address) }
                        Button("QSO Table") { addElement(type: .table) }
                        Button("Location Line") { addElement(type: .locationFooter) }
                        Button("Badge / Sticker...") { isStickerPickerPresented = true }
                        Button("Custom Text") { addElement(type: .text) }
                    } label: {
                        Image(systemName: "plus")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 28)
                }
                .padding(10)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Elements List
                List(selection: $selectedElementId) {
                    ForEach(appState.activeTemplate.elements) { el in
                        HStack {
                            Image(systemName: iconForElement(el.type))
                                .foregroundColor(.secondary)
                                .frame(width: 16)
                            Text(el.name)
                                .font(.callout)
                            Spacer()
                            if el.isLocked {
                                Image(systemName: "lock.fill")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Button(action: {
                                toggleVisibility(el.id)
                            }) {
                                Image(systemName: el.isVisible ? "eye" : "eye.slash")
                                    .font(.caption)
                                    .foregroundColor(el.isVisible ? .primary : .secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .tag(el.id)
                        .contextMenu {
                            Button("Duplicate") { duplicateElement(el.id) }
                            Button("Delete", role: .destructive) { deleteElement(el.id) }
                        }
                    }
                }
                .listStyle(.inset)
                
                Divider()
                
                // Add Quick Badge Button
                Button(action: { isStickerPickerPresented = true }) {
                    Label("Add Badge / Sticker", systemImage: "shield.lefthalf.filled")
                        .frame(maxWidth: .infinity)
                }
                .padding(8)
            }
            .frame(minWidth: 200, maxWidth: 260)
            
            // Center: Interactive Canvas
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    // Template Selector
                    Picker("Template", selection: $appState.selectedTemplateId) {
                        ForEach(appState.templates) { t in
                            Text(t.name).tag(t.id)
                        }
                    }
                    .frame(width: 220)
                    
                    Button(action: createNewTemplate) {
                        Image(systemName: "plus")
                    }
                    .help("Create new template")
                    
                    Spacer()
                    
                    // Zoom Controls
                    HStack(spacing: 6) {
                        Button(action: { zoomScale = max(zoomScale - 0.1, 0.4) }) {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        Text("\(Int(zoomScale * 100))%")
                            .font(.caption.monospaced())
                            .frame(width: 44)
                        Button(action: { zoomScale = min(zoomScale + 0.1, 1.5) }) {
                            Image(systemName: "plus.magnifyingglass")
                        }
                    }
                    
                    Divider().frame(height: 16)
                    
                    Button(action: exportCardImage) {
                        Label("Export Image", systemImage: "square.and.arrow.up")
                    }
                }
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Canvas Area with Zoom & Centering
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        // Desktop workspace background
                        Color(NSColor.underPageBackgroundColor)
                        
                        // Card Canvas
                        let baseW = appState.activeTemplate.aspectRatio.widthPoints
                        let baseH = appState.activeTemplate.aspectRatio.heightPoints
                        
                        CardCanvasView(
                            template: appState.activeTemplate,
                            settings: appState.settings,
                            qso: sampleQSO,
                            isInteractive: true,
                            selectedElementId: $selectedElementId,
                            onElementMoved: { id, newNormX, newNormY in
                                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                                    appState.activeTemplate.elements[idx].normalizedX = newNormX
                                    appState.activeTemplate.elements[idx].normalizedY = newNormY
                                }
                            }
                        )
                        .frame(width: baseW, height: baseH)
                        .scaleEffect(zoomScale)
                        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                        .padding(40)
                    }
                    .frame(minWidth: 900, minHeight: 650)
                }
            }
            .frame(minWidth: 500)
            
            // Right: Inspector Panel
            VStack(spacing: 0) {
                if let selectedId = selectedElementId,
                   let index = appState.activeTemplate.elements.firstIndex(where: { $0.id == selectedId }) {
                    ElementInspectorView(element: $appState.activeTemplate.elements[index])
                } else {
                    BackgroundInspectorView(template: $appState.activeTemplate)
                }
            }
            .frame(minWidth: 260, maxWidth: 340)
        }
        .sheet(isPresented: $isStickerPickerPresented) {
            StickerPickerView { type, customPath in
                addStickerElement(type: type, customPath: customPath)
                isStickerPickerPresented = false
            }
            .frame(width: 420, height: 380)
        }
    }
    
    private func iconForElement(_ type: ElementType) -> String {
        switch type {
        case .callsign: return "textformat.characters"
        case .address: return "text.alignleft"
        case .table: return "tablecells"
        case .locationFooter: return "mappin.and.ellipse"
        case .sticker: return "shield.lefthalf.filled"
        case .text: return "character"
        }
    }
    
    private func addElement(type: ElementType) {
        let newElement: CardElement
        switch type {
        case .callsign:
            newElement = CardElement(type: .callsign, name: "Callsign", normalizedX: 0.3, normalizedY: 0.2, normalizedWidth: 0.4, normalizedHeight: 0.15, textContent: appState.settings.myCallsign, effectType: .metallicGold)
        case .address:
            newElement = CardElement(type: .address, name: "Address", normalizedX: 0.3, normalizedY: 0.4, normalizedWidth: 0.35, normalizedHeight: 0.2, textContent: appState.settings.fullMyAddress)
        case .table:
            newElement = CardElement(type: .table, name: "QSO Table", normalizedX: 0.5, normalizedY: 0.85, normalizedWidth: 0.85, normalizedHeight: 0.18)
        case .locationFooter:
            newElement = CardElement(type: .locationFooter, name: "Location Line", normalizedX: 0.5, normalizedY: 0.96, normalizedWidth: 0.75, normalizedHeight: 0.05, textContent: "ITU: {MY_ITU} CQ: {MY_CQ} Grid: {MY_GRID}")
        case .sticker:
            newElement = CardElement(type: .sticker, name: "Badge", normalizedX: 0.5, normalizedY: 0.2, normalizedWidth: 0.12, normalizedHeight: 0.18, stickerType: .arrl)
        case .text:
            newElement = CardElement(type: .text, name: "Text", normalizedX: 0.5, normalizedY: 0.5, normalizedWidth: 0.3, normalizedHeight: 0.1, textContent: "Custom Text")
        }
        
        appState.activeTemplate.elements.append(newElement)
        selectedElementId = newElement.id
    }
    
    private func addStickerElement(type: StickerType, customPath: String?) {
        let name = type == .custom ? "Custom Badge" : type.rawValue
        let newElement = CardElement(
            type: .sticker,
            name: name,
            normalizedX: 0.5,
            normalizedY: 0.25,
            normalizedWidth: 0.12,
            normalizedHeight: 0.18,
            stickerType: type,
            customImagePath: customPath
        )
        appState.activeTemplate.elements.append(newElement)
        selectedElementId = newElement.id
    }
    
    private func toggleVisibility(_ id: UUID) {
        if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
            appState.activeTemplate.elements[idx].isVisible.toggle()
        }
    }
    
    private func duplicateElement(_ id: UUID) {
        if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
            var clone = appState.activeTemplate.elements[idx]
            clone.id = UUID()
            clone.name += " Copy"
            clone.normalizedX = min(clone.normalizedX + 0.05, 0.9)
            clone.normalizedY = min(clone.normalizedY + 0.05, 0.9)
            appState.activeTemplate.elements.append(clone)
            selectedElementId = clone.id
        }
    }
    
    private func deleteElement(_ id: UUID) {
        appState.activeTemplate.elements.removeAll(where: { $0.id == id })
        if selectedElementId == id {
            selectedElementId = nil
        }
    }
    
    private func createNewTemplate() {
        var newT = QSLCardTemplate.createDefaultTemplate(myCall: appState.settings.myCallsign)
        newT.name = "Card Template \(appState.templates.count + 1)"
        appState.templates.append(newT)
        appState.selectedTemplateId = newT.id
    }
    
    private func exportCardImage() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.jpeg, .png]
        savePanel.nameFieldStringValue = "QSL_Preview.jpg"
        if savePanel.runModal() == .OK, let url = savePanel.url {
            if let data = CardRenderer.shared.renderCardToJPEGData(
                template: appState.activeTemplate,
                settings: appState.settings,
                qso: sampleQSO,
                scale: 3.0
            ) {
                try? data.write(to: url)
            }
        }
    }
}
