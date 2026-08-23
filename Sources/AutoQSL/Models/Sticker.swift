import Foundation

public struct StickerItem: Identifiable, Codable, Hashable {
    public var id: UUID
    public var name: String
    public var category: String
    public var type: StickerType
    public var customImagePath: String?
    public var isBuiltin: Bool
    
    public init(
        id: UUID = UUID(),
        name: String,
        category: String,
        type: StickerType,
        customImagePath: String? = nil,
        isBuiltin: Bool = true
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.type = type
        self.customImagePath = customImagePath
        self.isBuiltin = isBuiltin
    }
    
    public static var builtinStickers: [StickerItem] {
        return [
            StickerItem(name: "ARRL Diamond Logo", category: "Badges", type: .arrl),
            StickerItem(name: "POTA - Parks on the Air", category: "Activities", type: .pota),
            StickerItem(name: "IOTA - Islands on the Air", category: "Activities", type: .iota),
            StickerItem(name: "SOTA - Summits on the Air", category: "Activities", type: .sota),
            StickerItem(name: "CQ Zone / WPX", category: "Contest / Award", type: .cq),
            StickerItem(name: "WAS - Worked All States", category: "Contest / Award", type: .was)
        ]
    }
}
