import SwiftUI
import AppKit

@MainActor
public final class CardRenderer {
    public static let shared = CardRenderer()
    
    public init() {}
    
    public func renderCardToImage(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO?,
        scale: CGFloat = 2.0
    ) -> NSImage? {
        let baseWidth = template.aspectRatio.widthPoints
        let baseHeight = template.aspectRatio.heightPoints
        
        let canvas = CardCanvasView(
            template: template,
            settings: settings,
            qso: qso,
            isInteractive: false
        )
        .frame(width: baseWidth, height: baseHeight)
        
        let renderer = ImageRenderer(content: canvas)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(width: baseWidth, height: baseHeight)
        
        return renderer.nsImage
    }
    
    public func renderCardToJPEGData(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO?,
        compressionQuality: CGFloat = 0.9,
        scale: CGFloat = 2.0
    ) -> Data? {
        guard let nsImage = renderCardToImage(template: template, settings: settings, qso: qso, scale: scale) else {
            return nil
        }
        
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
    
    public func saveCardToFile(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO,
        targetDirectory: URL
    ) -> URL? {
        guard let data = renderCardToJPEGData(template: template, settings: settings, qso: qso) else {
            return nil
        }
        
        let cleanCall = qso.dxCall.replacingOccurrences(of: "/", with: "_")
        let filename = "QSL_\(cleanCall)_\(qso.formattedDateYear)\(qso.formattedDateMonth)\(qso.formattedDateDay)_\(qso.band).jpg"
        let fileURL = targetDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            return fileURL
        } catch {
            print("Failed to write card to disk: \(error)")
            return nil
        }
    }
}
