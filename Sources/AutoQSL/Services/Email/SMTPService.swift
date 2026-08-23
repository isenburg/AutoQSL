import Foundation
import Network

public enum SMTPError: LocalizedError {
    case invalidConfiguration(String)
    case connectionFailed(String)
    case authenticationFailed(String)
    case commandFailed(String, code: Int?)
    case timeout
    case cancelled
    
    public var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let msg): return "SMTP Configuration Error: \(msg)"
        case .connectionFailed(let msg): return "SMTP Connection Failed: \(msg)"
        case .authenticationFailed(let msg): return "SMTP Authentication Failed: \(msg)"
        case .commandFailed(let msg, let code): return "SMTP Error \(code != nil ? "(\(code!))" : ""): \(msg)"
        case .timeout: return "SMTP Connection Timed Out"
        case .cancelled: return "SMTP Operation Cancelled"
        }
    }
}

public final class SMTPService: Sendable {
    public static let shared = SMTPService()
    
    public init() {}
    
    public func sendQSLCard(
        recipientEmail: String,
        recipientCall: String,
        subject: String,
        bodyText: String,
        cardImageData: Data,
        imageFilename: String = "QSL_Card.jpg",
        settings: AppSettings
    ) async throws {
        guard !recipientEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SMTPError.invalidConfiguration("Recipient email address is missing")
        }
        guard !settings.smtpHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SMTPError.invalidConfiguration("SMTP host is not configured")
        }
        guard !settings.fromEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SMTPError.invalidConfiguration("Sender (From) email address is not configured")
        }
        
        let boundary = "----=_Part_\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        let fromHeader = settings.fromName.isEmpty ? settings.fromEmail : "\(settings.fromName) <\(settings.fromEmail)>"
        let toHeader = "\(recipientCall) <\(recipientEmail)>"
        
        var message = ""
        message += "From: \(fromHeader)\r\n"
        message += "To: \(toHeader)\r\n"
        if !settings.replyToEmail.isEmpty {
            message += "Reply-To: \(settings.replyToEmail)\r\n"
        }
        message += "Subject: \(subject)\r\n"
        message += "Date: \(makeDateHeader())\r\n"
        message += "MIME-Version: 1.0\r\n"
        message += "Content-Type: multipart/mixed; boundary=\"\(boundary)\"\r\n"
        message += "\r\n"
        
        // Plain text part
        message += "--\(boundary)\r\n"
        message += "Content-Type: text/plain; charset=utf-8\r\n"
        message += "Content-Transfer-Encoding: 8bit\r\n\r\n"
        message += bodyText.replacingOccurrences(of: "\n", with: "\r\n") + "\r\n\r\n"
        
        // Attachment part
        message += "--\(boundary)\r\n"
        message += "Content-Type: image/jpeg; name=\"\(imageFilename)\"\r\n"
        message += "Content-Transfer-Encoding: base64\r\n"
        message += "Content-Disposition: attachment; filename=\"\(imageFilename)\"\r\n\r\n"
        
        let base64Image = cardImageData.base64EncodedString(options: [.lineLength76Characters, .endLineWithCarriageReturn, .endLineWithLineFeed])
        message += base64Image + "\r\n\r\n"
        message += "--\(boundary)--\r\n"
        
        try await executeSMTPSession(
            host: settings.smtpHost,
            port: settings.smtpPort,
            useTLS: settings.smtpUseTLS,
            username: settings.smtpUsername,
            password: settings.smtpPassword,
            fromEmail: settings.fromEmail,
            toEmail: recipientEmail,
            rawMessage: message
        )
    }
    
    public func testConnection(settings: AppSettings) async throws -> String {
        guard !settings.smtpHost.isEmpty else {
            throw SMTPError.invalidConfiguration("SMTP host is empty")
        }
        
        let client = SMTPConnectionClient(
            host: settings.smtpHost,
            port: settings.smtpPort,
            useTLS: settings.smtpUseTLS,
            username: settings.smtpUsername,
            password: settings.smtpPassword
        )
        return try await client.testHandshakeAndAuth()
    }
    
    private func executeSMTPSession(
        host: String,
        port: Int,
        useTLS: Bool,
        username: String,
        password: String,
        fromEmail: String,
        toEmail: String,
        rawMessage: String
    ) async throws {
        let client = SMTPConnectionClient(
            host: host,
            port: port,
            useTLS: useTLS,
            username: username,
            password: password
        )
        try await client.sendMessage(from: fromEmail, to: toEmail, data: rawMessage)
    }
    
    private func makeDateHeader() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
        return formatter.string(from: Date())
    }
}

