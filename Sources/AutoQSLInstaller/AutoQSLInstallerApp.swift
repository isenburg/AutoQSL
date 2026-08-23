import SwiftUI
import AppKit

@main
struct AutoQSLInstallerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            InstallerContentView()
                .frame(width: 540, height: 420)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.center()
            window.isMovableByWindowBackground = true
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

enum InstallTarget: String, CaseIterable, Identifiable {
    case systemApplications = "/Applications (Alle Benutzer)"
    case userApplications = "~/Applications (Nur aktueller Benutzer)"
    case customFolder = "Benutzerdefinierter Ordner..."

    var id: String { rawValue }
}

enum InstallState {
    case ready
    case installing(step: Int, message: String)
    case success(destinationPath: String)
    case failed(message: String)
}

struct InstallerContentView: View {
    @State private var selectedTarget: InstallTarget = .systemApplications
    @State private var customFolderPath: String = ""
    @State private var launchAfterInstall: Bool = true
    @State private var installState: InstallState = .ready
    @State private var showOverwriteAlert: Bool = false
    @State private var pendingTargetURL: URL? = nil
    @State private var sourceAppURL: URL? = nil

    private var targetDirectoryURL: URL {
        switch selectedTarget {
        case .systemApplications:
            return URL(fileURLWithPath: "/Applications")
        case .userApplications:
            let home = FileManager.default.homeDirectoryForCurrentUser
            return home.appendingPathComponent("Applications")
        case .customFolder:
            if !customFolderPath.isEmpty {
                return URL(fileURLWithPath: customFolderPath)
            }
            return URL(fileURLWithPath: "/Applications")
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            contentView
                .padding(24)
            Divider()
            footerView
        }
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            locateSourceApp()
        }
        .alert("Bestehende Version überschreiben?", isPresented: $showOverwriteAlert) {
            Button("Überschreiben", role: .destructive) {
                if let target = pendingTargetURL {
                    executeInstallation(destinationDir: target, overwrite: true)
                }
            }
            Button("Abbrechen", role: .cancel) { }
        } message: {
            Text("In '\(pendingTargetURL?.path ?? "")' existiert bereits eine Version von AutoQSL. Möchtest du sie durch diese Version ersetzen?")
        }
    }

    private var headerView: some View {
        HStack(spacing: 16) {
            Image(systemName: "envelope.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 44, height: 44)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("AutoQSL Installation")
                    .font(.headline)
                    .fontWeight(.bold)
                Text("Automated Electronic QSL Card Generator & Email Dispatcher")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private var contentView: some View {
        VStack(alignment: .leading, spacing: 16) {
            switch installState {
            case .ready:
                readyView
            case .installing(let step, let message):
                installingView(step: step, message: message)
            case .success(let destPath):
                successView(destPath: destPath)
            case .failed(let message):
                failedView(message: message)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var readyView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Wähle den Zielordner für die Installation:")
                .font(.subheadline)
                .fontWeight(.medium)

            Picker("", selection: $selectedTarget) {
                ForEach(InstallTarget.allCases) { target in
                    Text(target.rawValue).tag(target)
                }
            }
            .pickerStyle(.radioGroup)

            if selectedTarget == .customFolder {
                HStack {
                    TextField("Pfad zum Zielordner...", text: $customFolderPath)
                        .textFieldStyle(.roundedBorder)
                    Button("Durchsuchen...") {
                        selectCustomFolder()
                    }
                }
                .padding(.leading, 20)
            }

            Toggle("AutoQSL nach erfolgreicher Installation sofort starten", isOn: $launchAfterInstall)
                .padding(.top, 4)

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Label("Entfernt Gatekeeper-Quarantäne (xattr -cr) automatisch.", systemImage: "checkmark.shield")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Label("Aktualisiert lokale Code-Signatur für reibungslosen Start.", systemImage: "lock.shield")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
            .cornerRadius(6)
        }
    }

    private func installingView(step: Int, message: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            ProgressView()
                .scaleEffect(1.3)
            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func successView(destPath: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(.green)

            Text("Installation erfolgreich!")
                .font(.title2)
                .fontWeight(.bold)

            Text("AutoQSL wurde erfolgreich nach '\(destPath)' installiert und startbereit eingerichtet.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func failedView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "xmark.octagon.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .foregroundColor(.red)

            Text("Installation fehlgeschlagen")
                .font(.title2)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Erneut versuchen") {
                installState = .ready
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
            .padding(.top, 8)

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footerView: some View {
        HStack {
            Button("Beenden") {
                NSApp.terminate(nil)
            }
            .buttonStyle(.bordered)
            .keyboardShortcut(.cancelAction)

            Spacer()

            switch installState {
            case .ready:
                Button(action: startInstallation) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("AutoQSL Installieren")
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            case .installing:
                Button("Wird installiert...") { }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(true)

            case .success(let destPath):
                Button("Fertigstellen") {
                    if launchAfterInstall {
                        let destURL = URL(fileURLWithPath: destPath)
                        NSWorkspace.shared.open(destURL)
                    }
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)

            case .failed:
                EmptyView()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func locateSourceApp() {
        let fm = FileManager.default
        let mainBundleURL = Bundle.main.bundleURL
        let dir = mainBundleURL.deletingLastPathComponent()

        let candidate1 = dir.appendingPathComponent("AutoQSL.app")
        if fm.fileExists(atPath: candidate1.path) {
            sourceAppURL = candidate1
            return
        }

        let candidate2 = dir.deletingLastPathComponent().appendingPathComponent("AutoQSL.app")
        if fm.fileExists(atPath: candidate2.path) {
            sourceAppURL = candidate2
            return
        }

        if let volumes = try? fm.contentsOfDirectory(at: URL(fileURLWithPath: "/Volumes"), includingPropertiesForKeys: nil) {
            for vol in volumes {
                let candidate = vol.appendingPathComponent("AutoQSL.app")
                if fm.fileExists(atPath: candidate.path) {
                    sourceAppURL = candidate
                    return
                }
            }
        }
    }

    private func selectCustomFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Zielordner wählen"
        panel.title = "Zielordner für AutoQSL auswählen"

        if panel.runModal() == .OK, let url = panel.url {
            customFolderPath = url.path
            selectedTarget = .customFolder
        }
    }

    private func startInstallation() {
        guard sourceAppURL != nil else {
            installState = .failed(message: "Die Quelldatei 'AutoQSL.app' wurde im DMG oder Verzeichnis nicht gefunden.")
            return
        }

        let targetDir = targetDirectoryURL
        let destAppURL = targetDir.appendingPathComponent("AutoQSL.app")

        if FileManager.default.fileExists(atPath: destAppURL.path) {
            pendingTargetURL = targetDir
            showOverwriteAlert = true
            return
        }

        executeInstallation(destinationDir: targetDir, overwrite: false)
    }

    private func executeInstallation(destinationDir: URL, overwrite: Bool) {
        guard let source = sourceAppURL else { return }
        let destAppURL = destinationDir.appendingPathComponent("AutoQSL.app")

        installState = .installing(step: 1, message: "Kopiere AutoQSL nach '\(destinationDir.path)'...")

        DispatchQueue.global(qos: .userInitiated).async {
            let fm = FileManager.default

            do {
                try fm.createDirectory(at: destinationDir, withIntermediateDirectories: true, attributes: nil)

                if fm.fileExists(atPath: destAppURL.path) {
                    try fm.removeItem(at: destAppURL)
                }

                try fm.copyItem(at: source, to: destAppURL)

                DispatchQueue.main.async {
                    self.installState = .installing(step: 2, message: "Entferne macOS Gatekeeper Quarantäne (xattr -cr)...")
                }

                let xattrProcess = Process()
                xattrProcess.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                xattrProcess.arguments = ["-cr", destAppURL.path]
                try? xattrProcess.run()
                xattrProcess.waitUntilExit()

                DispatchQueue.main.async {
                    self.installState = .installing(step: 3, message: "Aktualisiere ad-hoc Code-Signatur (codesign)...")
                }

                let codesignProcess = Process()
                codesignProcess.executableURL = URL(fileURLWithPath: "/usr/bin/codesign")
                codesignProcess.arguments = ["--force", "--deep", "--sign", "-", destAppURL.path]
                try? codesignProcess.run()
                codesignProcess.waitUntilExit()

                DispatchQueue.main.async {
                    self.installState = .success(destinationPath: destAppURL.path)
                }
                return
            } catch {
                DispatchQueue.main.async {
                    self.installState = .installing(step: 1, message: "Administrator-Rechte für '\(destinationDir.path)' erforderlich...")
                }

                let sourceEscaped = source.path.replacingOccurrences(of: "'", with: "'\\''")
                let destDirEscaped = destinationDir.path.replacingOccurrences(of: "'", with: "'\\''")
                let destAppEscaped = destAppURL.path.replacingOccurrences(of: "'", with: "'\\''")

                let shellCommand = "mkdir -p '\(destDirEscaped)' && rm -rf '\(destAppEscaped)' && cp -R '\(sourceEscaped)' '\(destDirEscaped)/' && /usr/bin/xattr -cr '\(destAppEscaped)' && /usr/bin/codesign --force --deep --sign - '\(destAppEscaped)'"
                let escapedForAppleScript = shellCommand
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                let appleScriptSource = "do shell script \"\(escapedForAppleScript)\" with administrator privileges"

                var errorDict: NSDictionary? = nil
                if let appleScript = NSAppleScript(source: appleScriptSource) {
                    _ = appleScript.executeAndReturnError(&errorDict)
                } else {
                    errorDict = [NSAppleScript.errorMessage: "AppleScript konnte nicht initialisiert werden."]
                }

                DispatchQueue.main.async {
                    if let error = errorDict {
                        let errMsg = error[NSAppleScript.errorMessage] as? String ?? "Installation fehlgeschlagen (Rechte verweigert)."
                        self.installState = .failed(message: errMsg)
                    } else {
                        self.installState = .success(destinationPath: destAppURL.path)
                    }
                }
            }
        }
    }
}
