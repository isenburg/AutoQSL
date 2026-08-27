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
        template.backgroundColorHex = "#EDEDED"
        template.backgroundImagePath = nil
        
        // 1. Top-Left ARRL Badge
        let arrlBadge = CardElement(
            type: .sticker,
            name: "ARRL Badge",
            normalizedX: 0.12,
            normalizedY: 0.18,
            normalizedWidth: 0.08,
            normalizedHeight: 0.22,
            zIndex: 10,
            stickerType: .arrl
        )
        
        // 2. Callsign (Gold 3D Extruded, Centered Top)
        let callsignElement = CardElement(
            type: .callsign,
            name: "My Callsign",
            normalizedX: 0.52,
            normalizedY: 0.18,
            normalizedWidth: 0.38,
            normalizedHeight: 0.15,
            zIndex: 12,
            textContent: myCall.isEmpty ? "DJ6GI" : myCall,
            fontName: "Helvetica",
            fontSize: 76,
            isBold: true,
            textColorHex: "#FFB800",
            secondaryColorHex: "#DDAA00",
            effectType: .metallicGold,
            shadowRadius: 5,
            shadowX: 3,
            shadowY: 4,
            shadowColorHex: "#000000",
            shadowOpacity: 0.8,
            isShadowEnabled: true
        )
        
        // 3. Address Block (Centered Middle below Callsign)
        let addressText = (myAddress != nil && !myAddress!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ? myAddress!
            : "Max Hamradioop\nAntennenstrasse 5\n12345 Mastdorf\nGermany"
            
        let addressElement = CardElement(
            type: .address,
            name: "Address Block",
            normalizedX: 0.52,
            normalizedY: 0.38,
            normalizedWidth: 0.39,
            normalizedHeight: 0.20,
            zIndex: 11,
            textContent: addressText,
            fontName: "Helvetica",
            fontSize: 20,
            isBold: false,
            textAlignment: "left",
            textColorHex: "#000000",
            effectType: .standard,
            shadowRadius: 2,
            shadowX: 0,
            shadowY: 1,
            shadowColorHex: "#FFFFFF",
            shadowOpacity: 0.7,
            isShadowEnabled: true
        )
        
        // 4. QSO Confirmation Table (Centered Bottom)
        var tableElement = CardElement(
            type: .table,
            name: "Confirmation Table",
            normalizedX: 0.50,
            normalizedY: 0.72,
            normalizedWidth: 0.82,
            normalizedHeight: 0.20,
            zIndex: 20,
            fontSize: 15,
            textColorHex: "#000000",
            isShadowEnabled: true,
            tableBorderColorHex: "#000000",
            tableBorderWidth: 1.5,
            tableBackgroundColorHex: "#FFFFFF",
            tableBackgroundOpacity: 1.0,
            tableHeaderBackgroundHex: "#D8D8D8",
            tableHeaderBackgroundOpacity: 1.0,
            tableComment: "73, Thanks for the QSO. I hope to meet you further down the log."
        )
        tableElement.tableHeaderTextColorHex = "#000000"
        tableElement.tableHeaderFontName = "Helvetica"
        tableElement.tableHeaderFontSize = 15
        tableElement.tableHeaderIsBold = true
        tableElement.shadowRadius = 10
        tableElement.shadowX = 0
        tableElement.shadowY = 6
        tableElement.shadowColorHex = "#000000"
        tableElement.shadowOpacity = 0.7
        
        // 5. Location Footer (Centered Below Table)
        let footerElement = CardElement(
            type: .locationFooter,
            name: "Location / Zones Line",
            normalizedX: 0.50,
            normalizedY: 0.84,
            normalizedWidth: 0.70,
            normalizedHeight: 0.05,
            zIndex: 15,
            textContent: "ITU: {MY_ITU} CQ: {MY_CQ} Grid: {MY_GRID}",
            fontName: "Helvetica",
            fontSize: 14,
            isBold: true,
            textAlignment: "center",
            textColorHex: "#000000",
            effectType: .standard,
            isShadowEnabled: false
        )
        
        template.elements = [callsignElement, arrlBadge, addressElement, tableElement, footerElement]
        return template
    }
}
