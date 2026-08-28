import SwiftUI
import AppKit

public struct CardDesignerRootView: View {
    @ObservedObject var appState: AppState
    
    @State private var selectedElementIds: Set<UUID> = [canvasBackgroundSelectionId]
    @State private var zoomScale: CGFloat? = nil
    @State private var isAutoFit: Bool = true
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
                
                List(selection: $selectedElementIds) {
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
                            .tag(bgId)
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
                            .tag(element.id)
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
                    deleteSelectedElements()
                }
                
                Divider()
                
                HStack(spacing: 8) {
                    Button(action: {
                        deleteSelectedElements()
                    }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.borderless)
                    .disabled(selectedElementIds.filter({ $0 != canvasBackgroundSelectionId }).isEmpty)
                    .help(lang == .german ? "Ausgewählte Elemente löschen (⌫)" : "Delete selected elements (⌫)")
                    
                    Spacer()
                    
                    let nonBgCount = selectedElementIds.filter({ $0 != canvasBackgroundSelectionId }).count
                    if nonBgCount > 1 {
                        Text("\(nonBgCount) selected")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .frame(minWidth: 200, idealWidth: 240, maxWidth: 350)
            .background(SplitViewAutosaver(name: "AutoQSL_Designer_SplitView"))
            .onDeleteCommand {
                deleteSelectedElements()
            }
            
            // Center: Interactive Workspace Canvas
            VStack(spacing: 0) {
                // Top Action Toolbar (Compact Space-Optimized Layout)
                HStack(alignment: .bottom, spacing: 8) {
                    // Template Selector
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr(lang, "Template:", "Vorlage:"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 3) {
                            Picker("", selection: $appState.selectedTemplateId) {
                                ForEach(appState.templates) { template in
                                    Text(template.name).tag(template.id)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 145)
                            
                            Button(action: createNewTemplate) {
                                Image(systemName: "plus")
                            }
                            .help(lang == .german ? "Neue Vorlage erstellen" : "Create new template")
                            
                            Button(role: .destructive, action: {
                                isDeleteTemplateConfirmationPresented = true
                            }) {
                                Image(systemName: "trash")
                            }
                            .disabled(appState.templates.count <= 1)
                            .help(lang == .german ? "Aktuelle Vorlage löschen" : "Delete current template")
                        }
                    }
                    
                    Divider().frame(height: 28)
                    
                    // Undo & Redo Buttons
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr(lang, "History:", "Verlauf:"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 3) {
                            Button(action: performUndo) {
                                Image(systemName: "arrow.uturn.backward")
                            }
                            .disabled(undoStack.isEmpty)
                            .help(lang == .german ? "Rückgängig (⌘Z)" : "Undo (⌘Z)")
                            
                            Button(action: performRedo) {
                                Image(systemName: "arrow.uturn.forward")
                            }
                            .disabled(redoStack.isEmpty)
                            .help(lang == .german ? "Wiederholen (⇧⌘Z)" : "Redo (⇧⌘Z)")
                        }
                    }
                    
                    Divider().frame(height: 28)
                    
                    // QSO Data Preview Source
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.tr(lang, "Preview QSO:", "Vorschau-QSO:"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $selectedPreviewQSOId) {
                            Text(lang == .german ? "Beispiel: DJ6GI (Standard)" : "Sample: DJ6GI (Default)").tag(nil as UUID?)
                            
                            if !appState.qsoQueue.isEmpty {
                                Divider()
                                ForEach(appState.qsoQueue) { qso in
                                    Text("\(qso.dxCall) - \(qso.band) \(qso.mode) (\(qso.formattedUTCTime))").tag(qso.id as UUID?)
                                }
                            }
                        }
                        .labelsHidden()
                        .frame(width: 175)
                    }
                    
                    Spacer()
                    
                    // Zoom Controls
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.tr(lang, "View Zoom:", "Zoom:"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            Button(action: {
                                isAutoFit = true
                                zoomScale = nil
                            }) {
                                Text(L10n.tr(lang, "Fit", "Einpassen"))
                                    .font(.caption2.bold())
                                    .foregroundColor(isAutoFit ? .accentColor : .primary)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                isAutoFit = false
                                let cur = zoomScale ?? 1.0
                                zoomScale = max(cur - 0.15, 0.3)
                            }) {
                                Image(systemName: "minus.magnifyingglass")
                            }
                            
                            Button(action: {
                                isAutoFit = false
                                zoomScale = 1.0
                            }) {
                                Text("100%")
                                    .font(.caption2)
                            }
                            
                            Button(action: {
                                isAutoFit = false
                                let cur = zoomScale ?? 1.0
                                zoomScale = min(cur + 0.15, 2.5)
                            }) {
                                Image(systemName: "plus.magnifyingglass")
                            }
                        }
                    }
                    
