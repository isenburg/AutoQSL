import SwiftUI
import AppKit

public struct CardDesignerRootView: View {
    @ObservedObject var appState: AppState
    
    @State private var selectedElementId: UUID? = canvasBackgroundSelectionId
    @State private var zoomScale: CGFloat = 0.8
    @GestureState private var pinchMagnification: CGFloat = 1.05
    @State private var isStickerPickerPresented: Bool = false
    @State private var selectedPreviewQSOId: UUID? = nil
    @State private var isDeleteTemplateConfirmationPresented: Bool = false
        
    // Undo / Redo History Stack
    @State private var undoStack: [QSLCardTemplate] = []
    @State private var redoStack: [QSLCardTemplate] = []
    @State private var isUndoRedoAction: Bool = false
    @State private var previousTemplateSnapshot: QSLCardTemplate? = nil
    @State private var keyMonitor: Any? = nil
    
    private var activePreviewQSO: QSO {
        if let selId = selectedPreviewQSOId, let q = appState.qsoQueue.first(where: { $0.id == selId }) {
            return q
        }
        return sampleQSO
    }
    
    private var sampleQSO: QSO {
        QSO(
            source: .manual,
            dxCall: "DJ6GI",
            band: "20m",
            mode: "FT8",
            frequencyHz: 14074000,
            qsoDate: Date(),
            rstSent: "-12",
            rstRcvd: "-08",
            comment: appState.settings.defaultComment,
            txPowerWatts: 50,
            dxName: "Gerd Ihde",
            dxGrid: "JN58td",
            dxCountry: "Germany",
            dxEmail: "dj6gi@example.com",
            qrzFound: true
        )
    }
    
