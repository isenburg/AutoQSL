import SwiftUI

public struct LocationFooterView: View {
    public let element: CardElement
    public let settings: AppSettings
    public let qso: QSO?
    
    public init(element: CardElement, settings: AppSettings, qso: QSO?) {
        self.element = element
        self.settings = settings
        self.qso = qso
    }
    
    private var renderedText: String {
        let raw = element.textContent.isEmpty ? "ITU: {MY_ITU} CQ: {MY_CQ} Grid: {MY_GRID} {MY_COUNTY}" : element.textContent
        let activeQSO = qso ?? QSO()
        return EmailTemplateEngine.render(template: raw, qso: activeQSO, settings: settings)
    }
    
    public var body: some View {
        Text(renderedText)
            .font(resolveFont())
            .foregroundColor(Color(hex: element.textColorHex))
            .shadow(
                color: element.isShadowEnabled ? Color(hex: element.shadowColorHex).opacity(element.shadowOpacity) : .clear,
                radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) : 0,
                x: element.isShadowEnabled ? CGFloat(element.shadowX) : 0,
                y: element.isShadowEnabled ? CGFloat(element.shadowY) : 0
            )
    }
    
    private func resolveFont() -> Font {
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
