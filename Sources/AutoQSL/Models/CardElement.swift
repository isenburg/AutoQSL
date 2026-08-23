import Foundation
import SwiftUI

public enum ElementType: String, Codable, CaseIterable {
    case callsign = "Callsign"
    case address = "Address Block"
    case table = "QSO Table"
    case locationFooter = "Location Footer"
    case sticker = "Sticker / Badge"
    case text = "Custom Text"
}

public enum TextEffectType: String, Codable, CaseIterable {
    case standard = "Flat"
    case bevel3D = "3D Bevel & Shadow"
    case outline = "Outlined"
    case metallicGold = "Metallic Gold"
    case glow = "Neon Glow"
}

public enum StickerType: String, Codable, CaseIterable {
    case arrl = "ARRL Diamond"
    case pota = "POTA (Parks)"
    case iota = "IOTA (Islands)"
    case sota = "SOTA (Summits)"
    case cq = "CQ Zone / WPX"
    case was = "WAS (Worked All States)"
    case custom = "Custom Image"
}

public enum TableFreqDisplayMode: String, Codable, CaseIterable, Identifiable {
    case bandOnly = "Band (e.g. 20m)"
    case freqOnly = "Frequency MHz (e.g. 14.074 MHz)"
    case bandAndFreq = "Band + Freq (e.g. 20m • 14.074)"
    
    public var id: String { rawValue }
}

public struct CardElement: Identifiable, Codable, Hashable {
    public var id: UUID
    public var type: ElementType
    public var name: String
    public var isVisible: Bool
    public var isLocked: Bool
    
    // Geometry
    public var normalizedX: Double
    public var normalizedY: Double
    public var normalizedWidth: Double
    public var normalizedHeight: Double
    public var rotationDegrees: Double
    public var zIndex: Int
    
    // Typography & Content
    public var textContent: String
    public var fontName: String
    public var fontSize: Double
    public var isBold: Bool
    public var isItalic: Bool
    public var textAlignment: String
    public var textColorHex: String
    public var secondaryColorHex: String
    
    // Visual Effects
    public var effectType: TextEffectType
    public var shadowRadius: Double
    public var shadowX: Double
    public var shadowY: Double
    public var shadowColorHex: String
    public var shadowOpacity: Double
    public var isShadowEnabled: Bool
    
    // Table Specific Settings
    public var tableBorderColorHex: String
    public var tableBorderWidth: Double
    public var tableBackgroundColorHex: String
    public var tableBackgroundOpacity: Double
    public var tableHeaderBackgroundHex: String
    public var tableHeaderBackgroundOpacity: Double
    public var tableComment: String
    
    // Table Columns Configuration
    public var tableShowCallsign: Bool
    public var tableCallsignHeader: String
    public var tableShowDate: Bool
    public var tableDateHeader: String
    public var tableShowTime: Bool
    public var tableTimeHeader: String
    public var tableShowFreq: Bool
    public var tableFreqHeader: String
    public var tableFreqDisplayMode: TableFreqDisplayMode
    public var tableShowRST: Bool
    public var tableRSTHeader: String
    public var tableShowMode: Bool
    public var tableModeHeader: String
    public var tableShowCommentRow: Bool
    
    // Sticker Specific Settings
    public var stickerType: StickerType
    public var customImagePath: String?
    public var stickerTintHex: String?
    
