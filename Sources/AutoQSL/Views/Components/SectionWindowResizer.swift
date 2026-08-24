import SwiftUI
import AppKit

public final class WindowResizeCoordinator: ObservableObject {
    public static let shared = WindowResizeCoordinator()
    public var isProgrammaticResizing = false
}

public struct SectionWindowResizer: NSViewRepresentable {
    public let section: NavigationSection
    
    public init(section: NavigationSection) {
        self.section = section
    }
    
    public static func defaultSize(for section: NavigationSection) -> CGSize {
        switch section {
        case .queue:
            return CGSize(width: 1140, height: 750)
        case .designer:
            return CGSize(width: 1380, height: 870)
        case .settings:
            return CGSize(width: 1060, height: 750)
        }
    }
    
    public static func getSavedSize(for section: NavigationSection) -> CGSize {
        let keyW = "AutoQSL_WindowWidth_\(section.rawValue)"
        let keyH = "AutoQSL_WindowHeight_\(section.rawValue)"
        let w = UserDefaults.standard.double(forKey: keyW)
        let h = UserDefaults.standard.double(forKey: keyH)
        if w >= 500 && h >= 400 {
            return CGSize(width: w, height: h)
        }
        return defaultSize(for: section)
    }
    
    public static func saveSize(_ size: CGSize, for section: NavigationSection) {
        guard size.width >= 500 && size.height >= 400 else { return }
        let keyW = "AutoQSL_WindowWidth_\(section.rawValue)"
        let keyH = "AutoQSL_WindowHeight_\(section.rawValue)"
        UserDefaults.standard.set(size.width, forKey: keyW)
        UserDefaults.standard.set(size.height, forKey: keyH)
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.attach(view: view)
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.parent = self
        context.coordinator.applySectionSize(section: section, animated: true)
    }
    
    public class Coordinator: NSObject {
        var parent: SectionWindowResizer
        weak var targetWindow: NSWindow?
        private var lastSection: NavigationSection?
        private var resizeObserver: Any?
        
        init(_ parent: SectionWindowResizer) {
            self.parent = parent
            super.init()
        }
        
        deinit {
            if let obs = resizeObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
        
        func attach(view: NSView) {
            DispatchQueue.main.async { [weak self, weak view] in
                guard let self = self, let window = view?.window else { return }
                self.targetWindow = window
                window.tabbingMode = .disallowed
                
                // Observe user-driven window resizes
                self.resizeObserver = NotificationCenter.default.addObserver(
                    forName: NSWindow.didResizeNotification,
                    object: window,
                    queue: .main
                ) { [weak self] _ in
                    guard let self = self, let win = self.targetWindow else { return }
                    if !WindowResizeCoordinator.shared.isProgrammaticResizing {
                        SectionWindowResizer.saveSize(win.frame.size, for: self.parent.section)
                    }
                }
                
                self.applySectionSize(section: self.parent.section, animated: false)
            }
        }
        
        func applySectionSize(section: NavigationSection, animated: Bool) {
            guard let window = targetWindow ?? NSApplication.shared.windows.first(where: { $0.isVisible && $0.title == "AutoQSL" }) else {
                return
            }
            if targetWindow == nil {
                targetWindow = window
            }
            
            if lastSection == section { return }
            lastSection = section
            
            let targetSize = SectionWindowResizer.getSavedSize(for: section)
            let curFrame = window.frame
            
            if abs(curFrame.width - targetSize.width) > 4 || abs(curFrame.height - targetSize.height) > 4 {
                WindowResizeCoordinator.shared.isProgrammaticResizing = true
                
                let deltaW = targetSize.width - curFrame.width
                let deltaH = targetSize.height - curFrame.height
                var newOriginX = curFrame.origin.x - (deltaW / 2)
                var newOriginY = curFrame.origin.y - deltaH
                
                if let screen = window.screen ?? NSScreen.main {
                    let sf = screen.visibleFrame
                    newOriginX = max(sf.minX, min(newOriginX, sf.maxX - targetSize.width))
                    newOriginY = max(sf.minY, min(newOriginY, sf.maxY - targetSize.height))
                }
                
                let targetFrame = NSRect(x: newOriginX, y: newOriginY, width: targetSize.width, height: targetSize.height)
                window.setFrame(targetFrame, display: true, animate: animated)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + (animated ? 0.3 : 0.05)) {
                    WindowResizeCoordinator.shared.isProgrammaticResizing = false
                }
            }
        }
    }
}
