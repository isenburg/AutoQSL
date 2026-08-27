import SwiftUI
import AppKit

public let canvasBackgroundSelectionId = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

public struct CardCanvasView: View {
    public let template: QSLCardTemplate
    public let settings: AppSettings
    public let qso: QSO?
    public let isInteractive: Bool
    @Binding public var selectedElementId: UUID?
    public var onElementMoved: ((UUID, Double, Double) -> Void)?
    public var onElementResized: ((UUID, Double, Double, Double?) -> Void)?
    public var onElementTextChanged: ((UUID, String) -> Void)?
    
    public init(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO? = nil,
        isInteractive: Bool = false,
        selectedElementId: Binding<UUID?> = .constant(nil),
        onElementMoved: ((UUID, Double, Double) -> Void)? = nil,
        onElementResized: ((UUID, Double, Double, Double?) -> Void)? = nil,
        onElementTextChanged: ((UUID, String) -> Void)? = nil
    ) {
        self.template = template
        self.settings = settings
        self.qso = qso
        self.isInteractive = isInteractive
        self._selectedElementId = selectedElementId
        self.onElementMoved = onElementMoved
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
                // 1. Background Layer
                backgroundLayer(width: baseWidth, height: baseHeight)
                
                // 2. Elements Layers ordered by zIndex
                ForEach(template.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    if element.isVisible {
                        DraggableElementWrapperView(
                            element: element,
                            settings: settings,
                            qso: qso,
                            cardWidth: baseWidth,
                            cardHeight: baseHeight,
                            scale: scale,
                            isInteractive: isInteractive,
                            isSelected: isInteractive && (selectedElementId == element.id),
                            onSelect: {
                                selectedElementId = element.id
                            },
                            onMove: { newNormX, newNormY in
                                onElementMoved?(element.id, newNormX, newNormY)
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
            }
            .frame(width: baseWidth, height: baseHeight)
            .scaleEffect(scale)
            .frame(width: targetWidth, height: targetHeight)
            .coordinateSpace(name: "CardCanvas")
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                if isInteractive {
                    selectedElementId = canvasBackgroundSelectionId
                }
            }
        }
    }
    
    @ViewBuilder
    private func backgroundLayer(width: CGFloat, height: CGFloat) -> some View {
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
                selectedElementId = canvasBackgroundSelectionId
            }
        }
    }
}

public struct DraggableElementWrapperView: View {
    public let element: CardElement
    public let settings: AppSettings
    public let qso: QSO?
    public let cardWidth: CGFloat
    public let cardHeight: CGFloat
    public let scale: CGFloat
    public let isInteractive: Bool
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onMove: (Double, Double) -> Void
    public let onResize: ((Double, Double, Double?) -> Void)?
    public let onTextChanged: (String) -> Void
    
