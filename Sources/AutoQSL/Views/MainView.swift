import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case queue = "QSO Queue"
    case designer = "Card Designer"
    case settings = "Settings"
    case help = "Help & Docs"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .queue: return "tray.2.fill"
        case .designer: return "paintbrush.fill"
        case .settings: return "gearshape.fill"
        case .help: return "questionmark.circle.fill"
        }
    }
}

public struct MainView: View {
    @ObservedObject var appState: AppState
    @State private var selectedSection: NavigationSection = .queue
    
    private var awaitingCount: Int {
        appState.qsoQueue.filter { $0.status == .awaitingConfirmation || $0.status == .readyToSend }.count
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(NavigationSection.allCases, selection: $selectedSection) { section in
                    NavigationLink(value: section) {
                        HStack {
                            Label(section.rawValue, systemImage: section.iconName)
                            Spacer()
                            if section == .queue && awaitingCount > 0 {
                                Text("\(awaitingCount)")
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.orange)
                                    .foregroundColor(.white)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }
                .navigationTitle("AutoQSL")
                .frame(minWidth: 180)
            } detail: {
                Group {
                    switch selectedSection {
                    case .queue:
                        QSOQueueView(appState: appState)
                    case .designer:
                        CardDesignerRootView(appState: appState)
                    case .settings:
                        SettingsView(appState: appState)
                    case .help:
                        HelpView()
                    }
                }
            }
            
            Divider()
            
            // Bottom Status Bar
            HStack(spacing: 16) {
                // UDP Status
                HStack(spacing: 6) {
                    Circle()
                        .fill(appState.udpListener.isAnyListening ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(appState.udpListener.isAnyListening ? "UDP Active (2237 / 2333)" : "UDP Inactive")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider().frame(height: 12)
                
                // Sending Mode
                HStack(spacing: 4) {
                    Image(systemName: "hand.raised.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text(appState.settings.sendingMode.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Divider().frame(height: 12)
                
                // Last Message
                Text(appState.lastLogMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Station Callsign
                Text("Station: \(appState.settings.myCallsign)")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .sheet(isPresented: $appState.isConfirmationSheetPresented) {
            if let qso = appState.qsoAwaitingConfirmation {
                QSLConfirmationSheet(appState: appState, qso: qso)
            }
        }
    }
}
