import SwiftUI

public struct CallsignElementView: View {
    public let element: CardElement
    public let myCallsign: String
    
    public init(element: CardElement, myCallsign: String) {
        self.element = element
        self.myCallsign = myCallsign
    }
    
    private var displayText: String {
        let text = element.textContent.trimmingCharacters(in: .whitespacesAndNewlines)
        return text.isEmpty ? (myCallsign.isEmpty ? "KG4OJT" : myCallsign) : text
    }
    
    public var body: some View {
        ZStack {
            switch element.effectType {
            case .metallicGold:
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(element.isShadowEnabled ? Color(hex: element.shadowColorHex).opacity(element.shadowOpacity) : .clear)
                    .offset(x: element.isShadowEnabled ? CGFloat(element.shadowX) : 0, y: element.isShadowEnabled ? CGFloat(element.shadowY) : 0)
                    .blur(radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) / 2 : 0)
                
                ForEach(1...3, id: \.self) { i in
                    Text(displayText)
                        .font(resolveFont())
                        .foregroundColor(Color(hex: element.secondaryColorHex))
                        .offset(x: CGFloat(i) * 0.8, y: CGFloat(i) * 1.0)
                }
                
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(Color(hex: element.textColorHex))
                
            case .bevel3D:
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(Color(hex: element.shadowColorHex).opacity(element.shadowOpacity))
                    .offset(x: CGFloat(element.shadowX), y: CGFloat(element.shadowY))
                
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(Color(hex: element.textColorHex))
                
            case .outline:
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(Color(hex: element.textColorHex))
                    .shadow(color: element.isShadowEnabled ? Color(hex: element.shadowColorHex).opacity(element.shadowOpacity) : .clear, radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) : 0, x: element.isShadowEnabled ? CGFloat(element.shadowX) : 0, y: element.isShadowEnabled ? CGFloat(element.shadowY) : 0)
                
            case .glow:
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(Color(hex: element.textColorHex))
                    .shadow(color: element.isShadowEnabled ? Color(hex: element.secondaryColorHex) : .clear, radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) * 2 : 0, x: 0, y: 0)
                    .shadow(color: Color(hex: element.textColorHex), radius: CGFloat(element.shadowRadius), x: 0, y: 0)
                
            case .standard:
                Text(displayText)
                    .font(resolveFont())
                    .foregroundColor(Color(hex: element.textColorHex))
                    .shadow(color: element.isShadowEnabled ? Color(hex: element.shadowColorHex).opacity(element.shadowOpacity) : .clear, radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) : 0, x: element.isShadowEnabled ? CGFloat(element.shadowX) : 0, y: element.isShadowEnabled ? CGFloat(element.shadowY) : 0)
            }
        }
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
