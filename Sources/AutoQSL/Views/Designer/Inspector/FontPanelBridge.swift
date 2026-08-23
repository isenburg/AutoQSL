import AppKit
import SwiftUI

public final class FontPanelBridge: NSObject {
    public static let shared = FontPanelBridge()
    
    private var onFontChange: ((String, Double, Bool, Bool) -> Void)?
    
    public func present(
        fontName: String,
        fontSize: Double,
        isBold: Bool,
        isItalic: Bool,
        onChange: @escaping (String, Double, Bool, Bool) -> Void
    ) {
        self.onFontChange = onChange
        
        let manager = NSFontManager.shared
        manager.target = self
        manager.action = #selector(changeFont(_:))
        
        let baseFont: NSFont
        if let custom = NSFont(name: fontName, size: CGFloat(fontSize)) {
            baseFont = custom
        } else {
            baseFont = NSFont.systemFont(ofSize: CGFloat(fontSize), weight: isBold ? .bold : .regular)
        }
        
        manager.setSelectedFont(baseFont, isMultiple: false)
        
        let panel = NSFontPanel.shared
        panel.orderFront(nil)
        panel.makeKeyAndOrderFront(nil)
    }
    
    @objc func changeFont(_ sender: Any?) {
        guard let manager = sender as? NSFontManager else { return }
        let currentFont = manager.selectedFont ?? NSFont.systemFont(ofSize: 14)
        let converted = manager.convert(currentFont)
        
        let name = converted.familyName ?? converted.fontName
        let size = Double(converted.pointSize)
        let traits = manager.traits(of: converted)
        let bold = traits.contains(.boldFontMask)
        let italic = traits.contains(.italicFontMask)
        
        onFontChange?(name, size, bold, italic)
    }
}