    public var body: some View {
        let lang = appState.settings.appLanguage
        HSplitView {
            // Left: Elements Tree
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text(L10n.tr(lang, "Card Elements", "Kartenelemente"))
                        .font(.headline)
                    Spacer()
                    Menu {
                        Button(L10n.tr(lang, "Callsign Block", "Rufzeichen-Block")) { addElement(type: .callsign) }
                        Button(L10n.tr(lang, "Address Block", "Adress-Block")) { addElement(type: .address) }
                        Button(L10n.tr(lang, "QSO Table", "QSO-Tabelle")) { addElement(type: .table) }
                        Button(L10n.tr(lang, "Location Line", "Standortzeile")) { addElement(type: .locationFooter) }
                        Button(L10n.tr(lang, "Custom Text", "Freier Text")) { addElement(type: .text) }
                        Divider()
                        Button(L10n.tr(lang, "Add Badge / Sticker...", "Sticker / Abzeichen...")) { isStickerPickerPresented = true }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                    }
                    .menuStyle(.borderlessButton)
                    .help("Add new element to card")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                List(selection: $selectedElementId) {
                    Section {
                        ForEach([canvasBackgroundSelectionId], id: \.self) { bgId in
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                    .frame(width: 20)
                                    .foregroundColor(.accentColor)
                                
                                Text(L10n.tr(lang, "Background Picture", "Hintergrundbild"))
                                    .font(.callout.bold())
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                            .tag(bgId as UUID?)
                        }
                    } header: {
                        Text(L10n.tr(lang, "Canvas", "Leinwand"))
                    }
                    
                    Section {
                        ForEach(appState.activeTemplate.elements) { element in
                            HStack(spacing: 8) {
                                Image(systemName: iconForElement(element.type))
                                    .frame(width: 20)
                                    .foregroundColor(.accentColor)
                                
                                Text(layerDisplayName(for: element))
                                    .font(.callout)
                                    .lineLimit(1)
                                
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
                                Button(lang == .german ? "Duplizieren" : "Duplicate") {
                                    duplicateElement(element.id)
                                }
                                Button(lang == .german ? "Löschen" : "Delete", role: .destructive) {
                                    deleteElement(element.id)
                                }
                            }
                        }
                    } header: {
                        Text(L10n.tr(lang, "Layers", "Ebenen"))
                    }
                }
                .listStyle(.inset)
                .onDeleteCommand {
                    if let selId = selectedElementId, selId != canvasBackgroundSelectionId {
                        deleteElement(selId)
                    }
                }
                
                Divider()
                
                HStack(spacing: 8) {
                    Button(action: {
                        if let selId = selectedElementId, selId != canvasBackgroundSelectionId {
                            deleteElement(selId)
                        }
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedElementId == nil || selectedElementId == canvasBackgroundSelectionId)
                    .help(lang == .german ? "Ausgewähltes Element löschen (⌫)" : "Delete selected element (⌫)")
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .frame(minWidth: 200, idealWidth: 240, maxWidth: 350)
            .background(SplitViewAutosaver(name: "AutoQSL_Designer_SplitView"))
            .onDeleteCommand {
                if let selId = selectedElementId, selId != canvasBackgroundSelectionId {
                    deleteElement(selId)
                }
            }
            
            // Center: Interactive Workspace Canvas
            VStack(spacing: 0) {
                // Top Action Toolbar
                HStack(alignment: .bottom, spacing: 14) {
                    // Template Selector (Label above picker)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.tr(lang, "Template:", "Vorlage:"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Picker("", selection: $appState.selectedTemplateId) {
                                ForEach(appState.templates) { template in
                                    Text(template.name).tag(template.id)
                                }
                            }
                            .labelsHidden()
                            .controlSize(.regular)
                            .frame(width: 260)
                            
                            Button(action: { appState.duplicateTemplate(id: appState.selectedTemplateId) }) {
                                Image(systemName: "doc.on.doc")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .help(lang == .german ? "Aktive Vorlage duplizieren / kopieren" : "Duplicate active template")
                            
                            Button(action: createNewTemplate) {
                                Image(systemName: "plus")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .help(L10n.tr(lang, "Create new template", "Neue Vorlage erstellen"))
                            
                            Button(action: { isDeleteTemplateConfirmationPresented = true }) {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.regular)
                            .help(L10n.tr(lang, "Delete active template", "Aktive Vorlage löschen"))
                            .disabled(appState.templates.count <= 1)
                        }
                    }
                    
                    Divider().frame(height: 22)
                    
                    // Preview QSO Selector (Label above picker)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.tr(lang, "Preview QSO:", "Vorschau-QSO:"))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedPreviewQSOId) {
                            Text(L10n.tr(lang, "Sample (DJ6GI)", "Muster (DJ6GI)")).tag(nil as UUID?)
                            ForEach(appState.qsoQueue) { q in
                                Text("\(q.dxCall) (\(q.band) \(q.mode))").tag(q.id as UUID?)
                            }
                        }
                        .labelsHidden()
                        .controlSize(.regular)
                        .frame(width: 240)
                    }
                    
                    Divider().frame(height: 22)
                    
                    // Undo / Redo (Same height and bottom-aligned with pickers)
                    HStack(spacing: 4) {
                        Button(action: performUndo) {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .help("Undo last change (⌘Z)")
                        .disabled(undoStack.isEmpty)
                        .keyboardShortcut("z", modifiers: .command)
                        
                        Button(action: performRedo) {
                            Image(systemName: "arrow.uturn.forward")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        .help("Redo last change (⇧⌘Z)")
                        .disabled(redoStack.isEmpty)
                        .keyboardShortcut("z", modifiers: [.command, .shift])
                    }
                    
                    Spacer()
                    
                    // Zoom Controls (Same regular height)
                    HStack(spacing: 4) {
                        Button(action: { zoomScale = max(zoomScale - 0.1, 0.4) }) {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                        
                        Text("\(Int((zoomScale * pinchMagnification) * 100))%")
                            .font(.caption.monospaced())
                            .frame(width: 38)
                        
                        Button(action: { zoomScale = min(zoomScale + 0.1, 1.5) }) {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    
                    Divider().frame(height: 22)
                    
                    Button(action: exportCardImage) {
                        Label(L10n.tr(lang, "Export Image", "Bild exportieren"), systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                
                Divider()
                
                // Canvas Area with Zoom & Centering
                GeometryReader { geo in
                    let currentScale = zoomScale * pinchMagnification
                    let baseW = appState.activeTemplate.aspectRatio.widthPoints
                    let baseH = appState.activeTemplate.aspectRatio.heightPoints
                    let scaledW = baseW * currentScale
                    let scaledH = baseH * currentScale
                    
                    ScrollView([.horizontal, .vertical], showsIndicators: true) {
                        ZStack {
                            Color(NSColor.underPageBackgroundColor)
                            
                            CardCanvasView(
                                template: appState.activeTemplate,
                                settings: appState.settings,
                                qso: activePreviewQSO,
                                isInteractive: true,
                                selectedElementId: $selectedElementId,
                                onElementMoved: { id, newNormX, newNormY in
                                    if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                                        appState.activeTemplate.elements[idx].normalizedX = newNormX
                                        appState.activeTemplate.elements[idx].normalizedY = newNormY
                                    }
                                },
                                onElementResized: { id, newNormW, newNormH, newFontSize in
                                    if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                                        appState.activeTemplate.elements[idx].normalizedWidth = newNormW
                                        appState.activeTemplate.elements[idx].normalizedHeight = newNormH
                                        if let fs = newFontSize {
                                            appState.activeTemplate.elements[idx].fontSize = fs
                                        }
                                    }
                                },
                                onElementTextChanged: { id, newText in
                                    if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                                        appState.activeTemplate.elements[idx].textContent = newText
                                    }
                                }
                            )
                            .frame(width: baseW, height: baseH)
                            .scaleEffect(currentScale)
                            .shadow(color: .black.opacity(0.35), radius: 12, x: 0, y: 6)
                            .padding(40)
                        }
                        .frame(
                            width: max(geo.size.width, scaledW + 80),
                            height: max(geo.size.height, scaledH + 80)
                        )
                    }
                    .gesture(
                        MagnificationGesture()
                            .updating($pinchMagnification) { val, state, _ in
                                state = val
                            }
                            .onEnded { val in
                                zoomScale = min(max(zoomScale * val, 0.3), 2.5)
                            }
                    )
                }
            }
            .frame(minWidth: 500)
            
            // Right: Inspector Panel
            VStack(spacing: 0) {
                if let selectedId = selectedElementId,
                   let index = appState.activeTemplate.elements.firstIndex(where: { $0.id == selectedId }) {
                    ElementInspectorView(element: $appState.activeTemplate.elements[index])
                    
                    Divider()
                    
                    VStack {
                        Button(role: .destructive, action: {
                            deleteElement(selectedId)
                        }) {
                            Label(lang == .german ? "Element löschen" : "Delete Element", systemImage: "trash")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.regular)
                    }
                    .padding(12)
                    .background(Color(NSColor.controlBackgroundColor))
                } else {
                    BackgroundInspectorView(template: $appState.activeTemplate, lang: appState.settings.appLanguage)
                }
            }
            .frame(minWidth: 260, maxWidth: 340)
        }
        .sheet(isPresented: $isStickerPickerPresented) {
            StickerPickerView { item in
                addStickerElement(item: item)
                isStickerPickerPresented = false
            }
            .environmentObject(appState)
            .frame(width: 520, height: 500)
        }
        .confirmationDialog(
            "Delete Template '\(appState.activeTemplate.name)'?",
            isPresented: $isDeleteTemplateConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete Template", role: .destructive) {
                appState.deleteTemplate(id: appState.selectedTemplateId)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deleting this template will not affect any QSOs that were already sent or queued.")
        }
        .onAppear {
            previousTemplateSnapshot = appState.activeTemplate
            if keyMonitor == nil {
                keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    if event.keyCode == 51 || event.keyCode == 117 { // 51 = Backspace/Delete, 117 = Forward Delete
                        if let window = NSApp.keyWindow,
                           let responder = window.firstResponder,
                           (responder is NSTextView || responder is NSTextField) {
                            return event
                        }
                        if let selId = selectedElementId, selId != canvasBackgroundSelectionId {
                            deleteElement(selId)
                            return nil
                        }
                    }
                    return event
                }
            }
        }
        .onDisappear {
            if let monitor = keyMonitor {
                NSEvent.removeMonitor(monitor)
                keyMonitor = nil
            }
        }
        .onChange(of: appState.selectedTemplateId) { _, _ in
            undoStack.removeAll()
            redoStack.removeAll()
            previousTemplateSnapshot = appState.activeTemplate
        }
        .onChange(of: appState.activeTemplate) { _, newTemplate in
            if isUndoRedoAction {
                isUndoRedoAction = false
                previousTemplateSnapshot = newTemplate
                return
            }
            if let prev = previousTemplateSnapshot, prev != newTemplate {
                undoStack.append(prev)
                if undoStack.count > 50 {
                    undoStack.removeFirst()
                }
                redoStack.removeAll()
                previousTemplateSnapshot = newTemplate
            }
        }
    }
    
    private func performUndo() {
        guard let prev = undoStack.popLast() else { return }
        redoStack.append(appState.activeTemplate)
        isUndoRedoAction = true
        previousTemplateSnapshot = prev
        appState.activeTemplate = prev
    }
    
    private func performRedo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(appState.activeTemplate)
        isUndoRedoAction = true
        previousTemplateSnapshot = next
        appState.activeTemplate = next
    }
    
    private func layerDisplayName(for element: CardElement) -> String {
        if element.type == .text {
            let trimmed = element.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                let firstLine = trimmed.components(separatedBy: .newlines).first ?? trimmed
                return firstLine.count > 25 ? String(firstLine.prefix(25)) + "..." : firstLine
            }
        }
        return element.name
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
        var newT = QSLCardTemplate.createDefaultTemplate(myCall: appState.settings.myCallsign, myAddress: appState.settings.fullMyAddress)
        newT.name = "Card Template \(appState.templates.count + 1)"
        newT.backgroundColorHex = "#E8E8E8"
        newT.backgroundImagePath = nil
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
                qso: activePreviewQSO,
                scale: 3.0
            ) {
                try? data.write(to: url)
            }
        }
    }
}
