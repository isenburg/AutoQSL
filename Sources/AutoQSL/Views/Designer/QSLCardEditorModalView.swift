import SwiftUI
import AppKit

public struct QSLCardEditorModalView: View {
    @ObservedObject var appState: AppState
    let qso: QSO
    @Binding var isPresented: Bool
    
    @State private var workingTemplate: QSLCardTemplate
    @State private var selectedElementId: UUID? = canvasBackgroundSelectionId
    @State private var zoomScale: CGFloat = 0.8
    @State private var isStickerPickerPresented: Bool = false
    
    public init(appState: AppState, qso: QSO, isPresented: Binding<Bool>) {
        self.appState = appState
        self.qso = qso
        self._isPresented = isPresented
        
        let initialTmpl = qso.customTemplate ?? (qso.templateId.flatMap { tid in
            appState.templates.first(where: { $0.id == tid })
        } ?? appState.activeTemplate)
        
        self._workingTemplate = State(initialValue: initialTmpl)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Customize QSL Card: \(qso.dxCall)")
                        .font(.headline)
                    Text("Directly edit layout, fonts, colors, and stickers for this QSL card")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add Element Menu
                Menu {
                    Button("Callsign Block") { addElement(type: .callsign) }
                    Button("Address Block") { addElement(type: .address) }
                    Button("QSO Table") { addElement(type: .table) }
                    Button("Location Footer") { addElement(type: .locationFooter) }
                    Button("Custom Text") { addElement(type: .text) }
                    Divider()
                    Button("Add Badge / Sticker...") { isStickerPickerPresented = true }
                } label: {
                    Label("Add Element", systemImage: "plus.rectangle")
                }
                
                // Template Starting Point
                Menu {
                    ForEach(appState.templates) { t in
                        Button(t.name) {
                            workingTemplate = t
                        }
                    }
                } label: {
                    Label("Load Template", systemImage: "folder")
                }
                
                Divider().frame(height: 18)
                
                // Zoom Controls
                HStack(spacing: 4) {
                    Button(action: { zoomScale = max(zoomScale - 0.1, 0.4) }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    Text("\(Int(zoomScale * 100))%")
                        .font(.caption.monospaced())
                        .frame(width: 44)
                    Button(action: { zoomScale = min(zoomScale + 0.1, 1.4) }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                }
                
                Divider().frame(height: 18)
                
                Button("Cancel") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button(action: saveCustomCard) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Apply to Card")
                    }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 3-Pane or 2-Pane Editor
            HSplitView {
                // Left: Elements Tree
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Layers")
                            .font(.subheadline.bold())
                        Spacer()
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    
                    Divider()
                    
                    List(selection: $selectedElementId) {
                        Section {
                            ForEach([canvasBackgroundSelectionId], id: \.self) { bgId in
                                HStack {
                                    Image(systemName: "photo.on.rectangle")
                                        .frame(width: 18)
                                        .foregroundColor(.accentColor)
                                    
                                    Text("Background Picture")
                                        .font(.callout.bold())
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 2)
                                .tag(bgId as UUID?)
                            }
                        } header: {
                            Text("Canvas")
                        }
                        
                        Section {
                            ForEach(workingTemplate.elements) { element in
                                HStack {
                                    Image(systemName: iconForElement(element.type))
                                        .frame(width: 18)
                                        .foregroundColor(.accentColor)
                                    
                                    Text(element.name)
                                        .font(.callout)
                                    
                                    Spacer()
                                    
                                    Button(action: { toggleVisibility(element.id) }) {
                                        Image(systemName: element.isVisible ? "eye" : "eye.slash")
                                            .foregroundColor(element.isVisible ? .primary : .secondary)
                                    }
                                    .buttonStyle(.borderless)
                                }
                                .padding(.vertical, 2)
                                .tag(element.id as UUID?)
                                .contextMenu {
                                    Button("Duplicate") { duplicateElement(element.id) }
                                    Button("Delete", role: .destructive) { deleteElement(element.id) }
                                }
                            }
                        } header: {
                            Text("Layers")
                        }
                    }
                    .listStyle(.inset)
                }
                .frame(minWidth: 160, maxWidth: 220)
                
                // Center: Interactive Workspace Canvas
                ScrollView([.horizontal, .vertical]) {
                    ZStack {
                        Color(NSColor.underPageBackgroundColor)
                        
                        let baseW = workingTemplate.aspectRatio.widthPoints
                        let baseH = workingTemplate.aspectRatio.heightPoints
                        
                        CardCanvasView(
                            template: workingTemplate,
                            settings: appState.settings,
                            qso: qso,
                            isInteractive: true,
                            selectedElementId: $selectedElementId,
                            onElementMoved: { id, newNormX, newNormY in
                                if let idx = workingTemplate.elements.firstIndex(where: { $0.id == id }) {
                                    workingTemplate.elements[idx].normalizedX = newNormX
                                    workingTemplate.elements[idx].normalizedY = newNormY
                                }
                            },
                            onElementTextChanged: { id, newText in
                                if let idx = workingTemplate.elements.firstIndex(where: { $0.id == id }) {
                                    workingTemplate.elements[idx].textContent = newText
                                }
                            }
                        )
                        .frame(width: baseW, height: baseH)
                        .scaleEffect(zoomScale)
                        .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                        .padding(40)
                    }
                    .frame(minWidth: 500, maxWidth: .infinity, minHeight: 400, maxHeight: .infinity)
                }
                
                // Right: Inspector Panel
                VStack(spacing: 0) {
                    if let selectedId = selectedElementId,
                       let index = workingTemplate.elements.firstIndex(where: { $0.id == selectedId }) {
                        ElementInspectorView(element: $workingTemplate.elements[index])
                    } else {
                        BackgroundInspectorView(template: $workingTemplate)
                    }
                }
                .frame(minWidth: 260, maxWidth: 340)
            }
        }
        .frame(minWidth: 850, idealWidth: 1080, maxWidth: .infinity, minHeight: 580, idealHeight: 740, maxHeight: .infinity)
        .background(WindowResizeEnabler())
        .sheet(isPresented: $isStickerPickerPresented) {
            StickerPickerView { item in
                addStickerElement(item: item)
                isStickerPickerPresented = false
            }
            .environmentObject(appState)
            .frame(width: 520, height: 500)
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
        
        workingTemplate.elements.append(newElement)
        selectedElementId = newElement.id
    }
    
