import SwiftUI
import AppKit

public let canvasBackgroundSelectionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

public struct CardCanvasView: View {
    public let template: QSLCardTemplate
    public let settings: AppSettings
    public let qso: QSO?
    public let isInteractive: Bool
    
    // Multi-selection set & single-selection binding support
    @Binding public var selectedElementIds: Set<UUID>
    public var onElementMoved: ((UUID, Double, Double) -> Void)?
    public var onMultiElementsMoved: ((Set<UUID>, Double, Double) -> Void)?
    public var onElementResized: ((UUID, Double, Double, Double?) -> Void)?
    public var onElementTextChanged: ((UUID, String) -> Void)?
    
    // Internal Marquee & Multi-drag state
    @State private var marqueeStart: CGPoint? = nil
    @State private var marqueeCurrent: CGPoint? = nil
    @State private var initialSelectionBeforeMarquee: Set<UUID> = []
    @State private var sharedMultiDragOffset: CGSize = .zero
    @State private var isMultiDragging: Bool = false
    
    // Initializer supporting Set<UUID> multi-selection
    public init(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO? = nil,
        isInteractive: Bool = false,
        selectedElementIds: Binding<Set<UUID>>,
        onElementMoved: ((UUID, Double, Double) -> Void)? = nil,
        onMultiElementsMoved: ((Set<UUID>, Double, Double) -> Void)? = nil,
        onElementResized: ((UUID, Double, Double, Double?) -> Void)? = nil,
        onElementTextChanged: ((UUID, String) -> Void)? = nil
    ) {
        self.template = template
        self.settings = settings
        self.qso = qso
        self.isInteractive = isInteractive
        self._selectedElementIds = selectedElementIds
        self.onElementMoved = onElementMoved
        self.onMultiElementsMoved = onMultiElementsMoved
        self.onElementResized = onElementResized
        self.onElementTextChanged = onElementTextChanged
    }
    
    // Backwards-compatible Initializer supporting single UUID? selection
    public init(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO? = nil,
        isInteractive: Bool = false,
        selectedElementId: Binding<UUID?> = .constant(nil),
        onElementMoved: ((UUID, Double, Double) -> Void)? = nil,
        onMultiElementsMoved: ((Set<UUID>, Double, Double) -> Void)? = nil,
        onElementResized: ((UUID, Double, Double, Double?) -> Void)? = nil,
        onElementTextChanged: ((UUID, String) -> Void)? = nil
    ) {
        self.template = template
        self.settings = settings
        self.qso = qso
        self.isInteractive = isInteractive
        
        let adapterBinding = Binding<Set<UUID>>(
            get: {
                if let id = selectedElementId.wrappedValue {
                    return [id]
                }
                return [canvasBackgroundSelectionId]
            },
            set: { newSet in
                if newSet.isEmpty || newSet.contains(canvasBackgroundSelectionId) {
                    selectedElementId.wrappedValue = canvasBackgroundSelectionId
                } else {
                    selectedElementId.wrappedValue = newSet.first
                }
            }
        )
        self._selectedElementIds = adapterBinding
        self.onElementMoved = onElementMoved
        self.onMultiElementsMoved = onMultiElementsMoved
        self.onElementResized = onElementResized
        self.onElementTextChanged = onElementTextChanged
    }
    