private final class AtomicFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    
    func checkAndSet() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if flag { return false }
        flag = true
        return true
    }
}

private final class SMTPConnectionClient: @unchecked Sendable {
    let host: String
    let port: Int
    let useTLS: Bool
    let username: String
    let password: String
    
    private var connection: NWConnection?
    private let queue = DispatchQueue(label: "org.autoqsl.smtp.client")
    
    init(host: String, port: Int, useTLS: Bool, username: String, password: String) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.username = username
        self.password = password
    }
    
    func testHandshakeAndAuth() async throws -> String {
        try await connect()
        let greeting = try await readReply()
        _ = try await sendCommand("EHLO localhost")
        
        if !username.isEmpty {
            try await authenticate()
        }
        
        _ = try? await sendCommand("QUIT")
        close()
        return "Connected & Authenticated successfully! Greeting: \(greeting)"
    }
    
    func sendMessage(from: String, to: String, data: String) async throws {
        try await connect()
        _ = try await readReply()
        _ = try await sendCommand("EHLO localhost")
        
        if !username.isEmpty {
            try await authenticate()
        }
        
        _ = try await sendCommand("MAIL FROM:<\(from)>")
        _ = try await sendCommand("RCPT TO:<\(to)>")
        _ = try await sendCommand("DATA")
        
        let cleanData = data.replacingOccurrences(of: "\r\n.\r\n", with: "\r\n..\r\n")
        _ = try await sendCommand("\(cleanData)\r\n.")
        
        _ = try? await sendCommand("QUIT")
        close()
    }
    
    private func authenticate() async throws {
        let authResp = try await sendCommand("AUTH LOGIN")
        guard authResp.starts(with: "334") else {
            throw SMTPError.authenticationFailed("AUTH LOGIN not accepted: \(authResp)")
        }
        
        let userB64 = Data(username.utf8).base64EncodedString()
        let userResp = try await sendCommand(userB64)
        guard userResp.starts(with: "334") else {
            throw SMTPError.authenticationFailed("Username rejected: \(userResp)")
        }
        
        let passB64 = Data(password.utf8).base64EncodedString()
        let passResp = try await sendCommand(passB64)
        guard passResp.starts(with: "235") else {
            throw SMTPError.authenticationFailed("Password rejected: \(passResp)")
        }
    }
    
    private func connect() async throws {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: UInt16(port)) ?? 587
        )
        
        let params: NWParameters
        if port == 465 || (useTLS && port != 587 && port != 25) {
            params = .tls
        } else {
            params = .tcp
        }
        
        let conn = NWConnection(to: endpoint, using: params)
        self.connection = conn
        let flag = AtomicFlag()
        
        return try await withCheckedThrowingContinuation { continuation in
            conn.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    if flag.checkAndSet() {
                        continuation.resume()
                    }
                case .failed(let err):
                    if flag.checkAndSet() {
                        continuation.resume(throwing: SMTPError.connectionFailed(err.localizedDescription))
                    }
                case .cancelled:
                    if flag.checkAndSet() {
                        continuation.resume(throwing: SMTPError.cancelled)
                    }
                default:
                    break
                }
            }
            conn.start(queue: self.queue)
        }
    }
    
    private func sendCommand(_ cmd: String) async throws -> String {
        guard let conn = connection else { throw SMTPError.connectionFailed("No active connection") }
        let payload = "\(cmd)\r\n".data(using: .utf8)!
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            conn.send(content: payload, completion: .contentProcessed({ error in
                if let error = error {
                    continuation.resume(throwing: SMTPError.commandFailed(error.localizedDescription, code: nil))
                } else {
                    continuation.resume()
                }
            }))
        }
        
        return try await readReply()
    }
    
    private func readReply() async throws -> String {
        guard let conn = connection else { throw SMTPError.connectionFailed("No active connection") }
        
        return try await withCheckedThrowingContinuation { continuation in
            conn.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, error in
                if let error = error {
                    continuation.resume(throwing: SMTPError.commandFailed(error.localizedDescription, code: nil))
                    return
                }
                guard let data = data, let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
                    continuation.resume(throwing: SMTPError.commandFailed("Invalid reply data", code: nil))
                    return
                }
                
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let firstWord = trimmed.split(separator: " ").first ?? ""
                let code = Int(firstWord)
                
                if let code = code, code >= 400 {
                    continuation.resume(throwing: SMTPError.commandFailed(trimmed, code: code))
                } else {
                    continuation.resume(returning: trimmed)
                }
            }
        }
    }
    
    private func close() {
        connection?.cancel()
        connection = nil
    }
}