    private func addStickerElement(item: StickerItem) {
        let newElement = CardElement(
            type: .sticker,
            name: item.name,
            normalizedX: 0.5,
            normalizedY: 0.25,
            normalizedWidth: 0.12,
            normalizedHeight: 0.18,
            stickerType: item.type,
            customImagePath: item.customImagePath
        )
        workingTemplate.elements.append(newElement)
        selectedElementId = newElement.id
    }
    
    private func toggleVisibility(_ id: UUID) {
        if let idx = workingTemplate.elements.firstIndex(where: { $0.id == id }) {
            workingTemplate.elements[idx].isVisible.toggle()
        }
    }
    
    private func duplicateElement(_ id: UUID) {
        if let idx = workingTemplate.elements.firstIndex(where: { $0.id == id }) {
            var clone = workingTemplate.elements[idx]
            clone.id = UUID()
            clone.name += " Copy"
            clone.normalizedX = min(clone.normalizedX + 0.05, 0.9)
            clone.normalizedY = min(clone.normalizedY + 0.05, 0.9)
            workingTemplate.elements.append(clone)
            selectedElementId = clone.id
        }
    }
    
    private func deleteElement(_ id: UUID) {
        workingTemplate.elements.removeAll(where: { $0.id == id })
        if selectedElementId == id {
            selectedElementId = nil
        }
    }
    
    private func saveCustomCard() {
        appState.setCustomTemplate(for: qso.id, template: workingTemplate)
        isPresented = false
    }
}

public struct WindowResizeEnabler: NSViewRepresentable {
    public init() {}
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.styleMask.insert([.resizable])
                window.minSize = NSSize(width: 850, height: 580)
                window.showsResizeIndicator = true
            }
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            if let window = nsView.window {
                window.styleMask.insert([.resizable])
                window.minSize = NSSize(width: 850, height: 580)
                window.showsResizeIndicator = true
            }
        }
    }
}
