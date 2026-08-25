import Foundation

@MainActor
public final class HamQTHService: ObservableObject {
    @Published public private(set) var isAuthenticated: Bool = false
    @Published public private(set) var sessionId: String? = nil
    @Published public private(set) var lastError: String? = nil
    
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
            self.lastError = "HamQTH username or password is empty"
            self.isAuthenticated = false
            return false
        }
        
        let trimmedUser = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPass = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let encodedUser = trimmedUser.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedPass = trimmedPass.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.hamqth.com/xml.php?u=\(encodedUser)&p=\(encodedPass)") else {
            self.lastError = "Invalid HamQTH authentication URL"
            return false
        }
        
        do {
            let (data, _) = try await urlSession.data(from: url)
            guard let xmlString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                self.lastError = "Unable to decode HamQTH XML response"
                return false
            }
            
            if let errorMsg = HamQTHXMLParser.extractTag("error", from: xmlString) {
                self.lastError = errorMsg
                self.isAuthenticated = false
                return false
            }
            
            if let session = HamQTHXMLParser.extractTag("session_id", from: xmlString), !session.isEmpty {
                self.sessionId = session
                self.isAuthenticated = true
                self.lastError = nil
                return true
            } else {
                self.lastError = "No session ID received from HamQTH"
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
        
        // Authenticate if needed
        if sessionId == nil, let u = username, let p = password, !u.isEmpty, !p.isEmpty {
            let ok = await authenticate(username: u, password: p)
            if !ok {
                return nil
            }
        }
        
        guard let sId = sessionId else {
            self.lastError = "Not authenticated with HamQTH"
            return nil
        }
        
        guard let encodedId = sId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedCall = cleanCall.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.hamqth.com/xml.php?id=\(encodedId)&callsign=\(encodedCall)&prg=AutoQSL") else {
            return nil
        }
        
        do {
            let (data, _) = try await urlSession.data(from: url)
            guard let xmlString = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                return nil
            }
            
            // Check for session errors / timeout
            if let errorMsg = HamQTHXMLParser.extractTag("error", from: xmlString) {
                if errorMsg.localizedCaseInsensitiveContains("session") || errorMsg.localizedCaseInsensitiveContains("does not exist") {
                    self.sessionId = nil
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
            
            let profile = HamQTHXMLParser.parseCallsignXML(xmlString)
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

public final class HamQTHXMLParser: Sendable {
    public static func extractTag(_ tag: String, from xml: String) -> String? {
        let pattern = "<\\s*\\b\\Q\(tag)\\E\\b[^>]*>([\\s\\S]*?)</\\s*\\b\\Q\(tag)\\E\\b\\s*>"
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
        guard let call = extractTag("callsign", from: xml) ?? extractTag("call", from: xml) else {
            return nil
        }
        
        let email = extractTag("email", from: xml)
        let nick = extractTag("nick", from: xml)
        let name = extractTag("name", from: xml) ?? extractTag("adr_name", from: xml)
        let addr1 = extractTag("adr_street1", from: xml)
        let addr2 = extractTag("adr_city", from: xml)
        let state = extractTag("us_state", from: xml)
        let zip = extractTag("adr_zip", from: xml)
        let country = extractTag("adr_country", from: xml) ?? extractTag("country", from: xml)
        let grid = extractTag("grid", from: xml)
        let cqzone = extractTag("cq", from: xml)
        let ituzone = extractTag("itu", from: xml)
        let county = extractTag("us_county", from: xml)
        let qslmgr = extractTag("qsl", from: xml)
        let lotw = (extractTag("lotw", from: xml)?.uppercased() == "Y" || extractTag("lotw", from: xml) == "1")
        let eqsl = (extractTag("eqsl", from: xml)?.uppercased() == "Y" || extractTag("eqsl", from: xml) == "1")
        let imageURL = extractTag("picture", from: xml)
        
        return QRZProfile(
            call: call,
            email: email,
            fname: nick,
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
