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
    
    // 1. Standard Landscape QSL
    public static func createDefaultTemplate(myCall: String = "DJ6GI", myAddress: String? = nil) -> QSLCardTemplate {
        var template = QSLCardTemplate(name: "Standard Landscape QSL", isDefault: true)
        template.backgroundColorHex = "#EDEDED"
        template.backgroundImagePath = nil
        
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
        
        let addressText = (myAddress != nil && !myAddress!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ? myAddress!
            : "Georg Isenbürger\nHeeresfliegerstrasse 16\nHohenlockstedt, SH\nGermany"
            
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
    
    // 2. DJ6GI Sonnenuntergang QSL
    public static func createSonnenuntergangTemplate(myCall: String = "DJ6GI", myAddress: String? = nil) -> QSLCardTemplate {
        var template = QSLCardTemplate(name: "DJ6GI Sonnenuntergang QSL", isDefault: false)
        template.backgroundImagePath = "/Users/gi/Dropbox/300 AFU/Software/AutoQSL/Sources/AutoQSL/Resources/default_background.jpg"
        template.backgroundFit = .fill
        template.backgroundColorHex = "#0A0E17"
        template.backgroundDarkenOpacity = 0.0
        
        var badge1 = CardElement(type: .sticker, name: "Pilots on the Air", normalizedX: 0.078, normalizedY: 0.512, normalizedWidth: 0.102, normalizedHeight: 0.18, zIndex: 5, stickerType: .custom)
        badge1.customImagePath = "/Users/gi/Library/Mobile Documents/com~apple~CloudDocs/AutoQSL/Badges/D462F951-7EF9-49E9-9CB9-DEE9D4A1746F.png"
        
        var badge2 = CardElement(type: .sticker, name: "Airfields on the Air EDHF", normalizedX: 0.078, normalizedY: 0.706, normalizedWidth: 0.102, normalizedHeight: 0.18, zIndex: 5, stickerType: .custom)
        badge2.customImagePath = "/Users/gi/Library/Mobile Documents/com~apple~CloudDocs/AutoQSL/Badges/132A514F-264E-4606-BCE4-8299781C9DF0.png"
        
        let callsign = CardElement(
            type: .callsign,
            name: "My Callsign",
            normalizedX: 0.65,
            normalizedY: 0.18,
            normalizedWidth: 0.38,
            normalizedHeight: 0.15,
            zIndex: 12,
            textContent: myCall.isEmpty ? "DJ6GI" : myCall,
            fontName: "Impact",
            fontSize: 72,
            isBold: true,
            textColorHex: "#FFC000",
            secondaryColorHex: "#DAA520",
            effectType: .metallicGold,
            shadowRadius: 5,
            shadowX: 3,
            shadowY: 4,
            shadowColorHex: "#000000",
            shadowOpacity: 0.85,
            isShadowEnabled: true
        )
        
        let addressText = (myAddress != nil && !myAddress!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ? myAddress!
            : "Georg Isenbürger\nHeeresfliegerstrasse 16\nHohenlockstedt, SH\nGermany"
            
        let address = CardElement(
            type: .address,
            name: "Address Block",
            normalizedX: 0.65,
            normalizedY: 0.38,
            normalizedWidth: 0.38,
            normalizedHeight: 0.20,
            zIndex: 10,
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
        
        var table = CardElement(
            type: .table,
            name: "Confirmation Table",
            normalizedX: 0.50,
            normalizedY: 0.72,
            normalizedWidth: 0.82,
            normalizedHeight: 0.20,
            zIndex: 20,
            fontSize: 15,
            textColorHex: "#FFFFFF",
            isShadowEnabled: true,
            tableBorderColorHex: "#FFFFFF",
            tableBorderWidth: 1.2,
            tableBackgroundColorHex: "#000000",
            tableBackgroundOpacity: 0.45,
            tableHeaderBackgroundHex: "#000000",
            tableHeaderBackgroundOpacity: 0.6,
            tableComment: "73's, Thanks for the QSO"
        )
        table.tableHeaderTextColorHex = "#FFFFFF"
        table.tableHeaderFontName = "Helvetica"
        table.tableHeaderFontSize = 14
        table.tableHeaderIsBold = true
        table.tableCallsignHeader = "Confirming QSO with"
        table.tableDateHeader = "Date (D.M.Y)"
        table.tableTimeHeader = "UTC"
        table.tableFreqHeader = "Frequency"
        table.tableFreqDisplayMode = .freqOnly
        table.shadowRadius = 6
        table.shadowX = 0
        table.shadowY = 3
        table.shadowColorHex = "#000000"
        table.shadowOpacity = 0.7
        
        let footer = CardElement(
            type: .locationFooter,
            name: "Location / Zones Line",
            normalizedX: 0.50,
            normalizedY: 0.85,
            normalizedWidth: 0.70,
            normalizedHeight: 0.05,
            zIndex: 15,
            textContent: "ITU: {MY_ITU}    CQ: {MY_CQ}    Grid: {MY_GRID}",
            fontName: "Helvetica",
            fontSize: 14,
            isBold: true,
            textAlignment: "center",
            textColorHex: "#FFFFFF",
            effectType: .standard,
            shadowRadius: 3,
            shadowX: 1,
            shadowY: 1,
            shadowColorHex: "#000000",
            shadowOpacity: 0.8,
            isShadowEnabled: true
        )
        
        let textNote = CardElement(
            type: .text,
            name: "Footer Note",
            normalizedX: 0.72,
            normalizedY: 0.88,
            normalizedWidth: 0.40,
            normalizedHeight: 0.04,
            zIndex: 15,
            textContent: "automatically sent with AutoQSL by DJ6GI",
            fontName: "Helvetica",
            fontSize: 12,
            isBold: true,
            textAlignment: "right",
            textColorHex: "#FFB703",
            effectType: .standard,
            shadowRadius: 2,
            shadowX: 1,
            shadowY: 1,
            shadowColorHex: "#000000",
            shadowOpacity: 0.8,
            isShadowEnabled: true
        )
        
        template.elements = [badge1, badge2, callsign, address, table, footer, textNote]
        return template
    }
    
    // 3. DJ6GI Bonanza
    public static func createBonanzaTemplate(myCall: String = "DJ6GI", myAddress: String? = nil) -> QSLCardTemplate {
        var template = QSLCardTemplate(name: "DJ6GI Bonanza", isDefault: false)
        template.backgroundImagePath = "/Users/gi/Dropbox/300 AFU/Software/AutoQSL/Website/assets/hero-card.png"
        template.backgroundFit = .fill
        template.backgroundColorHex = "#0A0E17"
        template.backgroundDarkenOpacity = 0.0
        
        let callsign = CardElement(
            type: .callsign,
            name: "My Callsign",
            normalizedX: 0.65,
            normalizedY: 0.18,
            normalizedWidth: 0.38,
            normalizedHeight: 0.15,
            zIndex: 12,
            textContent: myCall.isEmpty ? "DJ6GI" : myCall,
            fontName: "Impact",
            fontSize: 74,
            isBold: true,
            textColorHex: "#FFC000",
            secondaryColorHex: "#DAA520",
            effectType: .metallicGold,
            shadowRadius: 5,
            shadowX: 3,
            shadowY: 4,
            shadowColorHex: "#000000",
            shadowOpacity: 0.85,
            isShadowEnabled: true
        )
        
        let addressText = (myAddress != nil && !myAddress!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ? myAddress!
            : "Georg Isenbürger\nHeeresfliegerstrasse 16\nHohenlockstedt, SH\nGermany"
            
        let address = CardElement(
            type: .address,
            name: "Address Block",
            normalizedX: 0.65,
            normalizedY: 0.38,
            normalizedWidth: 0.38,
            normalizedHeight: 0.20,
            zIndex: 10,
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
        
        var table = CardElement(
            type: .table,
            name: "Confirmation Table",
            normalizedX: 0.50,
            normalizedY: 0.72,
            normalizedWidth: 0.82,
            normalizedHeight: 0.20,
            zIndex: 20,
            fontSize: 15,
            textColorHex: "#FFFFFF",
            isShadowEnabled: true,
            tableBorderColorHex: "#FFFFFF",
            tableBorderWidth: 1.2,
            tableBackgroundColorHex: "#000000",
            tableBackgroundOpacity: 0.45,
            tableHeaderBackgroundHex: "#000000",
            tableHeaderBackgroundOpacity: 0.6,
            tableComment: "73, Thanks for the QSO."
        )
        table.tableHeaderTextColorHex = "#FFFFFF"
        table.tableHeaderFontName = "Helvetica"
        table.tableHeaderFontSize = 14
        table.tableHeaderIsBold = true
        table.tableCallsignHeader = "Confirming QSO with"
        table.tableDateHeader = "Date"
        table.tableTimeHeader = "UTC"
        table.tableFreqHeader = "Frequency"
        table.tableFreqDisplayMode = .freqOnly
        table.shadowRadius = 6
        table.shadowX = 0
        table.shadowY = 3
        table.shadowColorHex = "#000000"
        table.shadowOpacity = 0.7
        
        let footer = CardElement(
            type: .locationFooter,
            name: "Location / Zones Line",
            normalizedX: 0.50,
            normalizedY: 0.85,
            normalizedWidth: 0.70,
            normalizedHeight: 0.05,
            zIndex: 15,
            textContent: "ITU: {MY_ITU}    CQ: {MY_CQ}    Grid: {MY_GRID}",
            fontName: "Helvetica",
            fontSize: 14,
            isBold: true,
            textAlignment: "center",
            textColorHex: "#FFFFFF",
            effectType: .standard,
            shadowRadius: 3,
            shadowX: 1,
            shadowY: 1,
            shadowColorHex: "#000000",
            shadowOpacity: 0.8,
            isShadowEnabled: true
        )
        
        template.elements = [callsign, address, table, footer]
        return template
    }
    
    public static func defaultBuiltinTemplates(myCall: String = "DJ6GI", myAddress: String? = nil) -> [QSLCardTemplate] {
        return [
            createDefaultTemplate(myCall: myCall, myAddress: myAddress),
            createSonnenuntergangTemplate(myCall: myCall, myAddress: myAddress),
            createBonanzaTemplate(myCall: myCall, myAddress: myAddress)
        ]
    }
}
