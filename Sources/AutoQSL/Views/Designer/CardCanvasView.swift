import SwiftUI
import AppKit

public struct CardCanvasView: View {
    public let template: QSLCardTemplate
    public let settings: AppSettings
    public let qso: QSO?
    public let isInteractive: Bool
    @Binding public var selectedElementId: UUID?
    public var onElementMoved: ((UUID, Double, Double) -> Void)?
    
    public init(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO? = nil,
        isInteractive: Bool = false,
        selectedElementId: Binding<UUID?> = .constant(nil),
        onElementMoved: ((UUID, Double, Double) -> Void)? = nil
    ) {
        self.template = template
        self.settings = settings
        self.qso = qso
        self.isInteractive = isInteractive
        self._selectedElementId = selectedElementId
        self.onElementMoved = onElementMoved
    }
    
    public var body: some View {
        GeometryReader { geo in
            let cardWidth = geo.size.width
            let cardHeight = geo.size.height
            
            ZStack {
                // 1. Background Layer
                backgroundLayer(width: cardWidth, height: cardHeight)
                
                // 2. Elements Layers ordered by zIndex
                ForEach(template.elements.sorted(by: { $0.zIndex < $1.zIndex })) { element in
                    if element.isVisible {
                        DraggableElementWrapperView(
                            element: element,
                            settings: settings,
                            qso: qso,
                            cardWidth: cardWidth,
                            cardHeight: cardHeight,
                            isInteractive: isInteractive,
                            isSelected: isInteractive && (selectedElementId == element.id),
                            onSelect: {
                                selectedElementId = element.id
                            },
                            onMove: { newNormX, newNormY in
                                onElementMoved?(element.id, newNormX, newNormY)
                            }
                        )
                    }
                }
            }
            .frame(width: cardWidth, height: cardHeight)
            .coordinateSpace(name: "CardCanvas")
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                if isInteractive {
                    selectedElementId = nil
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
            if let bgPath = template.backgroundImagePath, let nsImage = NSImage(contentsOfFile: bgPath) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: template.backgroundFit == .fill ? .fill : (template.backgroundFit == .fit ? .fit : .fill))
                    .frame(width: width, height: height)
                    .clipped()
            } else if let bundledBg = Bundle.module.url(forResource: "default_background", withExtension: "jpg"),
                      let nsImage = NSImage(contentsOf: bundledBg) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: width, height: height)
                    .clipped()
            }
            
            // Darken / Tint Overlay
            if template.backgroundDarkenOpacity > 0 {
                Color.black.opacity(template.backgroundDarkenOpacity)
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
    public let isInteractive: Bool
    public let isSelected: Bool
    public let onSelect: () -> Void
    public let onMove: (Double, Double) -> Void
    
    @State private var dragStartNormX: Double? = nil
    @State private var dragStartNormY: Double? = nil
    @State private var currentDragOffset: CGSize = .zero
    @State private var isHovering: Bool = false
    
    public var body: some View {
        let posX = (CGFloat(element.normalizedX) * cardWidth) + currentDragOffset.width
        let posY = (CGFloat(element.normalizedY) * cardHeight) + currentDragOffset.height
        let elWidth = CGFloat(element.normalizedWidth) * cardWidth
        let elHeight = CGFloat(element.normalizedHeight) * cardHeight
        
        ZStack {
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
                    .shadow(
                        color: Color(hex: element.shadowColorHex).opacity(element.shadowOpacity),
                        radius: CGFloat(element.shadowRadius),
                        x: CGFloat(element.shadowX),
                        y: CGFloat(element.shadowY)
                    )
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
                        .frame(width: elWidth + 12, height: elHeight + 12)
                        .position(x: posX, y: posY)
                } else if isHovering && isInteractive && !element.isLocked {
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.accentColor.opacity(0.4), lineWidth: 1)
                        .frame(width: elWidth + 8, height: elHeight + 8)
                        .position(x: posX, y: posY)
                }
            }
        )
        .onHover { hovering in
            if isInteractive {
                isHovering = hovering
            }
        }
        .gesture(
            isInteractive && !element.isLocked ?
            DragGesture(coordinateSpace: .named("CardCanvas"))
                .onChanged { value in
                    if dragStartNormX == nil {
                        dragStartNormX = element.normalizedX
                        dragStartNormY = element.normalizedY
                        onSelect()
                    }
                    currentDragOffset = value.translation
                }
                .onEnded { value in
                    if let startX = dragStartNormX, let startY = dragStartNormY {
                        let finalNormX = min(max(startX + Double(value.translation.width / cardWidth), 0.02), 0.98)
                        let finalNormY = min(max(startY + Double(value.translation.height / cardHeight), 0.02), 0.98)
                        onMove(finalNormX, finalNormY)
                    }
                    currentDragOffset = .zero
                    dragStartNormX = nil
                    dragStartNormY = nil
                }
            : nil
        )
        .simultaneousGesture(
            TapGesture().onEnded {
                if isInteractive {
                    onSelect()
                }
            }
        )
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
