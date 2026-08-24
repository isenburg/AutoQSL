import Foundation
import AppKit

public enum AppleMailError: LocalizedError {
    case scriptExecutionFailed(String)
    case attachmentFileNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .scriptExecutionFailed(let msg):
            return "Apple Mail Error: \(msg)"
        case .attachmentFileNotFound(let path):
            return "Attachment file not found at: \(path)"
        }
    }
}

public final class AppleMailService: Sendable {
    public static let shared = AppleMailService()
    
    // Dedicated serial queue to prevent concurrency collisions in Apple Mail's AppleScript engine
    private let serialQueue = DispatchQueue(label: "com.autoqsl.applemail.serial", qos: .userInitiated)
    
    public init() {}
    
    /// Tests accessibility of Apple Mail via AppleScript
    public func testConnection() async throws -> String {
        let scriptSource = """
        tell application "Mail"
            return name
        end tell
        """
        try await executeAppleScript(scriptSource)
        return "Apple Mail is ready and responsive."
    }
    
    /// Sends an email with an attached QSL card file through Apple Mail
    public func sendViaAppleMail(
        recipientEmail: String,
        recipientName: String,
        subject: String,
        bodyText: String,
        attachmentPath: String,
        sendImmediately: Bool = true
    ) async throws {
        guard FileManager.default.fileExists(atPath: attachmentPath) else {
            throw AppleMailError.attachmentFileNotFound(attachmentPath)
        }
        
        let escapedSubject = escapeAppleScriptString(subject)
        let escapedBody = escapeAppleScriptString(bodyText)
        let escapedRecipientEmail = escapeAppleScriptString(recipientEmail)
        let escapedRecipientName = escapeAppleScriptString(recipientName)
        let escapedAttachmentPath = escapeAppleScriptString(attachmentPath)
        let visibleStr = sendImmediately ? "false" : "true"
        let sendCommand = sendImmediately ? "send newMessage" : "activate"
        
        let scriptSource = """
        tell application "Mail"
            set theAttachmentFile to (POSIX file "\(escapedAttachmentPath)") as alias
            set newMessage to make new outgoing message with properties {subject:"\(escapedSubject)", content:"\(escapedBody)" & return & return, visible:\(visibleStr)}
            tell newMessage
                make new to recipient at end of to recipients with properties {address:"\(escapedRecipientEmail)", name:"\(escapedRecipientName)"}
                tell content
                    make new attachment with properties {file name:theAttachmentFile} at after the last paragraph
                end tell
                delay 0.15
                \(sendCommand)
            end tell
        end tell
        """
        
        try await executeAppleScript(scriptSource)
    }
    
    /// Opens the default macOS Mail composer with pre-filled recipient, subject, body, and attachment
    public func openComposeWindow(
        recipientEmail: String,
        subject: String,
        bodyText: String,
        attachmentPath: String
    ) {
        let attachmentURL = URL(fileURLWithPath: attachmentPath)
        let sharingService = NSSharingService(named: .composeEmail)
        sharingService?.recipients = [recipientEmail]
        sharingService?.subject = subject
        
        var items: [Any] = [bodyText]
        if FileManager.default.fileExists(atPath: attachmentPath) {
            items.append(attachmentURL)
        }
        
        DispatchQueue.main.async {
            sharingService?.perform(withItems: items)
        }
    }
    
    private func executeAppleScript(_ source: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            serialQueue.async {
                var errorDict: NSDictionary?
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: AppleMailError.scriptExecutionFailed("Failed to initialize AppleScript"))
                    return
                }
                
                script.executeAndReturnError(&errorDict)
                if let error = errorDict {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    continuation.resume(throwing: AppleMailError.scriptExecutionFailed(message))
                } else {
                    continuation.resume()
                }
            }
        }
    }
    
    private func escapeAppleScriptString(_ str: String) -> String {
        return str
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: "\" & return & \"")
    }
}
