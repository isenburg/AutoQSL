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
    public var onElementTextChanged: ((UUID, String) -> Void)?
    
    public init(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO? = nil,
        isInteractive: Bool = false,
        selectedElementId: Binding<UUID?> = .constant(nil),
        onElementMoved: ((UUID, Double, Double) -> Void)? = nil,
        onElementTextChanged: ((UUID, String) -> Void)? = nil
    ) {
        self.template = template
        self.settings = settings
        self.qso = qso
        self.isInteractive = isInteractive
        self._selectedElementId = selectedElementId
        self.onElementMoved = onElementMoved
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
    public let onTextChanged: (String) -> Void
    
    @State private var dragStartNormX: Double? = nil
    @State private var dragStartNormY: Double? = nil
    @State private var currentDragOffset: CGSize = .zero
    @State private var isHovering: Bool = false
    @State private var isInlineEditing: Bool = false
    @FocusState private var isInlineFieldFocused: Bool
    
    public var body: some View {
        let posX = (CGFloat(element.normalizedX) * cardWidth) + currentDragOffset.width
        let posY = (CGFloat(element.normalizedY) * cardHeight) + currentDragOffset.height
        let elWidth = CGFloat(element.normalizedWidth) * cardWidth
        let elHeight = CGFloat(element.normalizedHeight) * cardHeight
        
        ZStack {
            if isInlineEditing && isInteractive && !element.isLocked {
                inlineEditorView(elWidth: elWidth, elHeight: elHeight)
            } else {
                renderElementView(elWidth: elWidth, elHeight: elHeight)
            }
        }
        .frame(width: elWidth > 0 ? elWidth : nil, height: elHeight > 0 ? elHeight : nil)
        .rotationEffect(.degrees(element.rotationDegrees))
        .contentShape(Rectangle())
        .position(x: posX, y: posY)
        .overlay(
            Group {
                if isSelected {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                        .frame(width: max(elWidth, 40) + 12, height: max(elHeight, 24) + 12)
                        .position(x: posX, y: posY)
                } else if isHovering && isInteractive && !element.isLocked {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                        .frame(width: max(elWidth, 40) + 8, height: max(elHeight, 24) + 8)
                        .position(x: posX, y: posY)
                }
            }
        )
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
        .gesture(
            isInteractive && !element.isLocked && !isInlineEditing ?
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
        .simultaneousGesture(
            TapGesture(count: 2).onEnded {
                if isInteractive && isDirectlyEditable(element.type) && !element.isLocked {
                    isInlineEditing = true
                }
            }
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if isInteractive {
                    onSelect()
                }
            }
        )
    }
    
    private func isDirectlyEditable(_ type: ElementType) -> Bool {
        return type == .callsign || type == .address || type == .text || type == .locationFooter
    }
    
    @ViewBuilder
    private func inlineEditorView(elWidth: CGFloat, elHeight: CGFloat) -> some View {
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
            renderElementView(elWidth: elWidth, elHeight: elHeight)
        }
    }
    
    @ViewBuilder
    private func renderElementView(elWidth: CGFloat, elHeight: CGFloat) -> some View {
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
        default: f = .system(size: size)
        }
        if element.isBold { f = f.bold() }
        if element.isItalic { f = f.italic() }
        return f
    }
}
