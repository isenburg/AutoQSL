import Foundation
import AppKit

public final class MacLoggerDXAppleScriptService {
    public static let shared = MacLoggerDXAppleScriptService()
    
    public init() {}
    
    public func fetchLastQSO() async throws -> QSO {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Check if MacLoggerDX is running
                let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: "com.dogparksoftware.MacLoggerDX")
                let anyMLDX = !runningApps.isEmpty || NSWorkspace.shared.runningApplications.contains { app in
                    app.localizedName?.lowercased().contains("maclogger") == true
                }
                
                guard anyMLDX else {
                    continuation.resume(throwing: NSError(
                        domain: "MacLoggerDX",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "MacLoggerDX is not running. Please launch MacLoggerDX and try again."]
                    ))
                    return
                }
                
                // 1. Try ADIF export via AppleScript
                let adifScriptText = """
                tell application "MacLoggerDX"
                    try
                        set adifText to get_last_qso_adif
                        return adifText
                    on error
                        return ""
                    end try
                end tell
                """
                
                var errorDict: NSDictionary?
                var adifOutput: String? = nil
                if let appleScript = NSAppleScript(source: adifScriptText) {
                    let descriptor = appleScript.executeAndReturnError(&errorDict)
                    if errorDict == nil, let str = descriptor.stringValue, !str.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        adifOutput = str
                    }
                }
                
                if let adif = adifOutput, !adif.isEmpty {
                    let records = ADIFParser.parse(text: adif)
                    if let lastRecord = records.last, let call = lastRecord.dxCall, !call.isEmpty {
                        let qso = QSO(
                            source: .macloggerdx,
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
                        return
                    }
                }
                
                // 2. Fallback to direct field getters
                let fieldsScript = """
                tell application "MacLoggerDX"
                    try
                        set theCall to get_call
                        set theBand to get_band
                        set theMode to get_mode
                        set theFreq to get_frequency
                        set theRstSent to get_rst_sent
                        set theRstRcvd to get_rst_rcvd
                        set theName to get_name
                        set theGrid to get_grid
                        set theCountry to get_country
                        set theEmail to get_email
                        set theComments to get_comments
                        set thePower to get_power
                        return (theCall as text) & "\\t" & (theBand as text) & "\\t" & (theMode as text) & "\\t" & (theFreq as text) & "\\t" & (theRstSent as text) & "\\t" & (theRstRcvd as text) & "\\t" & (theName as text) & "\\t" & (theGrid as text) & "\\t" & (theCountry as text) & "\\t" & (theEmail as text) & "\\t" & (theComments as text) & "\\t" & (thePower as text)
                    on error errMsg number errNum
                        return "ERR:" & (errNum as text) & ":" & errMsg
                    end try
                end tell
                """
                
                guard let fieldScriptObj = NSAppleScript(source: fieldsScript) else {
                    continuation.resume(throwing: NSError(
                        domain: "MacLoggerDX",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to initialize AppleScript for MacLoggerDX."]
                    ))
                    return
                }
                
                var fieldErr: NSDictionary?
                let descriptor = fieldScriptObj.executeAndReturnError(&fieldErr)
                
                if let error = fieldErr {
                    let errDescription = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    let errorNumber = error[NSAppleScript.errorNumber] as? Int ?? 0
                    let msg: String
                    if errorNumber == -1743 || errDescription.lowercased().contains("not authorized") {
                        msg = "Permission denied: macOS blocked Apple Events to MacLoggerDX. Please enable 'MacLoggerDX' under System Settings > Privacy & Security > Automation > AutoQSL."
                    } else {
                        msg = "MacLoggerDX AppleScript error: \(errDescription)"
                    }
                    continuation.resume(throwing: NSError(domain: "MacLoggerDX", code: errorNumber, userInfo: [NSLocalizedDescriptionKey: msg]))
                    return
                }
                
                guard let output = descriptor.stringValue, !output.isEmpty else {
                    continuation.resume(throwing: NSError(
                        domain: "MacLoggerDX",
                        code: 204,
                        userInfo: [NSLocalizedDescriptionKey: "MacLoggerDX returned no data (logbook might be empty)."]
                    ))
                    return
                }
                
                if output.hasPrefix("ERR:") {
                    continuation.resume(throwing: NSError(
                        domain: "MacLoggerDX",
                        code: 500,
                        userInfo: [NSLocalizedDescriptionKey: "MacLoggerDX: \(output)"]
                    ))
                    return
                }
                
                let parts = output.components(separatedBy: "\t")
                let call = parts.indices.contains(0) ? parts[0].trimmingCharacters(in: .whitespacesAndNewlines) : ""
                
                guard !call.isEmpty && call != "missing value" else {
                    continuation.resume(throwing: NSError(
                        domain: "MacLoggerDX",
                        code: 404,
                        userInfo: [NSLocalizedDescriptionKey: "No active or logged contact found in MacLoggerDX."]
                    ))
                    return
                }
                
                let band = parts.indices.contains(1) && parts[1] != "missing value" ? parts[1] : "20m"
                let mode = parts.indices.contains(2) && parts[2] != "missing value" ? parts[2] : "SSB"
                let freqStr = parts.indices.contains(3) && parts[3] != "missing value" ? parts[3] : ""
                let freqHz = Double(freqStr.replacingOccurrences(of: ",", with: "."))
                let rstSent = parts.indices.contains(4) && parts[4] != "missing value" ? parts[4] : "59"
                let rstRcvd = parts.indices.contains(5) && parts[5] != "missing value" ? parts[5] : "59"
                let dxName = parts.indices.contains(6) && parts[6] != "missing value" ? parts[6] : ""
                let dxGrid = parts.indices.contains(7) && parts[7] != "missing value" ? parts[7] : ""
                let dxCountry = parts.indices.contains(8) && parts[8] != "missing value" ? parts[8] : ""
                let dxEmail = parts.indices.contains(9) && parts[9] != "missing value" ? parts[9] : ""
                let comment = parts.indices.contains(10) && parts[10] != "missing value" ? parts[10] : ""
                let pwrStr = parts.indices.contains(11) && parts[11] != "missing value" ? parts[11] : ""
                let pwr = Double(pwrStr)
                
                let qso = QSO(
                    source: .macloggerdx,
                    dxCall: call,
                    band: band,
                    mode: mode,
                    frequencyHz: freqHz != nil ? (freqHz! > 100_000 ? freqHz : freqHz! * 1_000_000.0) : nil,
                    qsoDate: Date(),
                    rstSent: rstSent,
                    rstRcvd: rstRcvd,
                    comment: comment,
                    txPowerWatts: pwr,
                    dxName: dxName,
                    dxGrid: dxGrid,
                    dxCountry: dxCountry,
                    dxEmail: dxEmail
                )
                
                continuation.resume(returning: qso)
            }
        }
    }
}
