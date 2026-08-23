import Foundation
import AppKit

public final class RUMlogAppleScriptService {
    public static let shared = RUMlogAppleScriptService()
    
    public init() {}
    
    public func fetchLastQSO() async throws -> QSO {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Check if RUMlogNG is running
                let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "de.dl2rum.RUMlogNG")
                let anyRumlog = !runningApps.isEmpty || NSWorkspace.shared.runningApplications.contains { app in
                    app.localizedName?.lowercased().contains("rumlog") == true
                }
                
                guard anyRumlog else {
                    continuation.resume(throwing: NSError(
                        domain: "RUMlogNG",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "RUMlogNG is not running. Please launch RUMlogNG and try again."]
                    ))
                    return
                }
                
                let scriptText = """
                tell application "RUMlogNG"
                    set adifText to ReadAdif ("1900-01-01 00:00:00")
                    return adifText
                end tell
                """
                
                var errorDict: NSDictionary?
                guard let appleScript = NSAppleScript(source: scriptText) else {
                    continuation.resume(throwing: NSError(
                        domain: "RUMlogNG",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AppleScript for RUMlogNG."]
                    ))
                    return
                }
                
                let descriptor = appleScript.executeAndReturnError(&errorDict)
                
                if let error = errorDict {
                    let errDescription = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                    
                    let msg: String
                    if errorNumber == -1743 || errDescription.lowercased().contains("not authorized") {
                        msg = "Permission denied: macOS blocked Apple Events to RUMlogNG. Please enable 'RUMlogNG' under System Settings > Privacy & Security > Automation > AutoQSL."
                    } else {
                        msg = "RUMlogNG AppleScript error: \(errDescription)"
                    }
                    continuation.resume(throwing: NSError(domain: "RUMlogNG", code: errorNumber, userInfo: [NSLocalizedDescriptionKey: msg]))
                    return
                }
                
                guard let adifOutput = descriptor.stringValue, !adifOutput.isEmpty else {
                    continuation.resume(throwing: NSError(
                        domain: "RUMlogNG",
                        code: 204,
                        userInfo: [NSLocalizedDescriptionKey: "RUMlogNG returned no data (logbook might be empty)."]
                    ))
                    return
                }
                
                let records = ADIFParser.parse(text: adifOutput)
                guard let lastRecord = records.last, let call = lastRecord.dxCall, !call.isEmpty else {
                    continuation.resume(throwing: NSError(
                        domain: "RUMlogNG",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "No valid QSO record found in RUMlogNG export."]
                    ))
                    return
                }
                
                let qso = QSO(
                    source: .rumlog,
                    dxCall: call,
                    band: lastRecord.band ?? "20m",
                    mode: lastRecord.mode ?? "SSB",
                    frequencyHz: lastRecord.freqMHz != nil ? (lastRecord.freqMHz! * 1_000_000.0) : nil,
                    qsoDate: lastRecord.qsoDate ?? Date(),
                    rstSent: lastRecord.rstSent ?? "59",
                    rstRcvd: lastRecord.rstRcvd ?? "59",
                    comment: lastRecord.comment ?? "",
                    txPowerWatts: lastRecord.txPower,
                    dxName: lastRecord.dxName ?? "",
                    dxGrid: lastRecord.dxGrid ?? "",
                    dxCountry: lastRecord.dxCountry ?? "",
                    dxEmail: lastRecord.dxEmail ?? ""
                )
                
                continuation.resume(returning: qso)
            }
        }
    }
}