    public init(
        id: UUID = UUID(),
        type: ElementType,
        name: String,
        isVisible: Bool = true,
        isLocked: Bool = false,
        normalizedX: Double,
        normalizedY: Double,
        normalizedWidth: Double,
        normalizedHeight: Double,
        rotationDegrees: Double = 0,
        zIndex: Int = 0,
        textContent: String = "",
        fontName: String = "System",
        fontSize: Double = 24,
        isBold: Bool = true,
        isItalic: Bool = false,
        textAlignment: String = "left",
        textColorHex: String = "#FFFFFF",
        secondaryColorHex: String = "#DAA520",
        effectType: TextEffectType = .standard,
        shadowRadius: Double = 4,
        shadowX: Double = 2,
        shadowY: Double = 3,
        shadowColorHex: String = "#000000",
        shadowOpacity: Double = 0.8,
        isShadowEnabled: Bool = true,
        tableBorderColorHex: String = "#000000",
        tableBorderWidth: Double = 1.5,
        tableBackgroundColorHex: String = "#FFFFFF",
        tableBackgroundOpacity: Double = 0.95,
        tableHeaderBackgroundHex: String = "#F0F0F0",
        tableHeaderBackgroundOpacity: Double = 0.95,
        tableComment: String = "73, Thanks for the QSO. I hope to meet you further down the log.",
        tableShowCallsign: Bool = true,
        tableCallsignHeader: String = "Confirming QSO With",
        tableShowDate: Bool = true,
        tableDateHeader: String = "Date",
        tableShowTime: Bool = true,
        tableTimeHeader: String = "UTC Time",
        tableShowFreq: Bool = true,
        tableFreqHeader: String = "Band",
        tableFreqDisplayMode: TableFreqDisplayMode = .bandOnly,
        tableShowRST: Bool = true,
        tableRSTHeader: String = "Report",
        tableShowMode: Bool = true,
        tableModeHeader: String = "Mode",
        tableShowCommentRow: Bool = true,
        stickerType: StickerType = .arrl,
        customImagePath: String? = nil,
        stickerTintHex: String? = nil
    ) {
        self.id = id
        self.type = type
        self.name = name
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.normalizedWidth = normalizedWidth
        self.normalizedHeight = normalizedHeight
        self.rotationDegrees = rotationDegrees
        self.zIndex = zIndex
        self.textContent = textContent
        self.fontName = fontName
        self.fontSize = fontSize
        self.isBold = isBold
        self.isItalic = isItalic
        self.textAlignment = textAlignment
        self.textColorHex = textColorHex
        self.secondaryColorHex = secondaryColorHex
        self.effectType = effectType
        self.shadowRadius = shadowRadius
        self.shadowX = shadowX
        self.shadowY = shadowY
        self.shadowColorHex = shadowColorHex
        self.shadowOpacity = shadowOpacity
        self.isShadowEnabled = isShadowEnabled
        self.tableBorderColorHex = tableBorderColorHex
        self.tableBorderWidth = tableBorderWidth
        self.tableBackgroundColorHex = tableBackgroundColorHex
        self.tableBackgroundOpacity = tableBackgroundOpacity
        self.tableHeaderBackgroundHex = tableHeaderBackgroundHex
        self.tableHeaderBackgroundOpacity = tableHeaderBackgroundOpacity
        self.tableComment = tableComment
        self.tableShowCallsign = tableShowCallsign
        self.tableCallsignHeader = tableCallsignHeader
        self.tableShowDate = tableShowDate
        self.tableDateHeader = tableDateHeader
        self.tableShowTime = tableShowTime
        self.tableTimeHeader = tableTimeHeader
        self.tableShowFreq = tableShowFreq
        self.tableFreqHeader = tableFreqHeader
        self.tableFreqDisplayMode = tableFreqDisplayMode
        self.tableShowRST = tableShowRST
        self.tableRSTHeader = tableRSTHeader
        self.tableShowMode = tableShowMode
        self.tableModeHeader = tableModeHeader
        self.tableShowCommentRow = tableShowCommentRow
        self.stickerType = stickerType
        self.customImagePath = customImagePath
        self.stickerTintHex = stickerTintHex
    }
    