    @State private var dragStartNormX: Double? = nil
    @State private var dragStartNormY: Double? = nil
    @State private var currentDragOffset: CGSize = .zero
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
        let posX = (CGFloat(element.normalizedX) * cardWidth) + currentDragOffset.width
        let posY = (CGFloat(element.normalizedY) * cardHeight) + currentDragOffset.height
        
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
                    localSelectionAndResizeHandles(w: boundingW, h: boundingH)
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
                onSelect()
            }
        }
        .gesture(
            isInteractive && !element.isLocked && !isInlineEditing && !isResizing ?
            DragGesture(minimumDistance: 1, coordinateSpace: .global)
                .onChanged { value in
                    if dragStartNormX == nil {
                        dragStartNormX = element.normalizedX
                        dragStartNormY = element.normalizedY
                        onSelect()
                    }
                    let effectiveScale = max(scale, 0.05)
                    currentDragOffset = CGSize(
                        width: value.translation.width / effectiveScale,
                        height: value.translation.height / effectiveScale
                    )
                }
                .onEnded { value in
                    let effectiveScale = max(scale, 0.05)
                    let unscaledWidth = value.translation.width / effectiveScale
                    let unscaledHeight = value.translation.height / effectiveScale
                    
                    if let startX = dragStartNormX, let startY = dragStartNormY {
                        let finalNormX = min(max(startX + Double(unscaledWidth / cardWidth), 0.01), 0.99)
                        let finalNormY = min(max(startY + Double(unscaledHeight / cardHeight), 0.01), 0.99)
                        onMove(finalNormX, finalNormY)
                    }
                    currentDragOffset = .zero
                    dragStartNormX = nil
                    dragStartNormY = nil
                }
            : nil
        )
    }
    
    @ViewBuilder
    private func localSelectionAndResizeHandles(w: CGFloat, h: CGFloat) -> some View {
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
            } else {
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
        .frame(width: 24, height: 24)
        .contentShape(Rectangle())
    }
    
    private func makeResizeGesture(axisX: CGFloat, axisY: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 1, coordinateSpace: .global)
            .onChanged { value in
                if resizeStartNormW == nil {
                    resizeStartNormW = element.normalizedWidth
                    resizeStartNormH = element.normalizedHeight
                    resizeStartFontSize = element.fontSize
                    isResizing = true
                }
                let effectiveScale = max(scale, 0.05)
                let deltaX = (value.translation.width / effectiveScale) * axisX
                let deltaY = (value.translation.height / effectiveScale) * (axisY == 0 ? 0 : axisY)
                
                liveResizeDelta = CGSize(width: deltaX, height: deltaY)
            }
            .onEnded { value in
                let effectiveScale = max(scale, 0.05)
                let unscaledW = (value.translation.width / effectiveScale) * axisX
                let unscaledH = (value.translation.height / effectiveScale) * (axisY == 0 ? 0 : axisY)
                
                if let startW = resizeStartNormW, let startH = resizeStartNormH {
                    let finalNormW = min(max(startW + Double(unscaledW / cardWidth), 0.04), 0.98)
                    let finalNormH = min(max(startH + Double(unscaledH / cardHeight), 0.03), 0.98)
                    
                    var newFontSize: Double? = nil
                    if isFontScalable(element.type), let startFS = resizeStartFontSize, startW > 0 {
                        let factor = max((CGFloat(startW) * cardWidth + unscaledW) / max(CGFloat(startW) * cardWidth, 20.0), 0.2)
                        newFontSize = min(max(startFS * Double(factor), 8.0), 160.0)
                    }
                    
                    onResize?(finalNormW, finalNormH, newFontSize)
                }
                
                liveResizeDelta = .zero
                resizeStartNormW = nil
                resizeStartNormH = nil
                resizeStartFontSize = nil
                isResizing = false
            }
    }
    
    private func isFontScalable(_ type: ElementType) -> Bool {
        return type == .callsign || type == .address || type == .text || type == .locationFooter
    }
    
    private func isDirectlyEditable(_ type: ElementType) -> Bool {
        return type == .callsign || type == .address || type == .text || type == .locationFooter
    }
    
    @ViewBuilder
    private func inlineEditorView(element: CardElement, elWidth: CGFloat, elHeight: CGFloat) -> some View {
        switch element.type {
        case .callsign:
            TextField("", text: Binding(
                get: { element.textContent.isEmpty ? settings.myCallsign : element.textContent },
                set: { onTextChanged($0) }
            ))
            .font(resolveCustomTextFont(element: element))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(.center)
            .textFieldStyle(.plain)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.18)).stroke(Color.accentColor, lineWidth: 1.5))
            .focused($isInlineFieldFocused)
            .onSubmit { isInlineEditing = false }
            .onAppear { isInlineFieldFocused = true }
            
        case .address:
            TextEditor(text: Binding(
                get: {
                    if !element.textContent.isEmpty {
                        return element.textContent
                    }
                    return settings.fullMyAddress.isEmpty ? "Max Mustermann\nMusterstraße 123\n12345 Musterstadt\nGermany" : settings.fullMyAddress
                },
                set: { onTextChanged($0) }
            ))
            .font(resolveCustomTextFont(element: element))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(resolveAlignment(element: element))
            .scrollContentBackground(.hidden)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.18)).stroke(Color.accentColor, lineWidth: 1.5))
            .focused($isInlineFieldFocused)
            .onAppear { isInlineFieldFocused = true }
            
        case .locationFooter:
            TextField("", text: Binding(
                get: { element.textContent },
                set: { onTextChanged($0) }
            ))
            .font(resolveCustomTextFont(element: element))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(resolveAlignment(element: element))
            .textFieldStyle(.plain)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.18)).stroke(Color.accentColor, lineWidth: 1.5))
            .focused($isInlineFieldFocused)
            .onSubmit { isInlineEditing = false }
            .onAppear { isInlineFieldFocused = true }
            
        case .text:
            TextField("", text: Binding(
                get: { element.textContent },
                set: { onTextChanged($0) }
            ), axis: .vertical)
            .font(resolveCustomTextFont(element: element))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(resolveAlignment(element: element))
            .textFieldStyle(.plain)
            .padding(4)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.18)).stroke(Color.accentColor, lineWidth: 1.5))
            .focused($isInlineFieldFocused)
            .onSubmit { isInlineEditing = false }
            .onAppear { isInlineFieldFocused = true }
            
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
            TableElementView(element: element, qso: qso, defaultComment: settings.defaultComment, dateOrder: settings.dateOrder, dateSeparator: settings.dateSeparator, dateHeaderStyle: settings.dateHeaderStyle, tableWidth: elWidth)
        case .locationFooter:
            LocationFooterView(element: element, settings: settings, qso: qso)
        case .sticker:
            StickerElementView(stickerType: element.stickerType, customImagePath: element.customImagePath)
        case .text:
            Text(EmailTemplateEngine.render(template: element.textContent, qso: qso ?? QSO(), settings: settings))
                .font(resolveCustomTextFont(element: element))
                .foregroundColor(Color(hex: element.textColorHex))
                .multilineTextAlignment(resolveAlignment(element: element))
                .shadow(
                    color: element.isShadowEnabled ? Color(hex: element.shadowColorHex).opacity(element.shadowOpacity) : .clear,
                    radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) : 0,
                    x: element.isShadowEnabled ? CGFloat(element.shadowX) : 0,
                    y: element.isShadowEnabled ? CGFloat(element.shadowY) : 0
                )
        }
    }
    
    private func resolveAlignment(element: CardElement) -> TextAlignment {
        switch element.textAlignment.lowercased() {
        case "center": return .center
        case "right", "trailing": return .trailing
        default: return .leading
        }
    }
    
    private func resolveCustomTextFont(element: CardElement) -> Font {
        let size = CGFloat(element.fontSize)
        var f: Font
        switch element.fontName {
        case "System": f = .system(size: size)
        case "System Rounded": f = .system(size: size, design: .rounded)
        case "System Serif": f = .system(size: size, design: .serif)
        case "System Monospaced": f = .system(size: size, design: .monospaced)
        case "Helvetica": f = .custom("Helvetica", size: size)
        case "Arial": f = .custom("Arial", size: size)
        case "Impact": f = .custom("Impact", size: size)
        case "Times New Roman": f = .custom("Times New Roman", size: size)
        case "Courier New", "Courier": f = .custom("Courier New", size: size)
        case "Georgia": f = .custom("Georgia", size: size)
        case "Menlo": f = .custom("Menlo", size: size)
        case "Trebuchet MS": f = .custom("Trebuchet MS", size: size)
        default:
            if NSFont(name: element.fontName, size: size) != nil {
                f = .custom(element.fontName, size: size)
            } else {
                f = .system(size: size)
            }
        }
        if element.isBold { f = f.bold() }
        if element.isItalic { f = f.italic() }
        return f
    }
}