    public var body: some View {
        let baseWidth = CGFloat(template.aspectRatio.widthPoints)
        let baseHeight = CGFloat(template.aspectRatio.heightPoints)
        
        GeometryReader { geo in
            let targetWidth = geo.size.width
            let targetHeight = geo.size.height
            let scale = min(targetWidth / baseWidth, targetHeight / baseHeight)
            
            ZStack {
                // 1. Background Layer with Marquee selection gesture
                backgroundLayer(width: baseWidth, height: baseHeight, scale: scale)
                
                // 2. Elements Layers ordered by zIndex
                ForEach(template.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    if element.isVisible {
                        let isSelected = isInteractive && selectedElementIds.contains(element.id)
                        let activeDragOffset = (isSelected && isMultiDragging) ? sharedMultiDragOffset : .zero
                        
                        DraggableElementWrapperView(
                            element: element,
                            settings: settings,
                            qso: qso,
                            cardWidth: baseWidth,
                            cardHeight: baseHeight,
                            scale: scale,
                            isInteractive: isInteractive,
                            isSelected: isSelected,
                            isSoleSelection: isSelected && selectedElementIds.count == 1,
                            externalDragOffset: activeDragOffset,
                            onSelect: { isShiftOrCmd in
                                handleElementSelection(id: element.id, isShiftOrCmd: isShiftOrCmd)
                            },
                            onDragChanged: { offset in
                                isMultiDragging = true
                                sharedMultiDragOffset = offset
                            },
                            onDragEnded: { finalOffset in
                                isMultiDragging = false
                                sharedMultiDragOffset = .zero
                                handleDragCompleted(for: element.id, offset: finalOffset, width: baseWidth, height: baseHeight)
                            },
                            onResize: { newNormW, newNormH, newFontSize in
                                onElementResized?(element.id, newNormW, newNormH, newFontSize)
                            },
                            onTextChanged: { newText in
                                onElementTextChanged?(element.id, newText)
                            }
                        )
                    }
                }
                
                // 3. Live Rubberband / Marquee Selection Box
                if let start = marqueeStart, let cur = marqueeCurrent {
                    let rx = min(start.x, cur.x)
                    let ry = min(start.y, cur.y)
                    let rw = max(abs(cur.x - start.x), 1)
                    let rh = max(abs(cur.y - start.y), 1)
                    
                    ZStack {
                        Rectangle()
                            .fill(Color.accentColor.opacity(0.12))
                            .frame(width: rw, height: rh)
                        Rectangle()
                            .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                            .frame(width: rw, height: rh)
                    }
                    .position(x: rx + rw / 2, y: ry + rh / 2)
                    .allowsHitTesting(false)
                }
            }
            .frame(width: baseWidth, height: baseHeight)
            .scaleEffect(scale)
            .frame(width: targetWidth, height: targetHeight)
            .coordinateSpace(name: "CardCanvas")
            .clipped()
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Background Layer & Rubberband Drag Gesture
    
    @ViewBuilder
    private func backgroundLayer(width: CGFloat, height: CGFloat, scale: CGFloat) -> some View {
        ZStack {
            // Solid base color
            Color(hex: template.backgroundColorHex)
            
            // Custom Background Image if present
            if let bgPath = template.backgroundImagePath, !bgPath.isEmpty, let nsImage = NSImage(contentsOfFile: bgPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: template.backgroundFit == .fill ? .fill : (template.backgroundFit == .fit ? .fit : .fill))
                    .frame(width: width, height: height)
                    .clipped()
            }
            
            // Darken / Tint Overlay
            if template.backgroundDarkenOpacity > 0 {
                Color.black.opacity(template.backgroundDarkenOpacity)
            }
        }
        .frame(width: width, height: height)
        .contentShape(Rectangle())
        .onTapGesture {
            if isInteractive {
                selectedElementIds = [canvasBackgroundSelectionId]
            }
        }
        .gesture(
            isInteractive ?
            DragGesture(minimumDistance: 3, coordinateSpace: .named("CardCanvas"))
                .onChanged { value in
                    let effectiveScale = max(scale, 0.05)
                    let startX = value.startLocation.x / effectiveScale
                    let startY = value.startLocation.y / effectiveScale
                    let curX = value.location.x / effectiveScale
                    let curY = value.location.y / effectiveScale
                    
                    if marqueeStart == nil {
                        marqueeStart = CGPoint(x: startX, y: startY)
                        let isShift = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                        initialSelectionBeforeMarquee = isShift ? selectedElementIds.filter({ $0 != canvasBackgroundSelectionId }) : []
                    }
                    marqueeCurrent = CGPoint(x: curX, y: curY)
                    
                    // Update intersecting elements
                    updateMarqueeIntersections(
                        start: CGPoint(x: startX, y: startY),
                        current: CGPoint(x: curX, y: curY),
                        baseWidth: width,
                        baseHeight: height
                    )
                }
                .onEnded { _ in
                    marqueeStart = nil
                    marqueeCurrent = nil
                    initialSelectionBeforeMarquee = []
                    if selectedElementIds.isEmpty {
                        selectedElementIds = [canvasBackgroundSelectionId]
                    }
                }
            : nil
        )
    }
    
    // MARK: - Selection Handling
    
    private func handleElementSelection(id: UUID, isShiftOrCmd: Bool) {
        if isShiftOrCmd {
            var current = selectedElementIds.filter { $0 != canvasBackgroundSelectionId }
            if current.contains(id) {
                current.remove(id)
                if current.isEmpty {
                    selectedElementIds = [canvasBackgroundSelectionId]
                } else {
                    selectedElementIds = current
                }
            } else {
                current.insert(id)
                selectedElementIds = current
            }
        } else {
            selectedElementIds = [id]
        }
    }
    
    private func updateMarqueeIntersections(start: CGPoint, current: CGPoint, baseWidth: CGFloat, baseHeight: CGFloat) {
        let marqueeRect = CGRect(
            x: min(start.x, current.x),
            y: min(start.y, current.y),
            width: max(abs(current.x - start.x), 1),
            height: max(abs(current.y - start.y), 1)
        )
        
        var newSelection = initialSelectionBeforeMarquee
        for element in template.elements where element.isVisible && !element.isLocked {
            let elW = max(CGFloat(element.normalizedWidth) * baseWidth, 36)
            let elH = max(CGFloat(element.normalizedHeight) * baseHeight, 20)
            let elX = (CGFloat(element.normalizedX) * baseWidth) - (elW / 2.0)
            let elY = (CGFloat(element.normalizedY) * baseHeight) - (elH / 2.0)
            let elementRect = CGRect(x: elX, y: elY, width: elW, height: elH)
            
            if marqueeRect.intersects(elementRect) {
                newSelection.insert(element.id)
            }
        }
        
        selectedElementIds = newSelection.isEmpty ? [canvasBackgroundSelectionId] : newSelection
    }
    
    private func handleDragCompleted(for draggedId: UUID, offset: CGSize, width: CGFloat, height: CGFloat) {
        let deltaNormX = Double(offset.width / width)
        let deltaNormY = Double(offset.height / height)
        
        guard abs(deltaNormX) > 0.0001 || abs(deltaNormY) > 0.0001 else { return }
        
        let targetSet: Set<UUID> = selectedElementIds.contains(draggedId) ? selectedElementIds.filter({ $0 != canvasBackgroundSelectionId }) : [draggedId]
        
        if let onMulti = onMultiElementsMoved, targetSet.count > 1 {
            onMulti(targetSet, deltaNormX, deltaNormY)
        } else {
            for id in targetSet {
                if let el = template.elements.first(where: { $0.id == id }) {
                    let newNormX = min(max(el.normalizedX + deltaNormX, 0.01), 0.99)
                    let newNormY = min(max(el.normalizedY + deltaNormY, 0.01), 0.99)
                    onElementMoved?(id, newNormX, newNormY)
                }
            }
        }
    }
}

// MARK: - Draggable Element Wrapper View

public struct DraggableElementWrapperView: View {
    public let element: CardElement
    public let settings: AppSettings
    public let qso: QSO?
    public let cardWidth: CGFloat
    public let cardHeight: CGFloat
    public let scale: CGFloat
    public let isInteractive: Bool
    public let isSelected: Bool
    public let isSoleSelection: Bool
    public let externalDragOffset: CGSize
    public let onSelect: (Bool) -> Void
    public let onDragChanged: (CGSize) -> Void
    public let onDragEnded: (CGSize) -> Void
    public let onResize: ((Double, Double, Double?) -> Void)?
    public let onTextChanged: (String) -> Void
    
