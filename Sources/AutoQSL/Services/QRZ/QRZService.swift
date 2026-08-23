import Foundation

@MainActor
public final class QRZService: ObservableObject {
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var sessionKey: String? = nil
    @Published public private(set) var lastError: String? = nil
    @Published public private(set) var subscriptionExpiry: String? = nil
    
    private var cache: [String: QRZProfile] = [:]
    private let urlSession: URLSession
    
    public init(session: URLSession = .shared) {
        self.urlSession = session
    }
    
    public func clearCache() {
        cache.removeAll()
    }
    
    public func authenticate(username: String, password: String) async -> Bool {
        guard !username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.lastError = "QRZ username or password is empty"
            self.isAuthenticated = false
            return false
        }
        
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let encodedUser = trimmedUser.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedPass = trimmedPass.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://xmldata.qrz.com/xml/current/?username=\(encodedUser)&password=\(encodedPass);agent=AutoQSL-1.0") else {
            self.lastError = "Invalid QRZ authentication URL"
            return false
        }
        
        do {
            let (data, _) = try await urlSession.data(from: url)
            guard let xmlString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                self.lastError = "Unable to decode QRZ XML response"
                return false
            }
            
            if let errorMsg = QRZXMLParser.extractTag("Error", from: xmlString) {
                self.lastError = errorMsg
                self.isAuthenticated = false
                return false
            }
            
            if let key = QRZXMLParser.extractTag("Key", from: xmlString), !key.isEmpty {
                let subExp = QRZXMLParser.extractTag("SubExp", from: xmlString)
                self.sessionKey = key
                self.subscriptionExpiry = subExp
                self.isAuthenticated = true
                self.lastError = nil
                return true
            } else {
                self.lastError = "No session key received from QRZ"
                self.isAuthenticated = false
                return false
            }
        } catch {
            self.lastError = error.localizedDescription
            self.isAuthenticated = false
            return false
        }
    }
    
    public func lookup(callsign: String, username: String? = nil, password: String? = nil) async -> QRZProfile? {
        let cleanCall = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCall.isEmpty else { return nil }
        
        if let cached = cache[cleanCall] {
            return cached
        }
        
        // If not authenticated and credentials provided, authenticate first
        if sessionKey == nil, let u = username, let p = password, !u.isEmpty, !p.isEmpty {
            let ok = await authenticate(username: u, password: p)
            if !ok {
                return nil
            }
        }
        
        guard let sKey = sessionKey else {
            self.lastError = "Not authenticated with QRZ.com"
            return nil
        }
        
        guard let encodedKey = sKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedCall = cleanCall.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://xmldata.qrz.com/xml/current/?s=\(encodedKey)&callsign=\(encodedCall)") else {
            return nil
        }
        
        do {
            let (data, _) = try await urlSession.data(from: url)
            guard let xmlString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                return nil
            }
            
            // Check for session timeout
            if let errorMsg = QRZXMLParser.extractTag("Error", from: xmlString) {
                if errorMsg.localizedCaseInsensitiveContains("Session Timeout") || errorMsg.localizedCaseInsensitiveContains("invalid session") {
                    self.sessionKey = nil
                    if let u = username, let p = password, !u.isEmpty, !p.isEmpty {
                        let reauthed = await authenticate(username: u, password: p)
                        if reauthed {
                            return await lookup(callsign: cleanCall)
                        }
                    }
                }
                self.lastError = errorMsg
                return nil
            }
            
            let profile = QRZXMLParser.parseCallsignXML(xmlString)
            if let prof = profile {
                self.cache[cleanCall] = prof
            }
            return profile
        } catch {
            self.lastError = error.localizedDescription
            return nil
        }
    }
}

public final class QRZXMLParser: Sendable {
    public static func extractTag(_ tag: String, from xml: String) -> String? {
        let pattern = "<\(tag)>([\\s\\S]*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        let nsString = xml as NSString
        guard let match = regex.firstMatch(in: xml, options: [], range: NSRange(location: 0, length: nsString.length)) else {
            return nil
        }
        return nsString.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public static func parseCallsignXML(_ xml: String) -> QRZProfile? {
        guard let call = extractTag("call", from: xml) ?? extractTag("Call", from: xml) else {
            return nil
        }
        
        let email = extractTag("email", from: xml)
        let fname = extractTag("fname", from: xml)
        let name = extractTag("name", from: xml)
        let addr1 = extractTag("addr1", from: xml)
        let addr2 = extractTag("addr2", from: xml)
        let state = extractTag("state", from: xml)
        let zip = extractTag("zip", from: xml)
        let country = extractTag("country", from: xml)
        let grid = extractTag("grid", from: xml)
        let cqzone = extractTag("cqzone", from: xml)
        let ituzone = extractTag("ituzone", from: xml)
        let county = extractTag("county", from: xml)
        let qslmgr = extractTag("qslmgr", from: xml)
        let lotw = (extractTag("lotw", from: xml) == "1")
        let eqsl = (extractTag("eqsl", from: xml) == "1")
        let imageURL = extractTag("image", from: xml)
        
        return QRZProfile(
            call: call,
            email: email,
            fname: fname,
            name: name,
            addr1: addr1,
            addr2: addr2,
            state: state,
            zip: zip,
            country: country,
            grid: grid,
            cqZone: cqzone,
            ituZone: ituzone,
            county: county,
            qslmgr: qslmgr,
            lotw: lotw,
            eqsl: eqsl,
            imageURL: imageURL
        )
    }
}
