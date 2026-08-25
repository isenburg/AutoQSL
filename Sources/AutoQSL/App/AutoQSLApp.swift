import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

public struct WindowAccessor: NSViewRepresentable {
    public let autosaveName: String
    public let defaultWidth: CGFloat
    public let defaultHeight: CGFloat
    
    public init(autosaveName: String, defaultWidth: CGFloat, defaultHeight: CGFloat) {
        self.autosaveName = autosaveName
        self.defaultWidth = defaultWidth
        self.defaultHeight = defaultHeight
    }
    
    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                window.tabbingMode = .disallowed
                window.setFrameAutosaveName(autosaveName)
                
                // If user hasn't resized or moved yet, set comfortable default size and center on screen
                if UserDefaults.standard.string(forKey: "NSWindow Frame \(autosaveName)") == nil {
                    let screenFrame = window.screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                    let w = min(defaultWidth, screenFrame.width * 0.9)
                    let h = min(defaultHeight, screenFrame.height * 0.9)
                    let x = screenFrame.origin.x + (screenFrame.width - w) / 2
                    let y = screenFrame.origin.y + (screenFrame.height - h) / 2
                    window.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
                }
            }
        }
        return view
    }
    
    public func updateNSView(_ nsView: NSView, context: Context) {}
}

@main
struct AutoQSLApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        Window("AutoQSL", id: "main") {
            MainView(appState: appState)
                .frame(minWidth: 1000, minHeight: 680)
        }
        .commands {
            AutoQSLCommands(appState: appState)
        }
        
        Window("Help & Docs", id: "help") {
            HelpView()
                .frame(minWidth: 800, idealWidth: 900, minHeight: 600, idealHeight: 700)
                .background(WindowAccessor(autosaveName: "AutoQSLHelpWindow", defaultWidth: 900, defaultHeight: 700))
        }
    }
}

struct AutoQSLCommands: Commands {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("Settings…") {
                appState.navigationSection = .settings
                if let window = NSApp.windows.first(where: { $0.identifier?.rawValue == "main" || $0.title.contains("AutoQSL") }) {
                    window.makeKeyAndOrderFront(nil)
                }
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        
        CommandGroup(replacing: .help) {
            Button("AutoQSL Help") {
                openWindow(id: "help")
            }
            .keyboardShortcut("?", modifiers: .command)
        }
        
        // Remove File Menu items
        CommandGroup(replacing: .newItem) {}
        CommandGroup(replacing: .saveItem) {}
        CommandGroup(replacing: .printItem) {}
        
        CommandGroup(after: .sidebar) {
            Divider()
            
            Button("QSO Queue") {
                appState.navigationSection = .queue
            }
            .keyboardShortcut("1", modifiers: .command)
            
            Button("Card Designer") {
                appState.navigationSection = .designer
            }
            .keyboardShortcut("2", modifiers: .command)
            
            Button("Settings") {
                appState.navigationSection = .settings
            }
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            Button("Help & Documentation") {
                openWindow(id: "help")
            }
        }
        
        CommandMenu("Actions") {
            Button("Simulate Sample QSO") {
                let qso = QSO(
                    source: .wsjtx,
                    dxCall: "DJ6GI",
                    band: "20m",
                    mode: "FT8",
                    frequencyHz: 14074000,
                    qsoDate: Date(),
                    rstSent: "-12",
                    rstRcvd: "-08",
                    comment: "73, Thanks for the QSO. I hope to meet you further down the log.",
                    txPowerWatts: 50,
                    dxName: "Gerd Ihde",
                    dxGrid: "JN58td",
                    dxCountry: "Germany",
                    dxEmail: "dj6gi@example.com",
                    qrzFound: true
                )
                appState.handleIncomingQSO(qso)
            }
            .keyboardShortcut("k", modifiers: [.command, .shift])
            
            Button("Grab Last QSO from RUMlogNG") {
                appState.grabLastQSOFromRUMlog()
            }
            .keyboardShortcut("g", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Restart UDP Listeners") {
                appState.startUDPListening()
            }
        }
    }
}
