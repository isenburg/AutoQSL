import Foundation

public enum CardAspectRatio: String, Codable, CaseIterable {
    case standardQSL = "Standard QSL (3.5\" x 5.5\" / 140x90mm)"
    case classic4x6 = "Postcard (4\" x 6\")"
    case widescreen16x9 = "Widescreen (16:9)"
    
    public var widthPoints: Double {
        switch self {
        case .standardQSL: return 880.0
        case .classic4x6: return 900.0
        case .widescreen16x9: return 960.0
        }
    }
    
    public var heightPoints: Double {
        switch self {
        case .standardQSL: return 560.0
        case .classic4x6: return 600.0
        case .widescreen16x9: return 540.0
        }
    }
    
    public var aspectRatio: Double {
        return widthPoints / heightPoints
    }
}

public enum BackgroundFit: String, Codable, CaseIterable {
    case fill = "Fill / Crop"
    case fit = "Fit"
    case stretch = "Stretch"
}

public struct QSLCardTemplate: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var isDefault: Bool
    public var aspectRatio: CardAspectRatio
    
    // Background
    public var backgroundImagePath: String?
    public var backgroundFit: BackgroundFit
    public var backgroundColorHex: String
    public var backgroundDarkenOpacity: Double
    
    // Elements on the card
    public var elements: [CardElement]
    
    public init(
        id: UUID = UUID(),
        name: String = "Default QSL Card",
        isDefault: Bool = true,
        aspectRatio: CardAspectRatio = .standardQSL,
        backgroundImagePath: String? = nil,
        backgroundFit: BackgroundFit = .fill,
        backgroundColorHex: String = "#E8E8E8",
        backgroundDarkenOpacity: Double = 0.0,
        elements: [CardElement] = []
    ) {
        self.id = id
        self.name = name
        self.isDefault = isDefault
        self.aspectRatio = aspectRatio
        self.backgroundImagePath = backgroundImagePath
        self.backgroundFit = backgroundFit
        self.backgroundColorHex = backgroundColorHex
        self.backgroundDarkenOpacity = backgroundDarkenOpacity
        self.elements = elements
    }
    
    public static func createDefaultTemplate(myCall: String = "DJ6GI", myAddress: String? = nil) -> QSLCardTemplate {
        var template = QSLCardTemplate(name: "Standard Landscape QSL", isDefault: true)
        template.backgroundColorHex = "#E8E8E8"
        template.backgroundImagePath = nil
        
        // 1. Callsign (Gold 3D Extruded)
        let callsignElement = CardElement(
            type: .callsign,
            name: "My Callsign",
            normalizedX: 0.32,
            normalizedY: 0.12,
            normalizedWidth: 0.40,
            normalizedHeight: 0.14,
            zIndex: 10,
            textContent: myCall.isEmpty ? "DJ6GI" : myCall,
            fontName: "Impact",
            fontSize: 68,
            isBold: true,
            textColorHex: "#F2BB05",
            secondaryColorHex: "#D4A373",
            effectType: .metallicGold,
            shadowRadius: 6,
            shadowX: 4,
            shadowY: 5,
            shadowColorHex: "#000000",
            shadowOpacity: 0.85
        )
        
        // 2. ARRL Badge
        let arrlBadge = CardElement(
            type: .sticker,
            name: "ARRL Badge",
            normalizedX: 0.46,
            normalizedY: 0.15,
            normalizedWidth: 0.10,
            normalizedHeight: 0.20,
            zIndex: 11,
            stickerType: .arrl
        )
        
        // 3. Address Block
        let addressText = (myAddress != nil && !myAddress!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ? myAddress!
            : "Max Mustermann\nMusterstraße 123\n12345 Musterstadt\nGermany"
            
        let addressElement = CardElement(
            type: .address,
            name: "Address Block",
            normalizedX: 0.28,
            normalizedY: 0.28,
            normalizedWidth: 0.36,
            normalizedHeight: 0.20,
            zIndex: 9,
            textContent: addressText,
            fontName: "Helvetica",
            fontSize: 20,
            isBold: false,
            textAlignment: "left",
            textColorHex: "#000000",
            effectType: .bevel3D,
            shadowRadius: 2,
            shadowX: 1,
            shadowY: 1,
            shadowColorHex: "#FFFFFF",
            shadowOpacity: 0.7
        )
        
        // 4. QSO Confirmation Table
        let tableElement = CardElement(
            type: .table,
            name: "Confirmation Table",
            normalizedX: 0.50,
            normalizedY: 0.85,
            normalizedWidth: 0.85,
            normalizedHeight: 0.18,
            zIndex: 20,
            fontSize: 16,
            textColorHex: "#000000",
            tableBorderColorHex: "#111111",
            tableBorderWidth: 1.5,
            tableBackgroundColorHex: "#FFFFFF",
            tableBackgroundOpacity: 0.98,
            tableComment: "73, Thanks for the QSO. I hope to meet you further down the log."
        )
        
        // 5. Location Footer
        let footerElement = CardElement(
            type: .locationFooter,
            name: "Location / Zones Line",
            normalizedX: 0.50,
            normalizedY: 0.96,
            normalizedWidth: 0.75,
            normalizedHeight: 0.05,
            zIndex: 15,
            textContent: "ITU: {MY_ITU} CQ: {MY_CQ} Grid: {MY_GRID} {MY_COUNTY}",
            fontName: "Helvetica",
            fontSize: 16,
            isBold: true,
            textAlignment: "center",
            textColorHex: "#111111",
            effectType: .bevel3D,
            shadowRadius: 1,
            shadowX: 1,
            shadowY: 1,
            shadowColorHex: "#FFFFFF",
            shadowOpacity: 0.8
        )
        
        template.elements = [callsignElement, arrlBadge, addressElement, tableElement, footerElement]
        return template
    }
}
