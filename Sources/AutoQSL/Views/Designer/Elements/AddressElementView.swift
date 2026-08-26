import SwiftUI

public struct AddressElementView: View {
    public let element: CardElement
    public let myAddress: String
    
    public init(element: CardElement, myAddress: String) {
        self.element = element
        self.myAddress = myAddress
    }
    
    private var displayText: String {
        let elText = element.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        if !elText.isEmpty {
            return element.textContent
        }
        let addr = myAddress.trimmingCharacters(in: .whitespacesAndNewlines)
        if !addr.isEmpty {
            return myAddress
        }
        return "Max Mustermann\nMusterstraße 123\n12345 Musterstadt\nGermany"
    }
    
    public var body: some View {
        Text(displayText)
            .font(resolveFont())
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(resolveAlignment())
            .lineSpacing(2)
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
    
    private func resolveAlignment() -> TextAlignment {
        switch element.textAlignment.lowercased() {
        case "center": return .center
        case "right": return .trailing
        default: return .leading
        }
    }
}
