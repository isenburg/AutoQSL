import SwiftUI

public enum NavigationSection: String, CaseIterable, Identifiable {
    case queue = "QSO Queue"
    case designer = "Card Designer"
    case settings = "Settings"
    
    public var id: String { rawValue }
    
    public var iconName: String {
        switch self {
        case .queue: return "tray.2.fill"
        case .designer: return "paintbrush.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

public struct MainView: View {
    @ObservedObject var appState: AppState
    @Environment(\.openWindow) private var openWindow
    
    private var awaitingCount: Int {
        appState.qsoQueue.filter { $0.status == .awaitingConfirmation || $0.status == .readyToSend }.count
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            NavigationSplitView {
                List(NavigationSection.allCases, selection: $appState.navigationSection) { section in
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
                .navigationSplitViewColumnWidth(min: 190, ideal: 190, max: 190)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 0) {
                        Divider()
                        Button(action: {
                            openWindow(id: "help")
                        }) {
                            HStack {
                                Label("Help & Docs", systemImage: "questionmark.circle.fill")
                                Spacer()
                                Image(systemName: "macwindow.on.rectangle")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            } detail: {
                Group {
                    switch appState.navigationSection {
                    case .queue:
                        QSOQueueView(appState: appState)
                    case .designer:
                        CardDesignerRootView(appState: appState)
                    case .settings:
                        SettingsView(appState: appState)
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
                    Text(verbatim: udpStatusText)
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
        .background(SectionWindowResizer(section: appState.navigationSection))
        .preferredColorScheme(appState.settings.appearance.colorScheme)
        .sheet(isPresented: $appState.isConfirmationSheetPresented) {
            if let qso = appState.qsoAwaitingConfirmation {
                QSLConfirmationSheet(appState: appState, qso: qso)
            }
        }
    }
    
    private var udpStatusText: String {
        let running = appState.udpListener.listeners.values.filter { $0.isRunning }
        if !running.isEmpty {
            let portStrings = running.map { String(format: "%d", $0.port) }
            return "UDP Active (\(portStrings.joined(separator: " / ")))"
        } else if appState.udpListener.isAnyListening {
            var activePorts: [String] = []
            if appState.settings.wsjtxEnabled {
                activePorts.append(String(format: "%d", appState.settings.wsjtxPort))
            }
            if appState.settings.rumlogEnabled {
                activePorts.append(String(format: "%d", appState.settings.rumlogPort))
            }
            return activePorts.isEmpty ? "UDP Inactive" : "UDP Active (\(activePorts.joined(separator: " / ")))"
        } else {
            return "UDP Inactive"
        }
    }
}