                    Divider().frame(height: 28)
                    
                    // Export Card Image
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.tr(lang, "Export:", "Export:"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        Button(action: exportCardImage) {
                            Label(L10n.tr(lang, "Export JPEG...", "JPEG Export..."), systemImage: "square.and.arrow.up")
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                // Canvas Area with Dynamic Auto-Fit & Space Filling
                GeometryReader { geo in
                    let baseW = appState.activeTemplate.aspectRatio.widthPoints
                    let baseH = appState.activeTemplate.aspectRatio.heightPoints
                    
                    let availW = max(geo.size.width - 48, 200)
                    let availH = max(geo.size.height - 48, 200)
                    let autoFitScale = min(availW / baseW, availH / baseH)
                    
                    let activeScale = isAutoFit ? autoFitScale : (zoomScale ?? autoFitScale)
                    let currentScale = activeScale * pinchMagnification
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
                                selectedElementIds: $selectedElementIds,
                                onElementMoved: { id, newNormX, newNormY in
                                    if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                                        appState.activeTemplate.elements[idx].normalizedX = newNormX
                                        appState.activeTemplate.elements[idx].normalizedY = newNormY
                                    }
                                },
                                onMultiElementsMoved: { ids, deltaX, deltaY in
                                    moveSelectedElements(ids: ids, deltaX: deltaX, deltaY: deltaY)
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
                            .shadow(color: .black.opacity(0.35), radius: 14, x: 0, y: 7)
                            .padding(24)
                        }
                        .frame(
                            width: max(geo.size.width, scaledW + 48),
                            height: max(geo.size.height, scaledH + 48)
                        )
                    }
                    .gesture(
                        MagnificationGesture()
                            .updating($pinchMagnification) { val, state, _ in
                                state = val
                            }
                            .onEnded { val in
                                isAutoFit = false
                                let cur = zoomScale ?? autoFitScale
                                zoomScale = min(max(cur * val, 0.3), 2.5)
                            }
                    )
                }
            }
            .frame(minWidth: 500)
            
            // Right: Inspector Panel (Single, Multi, or Canvas Background)
            VStack(spacing: 0) {
                let nonBgSelected = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
                
                if nonBgSelected.count > 1 {
                    MultiElementInspectorView(
                        count: nonBgSelected.count,
                        lang: appState.settings.appLanguage,
                        onAlign: { alignSelectedElements(to: $0) },
                        onDistribute: { distributeSelectedElements(axis: $0) },
                        onDuplicate: { duplicateSelectedElements() },
                        onToggleLock: { toggleLockSelectedElements() },
                        onToggleVisibility: { toggleVisibilitySelectedElements() },
                        onDelete: { deleteSelectedElements() }
                    )
                } else if let singleId = nonBgSelected.first,
                          let index = appState.activeTemplate.elements.firstIndex(where: { $0.id == singleId }) {
                    ElementInspectorView(element: $appState.activeTemplate.elements[index], lang: appState.settings.appLanguage)
                    
                    Divider()
                    
                    VStack {
                        Button(role: .destructive, action: {
                            deleteElement(singleId)
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
                    // Prevent stealing keys when user is typing in a text field / inspector
                    if let window = NSApp.keyWindow,
                       let responder = window.firstResponder,
                       (responder is NSTextView || responder is NSTextField) {
                        return event
                    }
                    
                    let nonBgSelected = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
                    guard !nonBgSelected.isEmpty else {
                        return event
                    }
                    
                    // 1. Delete element with Backspace / Forward Delete
                    if event.keyCode == 51 || event.keyCode == 117 {
                        deleteSelectedElements()
                        return nil
                    }
                    
                    // 2. Move elements with Arrow Keys (123: Left, 124: Right, 125: Down, 126: Up)
                    if event.keyCode >= 123 && event.keyCode <= 126 {
                        let isShift = event.modifierFlags.contains(.shift)
                        let isOption = event.modifierFlags.contains(.option)
                        let pts: Double = isShift ? 10.0 : (isOption ? 5.0 : 1.0)
                        
                        let baseW = max(appState.activeTemplate.aspectRatio.widthPoints, 100.0)
                        let baseH = max(appState.activeTemplate.aspectRatio.heightPoints, 100.0)
                        let stepX = pts / baseW
                        let stepY = pts / baseH
                        
                        switch event.keyCode {
                        case 123: // Left
                            nudgeSelectedElements(dx: -stepX, dy: 0)
                        case 124: // Right
                            nudgeSelectedElements(dx: stepX, dy: 0)
                        case 125: // Down
                            nudgeSelectedElements(dx: 0, dy: stepY)
                        case 126: // Up
                            nudgeSelectedElements(dx: 0, dy: -stepY)
                        default:
                            break
                        }
                        return nil
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
            appState.syncTableCommentToSettings()
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
        selectedElementIds = [newElement.id]
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
        selectedElementIds = [newElement.id]
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
            selectedElementIds = [clone.id]
        }
    }
    
    private func moveSelectedElements(ids: Set<UUID>, deltaX: Double, deltaY: Double) {
        for id in ids {
            if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                appState.activeTemplate.elements[idx].normalizedX = min(max(appState.activeTemplate.elements[idx].normalizedX + deltaX, 0.01), 0.99)
                appState.activeTemplate.elements[idx].normalizedY = min(max(appState.activeTemplate.elements[idx].normalizedY + deltaY, 0.01), 0.99)
            }
        }
    }
    
    private func nudgeSelectedElements(dx: Double, dy: Double) {
        let validIds = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        guard !validIds.isEmpty else { return }
        moveSelectedElements(ids: validIds, deltaX: dx, deltaY: dy)
    }

    private func deleteElement(_ id: UUID) {
        appState.activeTemplate.elements.removeAll(where: { $0.id == id })
        selectedElementIds.remove(id)
        if selectedElementIds.isEmpty {
            selectedElementIds = [canvasBackgroundSelectionId]
        }
    }
    
    private func deleteSelectedElements() {
        let toDelete = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        guard !toDelete.isEmpty else { return }
        appState.activeTemplate.elements.removeAll(where: { toDelete.contains($0.id) })
        selectedElementIds = [canvasBackgroundSelectionId]
    }
    
    private func duplicateSelectedElements() {
        let toDup = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        guard !toDup.isEmpty else { return }
        var newIds: Set<UUID> = []
        for id in toDup {
            if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                var clone = appState.activeTemplate.elements[idx]
                clone.id = UUID()
                clone.name += " Copy"
                clone.normalizedX = min(clone.normalizedX + 0.04, 0.94)
                clone.normalizedY = min(clone.normalizedY + 0.04, 0.94)
                appState.activeTemplate.elements.append(clone)
                newIds.insert(clone.id)
            }
        }
        if !newIds.isEmpty {
            selectedElementIds = newIds
        }
    }
    
    private func alignSelectedElements(to alignment: MultiAlignment) {
        let targetIds = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        guard targetIds.count > 1 else { return }
        
        let elements = appState.activeTemplate.elements.filter { targetIds.contains($0.id) && !$0.isLocked }
        guard elements.count > 1 else { return }
        
        switch alignment {
        case .left:
            let minLeft = elements.map { $0.normalizedX - ($0.normalizedWidth / 2.0) }.min() ?? 0.1
            for id in targetIds {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                    let w = appState.activeTemplate.elements[idx].normalizedWidth
                    appState.activeTemplate.elements[idx].normalizedX = min(max(minLeft + (w / 2.0), 0.01), 0.99)
                }
            }
        case .centerH:
            let avgX = elements.map { $0.normalizedX }.reduce(0, +) / Double(elements.count)
            for id in targetIds {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                    appState.activeTemplate.elements[idx].normalizedX = min(max(avgX, 0.01), 0.99)
                }
            }
        case .right:
            let maxRight = elements.map { $0.normalizedX + ($0.normalizedWidth / 2.0) }.max() ?? 0.9
            for id in targetIds {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                    let w = appState.activeTemplate.elements[idx].normalizedWidth
                    appState.activeTemplate.elements[idx].normalizedX = min(max(maxRight - (w / 2.0), 0.01), 0.99)
                }
            }
        case .top:
            let minTop = elements.map { $0.normalizedY - ($0.normalizedHeight / 2.0) }.min() ?? 0.1
            for id in targetIds {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                    let h = appState.activeTemplate.elements[idx].normalizedHeight
                    appState.activeTemplate.elements[idx].normalizedY = min(max(minTop + (h / 2.0), 0.01), 0.99)
                }
            }
        case .centerV:
            let avgY = elements.map { $0.normalizedY }.reduce(0, +) / Double(elements.count)
            for id in targetIds {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                    appState.activeTemplate.elements[idx].normalizedY = min(max(avgY, 0.01), 0.99)
                }
            }
        case .bottom:
            let maxBottom = elements.map { $0.normalizedY + ($0.normalizedHeight / 2.0) }.max() ?? 0.9
            for id in targetIds {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id && !$0.isLocked }) {
                    let h = appState.activeTemplate.elements[idx].normalizedHeight
                    appState.activeTemplate.elements[idx].normalizedY = min(max(maxBottom - (h / 2.0), 0.01), 0.99)
                }
            }
        }
    }
    
    private func distributeSelectedElements(axis: Axis) {
        let targetIds = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        guard targetIds.count >= 3 else { return }
        
        var elements = appState.activeTemplate.elements.filter { targetIds.contains($0.id) && !$0.isLocked }
        guard elements.count >= 3 else { return }
        
        if axis == .horizontal {
            elements.sort { $0.normalizedX < $1.normalizedX }
            guard let firstX = elements.first?.normalizedX, let lastX = elements.last?.normalizedX else { return }
            let step = (lastX - firstX) / Double(elements.count - 1)
            for (i, el) in elements.enumerated() {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == el.id }) {
                    appState.activeTemplate.elements[idx].normalizedX = min(max(firstX + (Double(i) * step), 0.01), 0.99)
                }
            }
        } else {
            elements.sort { $0.normalizedY < $1.normalizedY }
            guard let firstY = elements.first?.normalizedY, let lastY = elements.last?.normalizedY else { return }
            let step = (lastY - firstY) / Double(elements.count - 1)
            for (i, el) in elements.enumerated() {
                if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == el.id }) {
                    appState.activeTemplate.elements[idx].normalizedY = min(max(firstY + (Double(i) * step), 0.01), 0.99)
                }
            }
        }
    }
    
    private func toggleLockSelectedElements() {
        let targetIds = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        let shouldLock = appState.activeTemplate.elements.filter({ targetIds.contains($0.id) }).contains(where: { !$0.isLocked })
        for id in targetIds {
            if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                appState.activeTemplate.elements[idx].isLocked = shouldLock
            }
        }
    }
    
    private func toggleVisibilitySelectedElements() {
        let targetIds = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
        let shouldShow = appState.activeTemplate.elements.filter({ targetIds.contains($0.id) }).contains(where: { !$0.isVisible })
        for id in targetIds {
            if let idx = appState.activeTemplate.elements.firstIndex(where: { $0.id == id }) {
                appState.activeTemplate.elements[idx].isVisible = shouldShow
            }
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