    enum CodingKeys: String, CodingKey {
        case id, type, name, isVisible, isLocked
        case normalizedX, normalizedY, normalizedWidth, normalizedHeight, rotationDegrees, zIndex
        case textContent, fontName, fontSize, isBold, isItalic, textAlignment, textColorHex, secondaryColorHex
        case effectType, shadowRadius, shadowX, shadowY, shadowColorHex, shadowOpacity, isShadowEnabled
        case tableBorderColorHex, tableBorderWidth, tableBackgroundColorHex, tableBackgroundOpacity
        case tableHeaderBackgroundHex, tableHeaderBackgroundOpacity, tableComment
        case tableShowCallsign, tableCallsignHeader, tableShowDate, tableDateHeader
        case tableShowTime, tableTimeHeader, tableShowFreq, tableFreqHeader, tableFreqDisplayMode
        case tableShowRST, tableRSTHeader, tableShowMode, tableModeHeader, tableShowCommentRow
        case stickerType, customImagePath, stickerTintHex
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.type = try c.decodeIfPresent(ElementType.self, forKey: .type) ?? .text
        self.name = try c.decodeIfPresent(String.self, forKey: .name) ?? "Element"
        self.isVisible = try c.decodeIfPresent(Bool.self, forKey: .isVisible) ?? true
        self.isLocked = try c.decodeIfPresent(Bool.self, forKey: .isLocked) ?? false
        self.normalizedX = try c.decodeIfPresent(Double.self, forKey: .normalizedX) ?? 0.5
        self.normalizedY = try c.decodeIfPresent(Double.self, forKey: .normalizedY) ?? 0.5
        self.normalizedWidth = try c.decodeIfPresent(Double.self, forKey: .normalizedWidth) ?? 0.3
        self.normalizedHeight = try c.decodeIfPresent(Double.self, forKey: .normalizedHeight) ?? 0.15
        self.rotationDegrees = try c.decodeIfPresent(Double.self, forKey: .rotationDegrees) ?? 0.0
        self.zIndex = try c.decodeIfPresent(Int.self, forKey: .zIndex) ?? 0
        self.textContent = try c.decodeIfPresent(String.self, forKey: .textContent) ?? ""
        self.fontName = try c.decodeIfPresent(String.self, forKey: .fontName) ?? "System"
        self.fontSize = try c.decodeIfPresent(Double.self, forKey: .fontSize) ?? 24
        self.isBold = try c.decodeIfPresent(Bool.self, forKey: .isBold) ?? true
        self.isItalic = try c.decodeIfPresent(Bool.self, forKey: .isItalic) ?? false
        self.textAlignment = try c.decodeIfPresent(String.self, forKey: .textAlignment) ?? "left"
        self.textColorHex = try c.decodeIfPresent(String.self, forKey: .textColorHex) ?? "#FFFFFF"
        self.secondaryColorHex = try c.decodeIfPresent(String.self, forKey: .secondaryColorHex) ?? "#DAA520"
        self.effectType = try c.decodeIfPresent(TextEffectType.self, forKey: .effectType) ?? .standard
        self.shadowRadius = try c.decodeIfPresent(Double.self, forKey: .shadowRadius) ?? 4
        self.shadowX = try c.decodeIfPresent(Double.self, forKey: .shadowX) ?? 2
        self.shadowY = try c.decodeIfPresent(Double.self, forKey: .shadowY) ?? 3
        self.shadowColorHex = try c.decodeIfPresent(String.self, forKey: .shadowColorHex) ?? "#000000"
        self.shadowOpacity = try c.decodeIfPresent(Double.self, forKey: .shadowOpacity) ?? 0.8
        self.isShadowEnabled = try c.decodeIfPresent(Bool.self, forKey: .isShadowEnabled) ?? true
        self.tableBorderColorHex = try c.decodeIfPresent(String.self, forKey: .tableBorderColorHex) ?? "#000000"
        self.tableBorderWidth = try c.decodeIfPresent(Double.self, forKey: .tableBorderWidth) ?? 1.5
        self.tableBackgroundColorHex = try c.decodeIfPresent(String.self, forKey: .tableBackgroundColorHex) ?? "#FFFFFF"
        self.tableBackgroundOpacity = try c.decodeIfPresent(Double.self, forKey: .tableBackgroundOpacity) ?? 0.95
        self.tableHeaderBackgroundHex = try c.decodeIfPresent(String.self, forKey: .tableHeaderBackgroundHex) ?? "#F0F0F0"
        self.tableHeaderBackgroundOpacity = try c.decodeIfPresent(Double.self, forKey: .tableHeaderBackgroundOpacity) ?? 0.95
        self.tableComment = try c.decodeIfPresent(String.self, forKey: .tableComment) ?? "73, Thanks for the QSO. I hope to meet you further down the log."
        self.tableShowCallsign = try c.decodeIfPresent(Bool.self, forKey: .tableShowCallsign) ?? true
        self.tableCallsignHeader = try c.decodeIfPresent(String.self, forKey: .tableCallsignHeader) ?? "Confirming QSO With"
        self.tableShowDate = try c.decodeIfPresent(Bool.self, forKey: .tableShowDate) ?? true
        self.tableDateHeader = try c.decodeIfPresent(String.self, forKey: .tableDateHeader) ?? "Date"
        self.tableShowTime = try c.decodeIfPresent(Bool.self, forKey: .tableShowTime) ?? true
        self.tableTimeHeader = try c.decodeIfPresent(String.self, forKey: .tableTimeHeader) ?? "UTC Time"
        self.tableShowFreq = try c.decodeIfPresent(Bool.self, forKey: .tableShowFreq) ?? true
        self.tableFreqHeader = try c.decodeIfPresent(String.self, forKey: .tableFreqHeader) ?? "Band"
        self.tableFreqDisplayMode = try c.decodeIfPresent(TableFreqDisplayMode.self, forKey: .tableFreqDisplayMode) ?? .bandOnly
        self.tableShowRST = try c.decodeIfPresent(Bool.self, forKey: .tableShowRST) ?? true
        self.tableRSTHeader = try c.decodeIfPresent(String.self, forKey: .tableRSTHeader) ?? "Report"
        self.tableShowMode = try c.decodeIfPresent(Bool.self, forKey: .tableShowMode) ?? true
        self.tableModeHeader = try c.decodeIfPresent(String.self, forKey: .tableModeHeader) ?? "Mode"
        self.tableShowCommentRow = try c.decodeIfPresent(Bool.self, forKey: .tableShowCommentRow) ?? true
        self.stickerType = try c.decodeIfPresent(StickerType.self, forKey: .stickerType) ?? .arrl
        self.customImagePath = try c.decodeIfPresent(String.self, forKey: .customImagePath)
        self.stickerTintHex = try c.decodeIfPresent(String.self, forKey: .stickerTintHex)
    }
}
