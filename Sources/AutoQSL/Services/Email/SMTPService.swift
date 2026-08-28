import Foundation

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
        
        let client = SMTPStreamClient(
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
        let client = SMTPStreamClient(
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

// MARK: - Native Stream-based SMTP Client supporting STARTTLS & SSL/TLS

private final class SMTPStreamClient: @unchecked Sendable {
    let host: String
    let port: Int
    let useTLS: Bool
    let username: String
    let password: String
    
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    init(host: String, port: Int, useTLS: Bool, username: String, password: String) {
        self.host = host
        self.port = port
        self.useTLS = useTLS
        self.username = username
        self.password = password
    }
    
    func testHandshakeAndAuth() async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    let greeting = try self.performSession(sendMessageFrom: nil, to: nil, data: nil)
                    continuation.resume(returning: "Connected & Authenticated successfully! Greeting: \(greeting)")
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func sendMessage(from: String, to: String, data: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    _ = try self.performSession(sendMessageFrom: from, to: to, data: data)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performSession(sendMessageFrom: String?, to: String?, data: String?) throws -> String {
        try openStreams()
        defer { close() }
        
        let greeting = try readReply()
        
        // 1. Initial EHLO
        let ehloReply = try sendCommand("EHLO localhost")
        
        // 2. Handle STARTTLS if port != 465 and useTLS is enabled or server advertises STARTTLS
        let isImplicitTLS = (port == 465)
        let supportsStartTLS = ehloReply.uppercased().contains("STARTTLS")
        
        if !isImplicitTLS && (useTLS || supportsStartTLS || port == 587) {
            let startTLSResponse = try sendCommand("STARTTLS")
            guard startTLSResponse.starts(with: "220") else {
                throw SMTPError.commandFailed("STARTTLS rejected: \(startTLSResponse)", code: 220)
            }
            
            // Upgrade connection to TLS
            upgradeToTLS()
            
            // After STARTTLS, client MUST send EHLO again (RFC 3207)
            _ = try sendCommand("EHLO localhost")
        }
        
        // 3. Authenticate if username is provided
        if !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            try authenticate()
        }
        
        // 4. Send Email if requested
        if let from = sendMessageFrom, let recipient = to, let rawData = data {
            let mailFromResp = try sendCommand("MAIL FROM:<\(from)>")
            guard mailFromResp.starts(with: "250") else {
                throw SMTPError.commandFailed("MAIL FROM rejected: \(mailFromResp)", code: nil)
            }
            
            let rcptResp = try sendCommand("RCPT TO:<\(recipient)>")
            guard rcptResp.starts(with: "250") || rcptResp.starts(with: "251") else {
                throw SMTPError.commandFailed("RCPT TO rejected: \(rcptResp)", code: nil)
            }
            
            let dataResp = try sendCommand("DATA")
            guard dataResp.starts(with: "354") else {
                throw SMTPError.commandFailed("DATA command rejected: \(dataResp)", code: nil)
            }
            
            let cleanData = rawData.replacingOccurrences(of: "\r\n.\r\n", with: "\r\n..\r\n")
            let sendResp = try sendRawData("\(cleanData)\r\n.\r\n")
            guard sendResp.starts(with: "250") else {
                throw SMTPError.commandFailed("Message rejected: \(sendResp)", code: nil)
            }
        }
        
        _ = try? sendCommand("QUIT")
        return greeting
    }
    
    private func authenticate() throws {
        let authResp = try sendCommand("AUTH LOGIN")
        if authResp.starts(with: "334") {
            let userB64 = Data(username.utf8).base64EncodedString()
            let userResp = try sendCommand(userB64)
            guard userResp.starts(with: "334") else {
                throw SMTPError.authenticationFailed("Username rejected: \(userResp)")
            }
            
            let passB64 = Data(password.utf8).base64EncodedString()
            let passResp = try sendCommand(passB64)
            guard passResp.starts(with: "235") else {
                throw SMTPError.authenticationFailed("Password rejected: \(passResp)")
            }
        } else {
            // Try AUTH PLAIN fallback
            let plainString = "\0\(username)\0\(password)"
            let plainB64 = Data(plainString.utf8).base64EncodedString()
            let plainResp = try sendCommand("AUTH PLAIN \(plainB64)")
            guard plainResp.starts(with: "235") else {
                throw SMTPError.authenticationFailed("Authentication rejected: \(authResp)")
            }
        }
    }
    
    private func openStreams() throws {
        var readStream: Unmanaged<CFReadStream>?
        var writeStream: Unmanaged<CFWriteStream>?
        
        CFStreamCreatePairWithSocketToHost(
            kCFAllocatorDefault,
            host as CFString,
            UInt32(port),
            &readStream,
            &writeStream
        )
        
        guard let inStream = readStream?.takeRetainedValue(),
              let outStream = writeStream?.takeRetainedValue() else {
            throw SMTPError.connectionFailed("Failed to create socket streams to \(host):\(port)")
        }
        
        let inputStream = inStream as InputStream
        let outputStream = outStream as OutputStream
        
        // If implicit TLS (Port 465), enable SSL before opening
        if port == 465 {
            inputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: .socketSecurityLevelKey)
            outputStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: .socketSecurityLevelKey)
        }
        
        inputStream.open()
        outputStream.open()
        
        self.inputStream = inputStream
        self.outputStream = outputStream
        
        // Wait for streams to be ready
        let deadline = Date().addingTimeInterval(12.0)
        while inputStream.streamStatus == .opening || outputStream.streamStatus == .opening {
            if Date() > deadline {
                throw SMTPError.timeout
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        
        if inputStream.streamStatus == .error || outputStream.streamStatus == .error {
            let err = inputStream.streamError ?? outputStream.streamError
            throw SMTPError.connectionFailed(err?.localizedDescription ?? "Connection failed")
        }
    }
    
    private func upgradeToTLS() {
        guard let inStream = inputStream, let outStream = outputStream else { return }
        inStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: .socketSecurityLevelKey)
        outStream.setProperty(StreamSocketSecurityLevel.negotiatedSSL as AnyObject, forKey: .socketSecurityLevelKey)
        
        // Give TLS handshake a moment to negotiate
        Thread.sleep(forTimeInterval: 0.2)
    }
    
    private func sendCommand(_ cmd: String) throws -> String {
        return try sendRawData("\(cmd)\r\n")
    }
    
    private func sendRawData(_ dataString: String) throws -> String {
        guard let outStream = outputStream else {
            throw SMTPError.connectionFailed("No active output stream")
        }
        
        guard let payload = dataString.data(using: .utf8) else {
            throw SMTPError.commandFailed("Could not encode command", code: nil)
        }
        
        var totalWritten = 0
        let count = payload.count
        
        try payload.withUnsafeBytes { rawBuffer in
            guard let ptr = rawBuffer.bindMemory(to: UInt8.self).baseAddress else { return }
            let deadline = Date().addingTimeInterval(15.0)
            
            while totalWritten < count {
                if Date() > deadline {
                    throw SMTPError.timeout
                }
                if outStream.hasSpaceAvailable {
                    let written = outStream.write(ptr + totalWritten, maxLength: count - totalWritten)
                    if written < 0 {
                        let err = outStream.streamError?.localizedDescription ?? "Write error"
                        throw SMTPError.commandFailed("Stream write failed: \(err)", code: nil)
                    }
                    totalWritten += written
                } else {
                    Thread.sleep(forTimeInterval: 0.02)
                }
            }
        }
        
        return try readReply()
    }
    
    private func readReply() throws -> String {
        guard let inStream = inputStream else {
            throw SMTPError.connectionFailed("No active input stream")
        }
        
        var buffer = [UInt8](repeating: 0, count: 4096)
        var accumulated = ""
        let deadline = Date().addingTimeInterval(15.0)
        
        while true {
            if Date() > deadline {
                throw SMTPError.timeout
            }
            
            if inStream.hasBytesAvailable {
                let bytesRead = inStream.read(&buffer, maxLength: buffer.count)
                if bytesRead < 0 {
                    let err = inStream.streamError?.localizedDescription ?? "Read error"
                    throw SMTPError.commandFailed("Stream read failed: \(err)", code: nil)
                }
                if bytesRead > 0 {
                    let chunk = String(decoding: buffer[0..<bytesRead], as: UTF8.self)
                    accumulated += chunk
                    
                    // Check if complete SMTP multi-line or single-line response received
                    // E.g. "250-first line\r\n250 last line\r\n" or "334 ...\r\n"
                    if let lastLine = accumulated.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n").last {
                        let trimmedLine = lastLine.trimmingCharacters(in: .whitespacesAndNewlines)
                        if trimmedLine.count >= 3, let code = Int(trimmedLine.prefix(3)) {
                            // If char at index 3 is space or end of string, response is complete!
                            if trimmedLine.count == 3 || trimmedLine[trimmedLine.index(trimmedLine.startIndex, offsetBy: 3)] == " " {
                                let trimmed = accumulated.trimmingCharacters(in: .whitespacesAndNewlines)
                                if code >= 400 {
                                    throw SMTPError.commandFailed(trimmed, code: code)
                                }
                                return trimmed
                            }
                        }
                    }
                }
            } else {
                Thread.sleep(forTimeInterval: 0.03)
            }
        }
    }
    
    private func close() {
        inputStream?.close()
        outputStream?.close()
        inputStream = nil
        outputStream = nil
    }
}