    @State private var dragStartNormX: Double? = nil
    @State private var dragStartNormY: Double? = nil
    @State private var localDragOffset: CGSize = .zero
    @State private var isHovering: Bool = false
    @State private var isInlineEditing: Bool = false
    @FocusState private var isInlineFieldFocused: Bool
    
    // Live Resize State
    @State private var isResizing: Bool = false
    @State private var resizeStartNormW: Double? = nil
    @State private var resizeStartNormH: Double? = nil
    @State private var resizeStartFontSize: Double? = nil
    @State private var liveResizeDelta: CGSize = .zero
    
    public var body: some View {
        let combinedOffset = CGSize(
            width: localDragOffset.width + externalDragOffset.width,
            height: localDragOffset.height + externalDragOffset.height
        )
        let posX = (CGFloat(element.normalizedX) * cardWidth) + combinedOffset.width
        let posY = (CGFloat(element.normalizedY) * cardHeight) + combinedOffset.height
        
        let baseElW = CGFloat(element.normalizedWidth) * cardWidth
        let baseElH = CGFloat(element.normalizedHeight) * cardHeight
        
        let elWidth = max(baseElW + liveResizeDelta.width, 24)
        let elHeight = max(baseElH + liveResizeDelta.height, 16)
        
        let currentFontSize: Double = {
            if isResizing, let startFS = resizeStartFontSize, baseElW > 0 {
                let factor = Double(elWidth / max(baseElW, 10))
                return min(max(startFS * factor, 8), 160)
            }
            return element.fontSize
        }()
        
        let effectiveElement: CardElement = {
            var el = element
            el.fontSize = currentFontSize
            return el
        }()
        
        let boundingW = max(elWidth, 36)
        let boundingH = max(elHeight, 20)
        
        ZStack {
            if isInlineEditing && isInteractive && !element.isLocked {
                inlineEditorView(element: effectiveElement, elWidth: elWidth, elHeight: elHeight)
            } else {
                renderElementView(element: effectiveElement, elWidth: elWidth, elHeight: elHeight)
            }
        }
        .frame(width: elWidth > 0 ? elWidth : nil, height: elHeight > 0 ? elHeight : nil)
        .rotationEffect(.degrees(element.rotationDegrees))
        .contentShape(Rectangle())
        .overlay(
            Group {
                if isSelected {
                    localSelectionAndResizeHandles(w: boundingW, h: boundingH, showHandles: isSoleSelection && !element.isLocked)
                } else if isHovering && isInteractive && !element.isLocked {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                        .frame(width: boundingW + 10, height: boundingH + 10)
                        .allowsHitTesting(false)
                }
            }
        )
        .position(x: posX, y: posY)
        .onHover { hovering in
            if isInteractive {
                isHovering = hovering
            }
        }
        .onChange(of: isSelected) { _, selected in
            if !selected {
                isInlineEditing = false
            }
        }
        .onTapGesture(count: 2) {
            if isInteractive && isDirectlyEditable(element.type) && !element.isLocked {
                isInlineEditing = true
            }
        }
        .onTapGesture(count: 1) {
            if isInteractive {
                let isShift = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                onSelect(isShift)
            }
        }
        .gesture(
            isInteractive && !element.isLocked && !isInlineEditing && !isResizing ?
            DragGesture(minimumDistance: 2, coordinateSpace: .global)
                .onChanged { value in
                    let isShift = NSEvent.modifierFlags.contains(.shift) || NSEvent.modifierFlags.contains(.command)
                    if dragStartNormX == nil {
                        dragStartNormX = element.normalizedX
                        dragStartNormY = element.normalizedY
                        if !isSelected {
                            onSelect(isShift)
                        }
                    }
                    let effectiveScale = max(scale, 0.05)
                    let unscaledOffset = CGSize(
                        width: value.translation.width / effectiveScale,
                        height: value.translation.height / effectiveScale
                    )
                    onDragChanged(unscaledOffset)
                }
                .onEnded { value in
                    let effectiveScale = max(scale, 0.05)
                    let finalOffset = CGSize(
                        width: value.translation.width / effectiveScale,
                        height: value.translation.height / effectiveScale
                    )
                    onDragEnded(finalOffset)
                    dragStartNormX = nil
                    dragStartNormY = nil
                    localDragOffset = .zero
                }
            : nil
        )
    }
    
