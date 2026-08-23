import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }
}

@main
struct AutoQSLApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup("AutoQSL") {
            MainView(appState: appState)
                .frame(minWidth: 1050, minHeight: 700)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
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
            }
        }
    }
}
