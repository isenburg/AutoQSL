import SwiftUI
import AppKit

@MainActor
public final class CardZoomWindowManager: NSObject, NSWindowDelegate {
    public static let shared = CardZoomWindowManager()
    
    private var zoomWindow: NSWindow?
    
    private override init() {
        super.init()
    }
    
    public func present(template: QSLCardTemplate, settings: AppSettings, qso: QSO?) {
        if let win = zoomWindow, win.isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let modalView = FullSizeCardModalView(
            template: template,
            settings: settings,
            qso: qso,
            onDismiss: { [weak self] in
                self?.closeWindow()
            }
        )
        
        let hostingController = NSHostingController(rootView: modalView)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 1120, height: 760)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1120, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "QSL Card Preview – \(qso?.dxCall.isEmpty == false ? qso!.dxCall : "Preview")"
        window.contentViewController = hostingController
        window.setContentSize(NSSize(width: 1120, height: 760))
        window.minSize = NSSize(width: 850, height: 550)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.level = .floating
        window.center()
        
        self.zoomWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func closeWindow() {
        zoomWindow?.close()
        zoomWindow = nil
    }
    
    public func windowWillClose(_ notification: Notification) {
        zoomWindow = nil
    }
}