    @ViewBuilder
    private func localSelectionAndResizeHandles(w: CGFloat, h: CGFloat, showHandles: Bool) -> some View {
        let boxW = w + 14
        let boxH = h + 14
        let halfW = boxW / 2.0
        let halfH = boxH / 2.0
        
        ZStack {
            // Bounding Box Stroke (does not intercept clicks)
            RoundedRectangle(cornerRadius: 4)
                .stroke(element.isLocked ? Color.orange : Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                .frame(width: boxW, height: boxH)
                .allowsHitTesting(false)
            
            if element.isLocked {
                // Lock indicator badge in top-right
                Image(systemName: "lock.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(3)
                    .background(Color.orange)
                    .clipShape(Circle())
                    .offset(x: halfW, y: -halfH)
                    .shadow(radius: 2)
                    .allowsHitTesting(false)
            } else if showHandles {
                // 1. Top-Left (NW)
                resizeHandleView(isCircle: true)
                    .offset(x: -halfW, y: -halfH)
                    .gesture(makeResizeGesture(axisX: -1, axisY: -1))
                
                // 2. Top-Right (NE)
                resizeHandleView(isCircle: true)
                    .offset(x: halfW, y: -halfH)
                    .gesture(makeResizeGesture(axisX: 1, axisY: -1))
                
                // 3. Bottom-Left (SW)
                resizeHandleView(isCircle: true)
                    .offset(x: -halfW, y: halfH)
                    .gesture(makeResizeGesture(axisX: -1, axisY: 1))
                
                // 4. Bottom-Right (SE)
                resizeHandleView(isCircle: true)
                    .offset(x: halfW, y: halfH)
                    .gesture(makeResizeGesture(axisX: 1, axisY: 1))
                
                // 5. Middle-Left (W) Handle
                resizeHandleView(isCircle: false)
                    .offset(x: -halfW, y: 0)
                    .gesture(makeResizeGesture(axisX: -1, axisY: 0))
                
                // 6. Middle-Right (E) Handle
                resizeHandleView(isCircle: false)
                    .offset(x: halfW, y: 0)
                    .gesture(makeResizeGesture(axisX: 1, axisY: 0))
            }
        }
        .frame(width: boxW, height: boxH)
        .zIndex(999)
    }
    
    private func resizeHandleView(isCircle: Bool = true) -> some View {
        ZStack {
            Color.clear
                .frame(width: 24, height: 24)
            
            if isCircle {
                Circle()
                    .fill(Color.white)
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.accentColor, lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.white)
                    .frame(width: 8, height: 14)
                    .overlay(RoundedRectangle(cornerRadius: 2).stroke(Color.accentColor, lineWidth: 2))
                    .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    private func makeResizeGesture(axisX: CGFloat, axisY: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if !isResizing {
                    isResizing = true
                    resizeStartNormW = element.normalizedWidth
                    resizeStartNormH = element.normalizedHeight
                    resizeStartFontSize = element.fontSize
                }
                
                let effectiveScale = max(scale, 0.05)
                let deltaW = (value.translation.width / effectiveScale) * axisX * 2.0
                let deltaH = (value.translation.height / effectiveScale) * axisY * 2.0
                
                liveResizeDelta = CGSize(
                    width: axisX != 0 ? deltaW : 0,
                    height: axisY != 0 ? deltaH : 0
                )
            }
            .onEnded { value in
                let effectiveScale = max(scale, 0.05)
                let finalDeltaW = (value.translation.width / effectiveScale) * axisX * 2.0
                let finalDeltaH = (value.translation.height / effectiveScale) * axisY * 2.0
                
                if let startW = resizeStartNormW, let startH = resizeStartNormH {
                    let baseW = CGFloat(startW) * cardWidth
                    let baseH = CGFloat(startH) * cardHeight
                    
                    let newPixelW = max(baseW + (axisX != 0 ? finalDeltaW : 0), 24)
                    let newPixelH = max(baseH + (axisY != 0 ? finalDeltaH : 0), 16)
                    
                    let finalNormW = Double(newPixelW / cardWidth)
                    let finalNormH = Double(newPixelH / cardHeight)
                    
                    let finalFontSize: Double? = {
                        if let startFS = resizeStartFontSize, baseW > 0 {
                            let factor = Double(newPixelW / max(baseW, 10))
                            return min(max(startFS * factor, 8), 160)
                        }
                        return nil
                    }()
                    
                    onResize?(finalNormW, finalNormH, finalFontSize)
                }
                
                isResizing = false
                resizeStartNormW = nil
                resizeStartNormH = nil
                resizeStartFontSize = nil
                liveResizeDelta = .zero
            }
    }
    
    private func isDirectlyEditable(_ type: ElementType) -> Bool {
        switch type {
        case .callsign, .address, .text, .locationFooter:
            return true
        default:
            return false
        }
    }
    
    @ViewBuilder
    private func inlineEditorView(element: CardElement, elWidth: CGFloat, elHeight: CGFloat) -> some View {
        switch element.type {
        case .callsign:
            TextField("Callsign", text: Binding(
                get: { element.textContent.isEmpty ? (settings.myCallsign.isEmpty ? "N0CALL" : settings.myCallsign) : element.textContent },
                set: { onTextChanged($0) }
            ))
            .font(getFont(element: element))
            .textFieldStyle(.plain)
            .multilineTextAlignment(.center)
            .padding(4)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
            .cornerRadius(4)
            .focused($isInlineFieldFocused)
            .onAppear { isInlineFieldFocused = true }
            .onSubmit { isInlineEditing = false }
            
        case .address, .text, .locationFooter:
            TextField("Text", text: Binding(
                get: { element.textContent },
                set: { onTextChanged($0) }
            ))
            .font(getFont(element: element))
            .textFieldStyle(.plain)
            .multilineTextAlignment(element.textAlignment == "center" ? .center : (element.textAlignment == "right" ? .trailing : .leading))
            .padding(4)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.9))
            .cornerRadius(4)
            .focused($isInlineFieldFocused)
            .onAppear { isInlineFieldFocused = true }
            .onSubmit { isInlineEditing = false }
            
        default:
            renderElementView(element: element, elWidth: elWidth, elHeight: elHeight)
        }
    }
    
    @ViewBuilder
    private func renderElementView(element: CardElement, elWidth: CGFloat, elHeight: CGFloat) -> some View {
        switch element.type {
        case .callsign:
            CallsignElementView(element: element, myCallsign: settings.myCallsign)
        case .address:
            AddressElementView(element: element, myAddress: settings.fullMyAddress)
        case .table:
            TableElementView(
                element: element,
                qso: qso,
                defaultComment: settings.defaultComment,
                dateOrder: settings.dateOrder,
                dateSeparator: settings.dateSeparator,
                dateHeaderStyle: settings.dateHeaderStyle,
                tableWidth: elWidth
            )
        case .locationFooter:
            LocationFooterView(element: element, settings: settings, qso: qso)
        case .sticker:
            StickerElementView(stickerType: element.stickerType, customImagePath: element.customImagePath)
        case .text:
            renderCustomText(element: element)
        }
    }
    
    @ViewBuilder
    private func renderCustomText(element: CardElement) -> some View {
        let activeQSO = qso ?? QSO()
        let rendered = EmailTemplateEngine.render(template: element.textContent, qso: activeQSO, settings: settings)
        Text(rendered)
            .font(getFont(element: element))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(element.textAlignment == "center" ? .center : (element.textAlignment == "right" ? .trailing : .leading))
            .shadow(
                color: element.isShadowEnabled ? Color(hex: element.shadowColorHex).opacity(element.shadowOpacity) : .clear,
                radius: CGFloat(element.shadowRadius),
                x: CGFloat(element.shadowX),
                y: CGFloat(element.shadowY)
            )
    }
    
    private func getFont(element: CardElement) -> Font {
        let size = CGFloat(element.fontSize)
        var f: Font
        switch element.fontName {
        case "System Serif": f = .system(size: size, design: .serif)
        case "System Mono": f = .system(size: size, design: .monospaced)
        case "System Rounded": f = .system(size: size, design: .rounded)
        case "System Default": f = .system(size: size, design: .default)
        default: f = .custom(element.fontName, size: size)
        }
        if element.isBold && element.isItalic {
            return f.bold().italic()
        } else if element.isBold {
            return f.bold()
        } else if element.isItalic {
            return f.italic()
        }
        return f
    }
}
