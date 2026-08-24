import Foundation

public final class PrefixMatcher {
    public static let shared = PrefixMatcher()
    
    private let lock = NSLock()
    private var database: [String: String] = [:]
    private var continentDatabase: [String: String] = [:]
    private var cqZoneDatabase: [String: Int] = [:]
    private var ituZoneDatabase: [String: Int] = [:]
    private var countryCoordinates: [String: (latitude: Double, longitude: Double)] = [:]
    public var lastUpdate: Date?
    
    public init() {
        loadBasicData()
    }
    
    public func country(for callsign: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return database[prefix] ?? "OTHER"
    }
    
    public func continent(for callsign: String) -> String {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return continentDatabase[prefix] ?? "OTHER"
    }
    
    public func cqZone(for callsign: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return cqZoneDatabase[prefix]
    }
    
    public func ituZone(for callsign: String) -> Int? {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        return ituZoneDatabase[prefix]
    }
    
    public func coordinates(for callsign: String) -> (latitude: Double, longitude: Double)? {
        let countryName = country(for: callsign)
        guard countryName != "OTHER" && !countryName.isEmpty else { return nil }
        lock.lock()
        defer { lock.unlock() }
        return countryCoordinates[countryName]
    }
    
    public func info(for callsign: String) -> (country: String, cqZone: Int?, ituZone: Int?, continent: String)? {
        lock.lock()
        defer { lock.unlock() }
        let prefix = findPrefix(for: callsign)
        guard let c = database[prefix], c != "OTHER" && !c.isEmpty else { return nil }
        return (
            country: c,
            cqZone: cqZoneDatabase[prefix],
            ituZone: ituZoneDatabase[prefix],
            continent: continentDatabase[prefix] ?? "OTHER"
        )
    }
    
    private func findPrefix(for callsign: String) -> String {
        let rawCall = callsign.uppercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if rawCall.isEmpty { return "" }
        
        let parts = rawCall.components(separatedBy: "/")
        if parts.count >= 2 {
            let p0 = parts[0]
            let p1 = parts[1]
            let modifiers = ["P", "M", "MM", "AM", "QRP", "LH", "LGT", "R", "B"]
            if p0.count <= 4 && !modifiers.contains(p0) {
                let match0 = matchPrefix(p0)
                if !match0.isEmpty && database[match0] != nil {
                    return match0
                }
            }
            if p1.count <= 4 && !modifiers.contains(p1) {
                let match1 = matchPrefix(p1)
                if !match1.isEmpty && database[match1] != nil {
                    return match1
                }
            }
            let mainPart = p0.count >= p1.count ? p0 : p1
            return matchPrefix(mainPart)
        }
        
        return matchPrefix(rawCall)
    }

    private func matchPrefix(_ call: String) -> String {
        for length in (1...6).reversed() {
            if call.count >= length {
                let prefix = String(call.prefix(length))
                if database[prefix] != nil { return prefix }
            }
        }
        return ""
    }
    
    public func parseCtyDat(_ content: String) {
        var newDatabase: [String: String] = [:]
        var newContinents: [String: String] = [:]
        var newCQZones: [String: Int] = [:]
        var newITUZones: [String: Int] = [:]
        var newCoordinates: [String: (latitude: Double, longitude: Double)] = [:]
        
        let lines = content.components(separatedBy: .newlines)
        var currentCountry = ""
        var currentContinent = ""
        var currentCQZone: Int? = nil
        var currentITUZone: Int? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty { continue }
            
            if line.starts(with: " ") || line.starts(with: "\t") {
                if !currentCountry.isEmpty {
                    let prefixes = trimmed.replacingOccurrences(of: ";", with: "").components(separatedBy: ",")
                    for p in prefixes {
                        let cleanPrefix = p.trimmingCharacters(in: .whitespaces)
                        if !cleanPrefix.isEmpty {
                            var prefixContinent = currentContinent
                            if let startBracket = cleanPrefix.firstIndex(of: "["), 
                               let endBracket = cleanPrefix.firstIndex(of: "]") {
                                let override = String(cleanPrefix[cleanPrefix.index(after: startBracket)..<endBracket])
                                if override.count == 2 { prefixContinent = override }
                            }

                            var prefixCQZone = currentCQZone
                            if let startParen = cleanPrefix.firstIndex(of: "("), 
                               let endParen = cleanPrefix.firstIndex(of: ")") {
                                let override = String(cleanPrefix[cleanPrefix.index(after: startParen)..<endParen])
                                if let z = Int(override) { prefixCQZone = z }
                            }

                            var prefixITUZone = currentITUZone
                            if let startBrace = cleanPrefix.firstIndex(of: "{"), 
                               let endBrace = cleanPrefix.firstIndex(of: "}") {
                                let override = String(cleanPrefix[cleanPrefix.index(after: startBrace)..<endBrace])
                                if let z = Int(override) { prefixITUZone = z }
                            }
                            
                            let basePrefix = cleanPrefix.components(separatedBy: "(").first!
                                                        .components(separatedBy: "[").first!
                                                        .components(separatedBy: "{").first!
                                                        .trimmingCharacters(in: .whitespaces)
                            newDatabase[basePrefix] = currentCountry
                            newContinents[basePrefix] = prefixContinent
                            if let cq = prefixCQZone { newCQZones[basePrefix] = cq }
                            if let itu = prefixITUZone { newITUZones[basePrefix] = itu }
                        }
                    }
                }
            } else {
                let parts = line.components(separatedBy: ":").map { $0.trimmingCharacters(in: .whitespaces) }
                if parts.count >= 8 {
                    currentCountry = parts[0]
                    currentCQZone = Int(parts[1])
                    currentITUZone = Int(parts[2])
                    currentContinent = parts[3]
                    let primaryPrefix = parts[7]
                    
                    newDatabase[primaryPrefix] = currentCountry
                    newContinents[primaryPrefix] = currentContinent
                    if let cq = currentCQZone { newCQZones[primaryPrefix] = cq }
                    if let itu = currentITUZone { newITUZones[primaryPrefix] = itu }
                    
                    if let lat = Double(parts[4]), let lon = Double(parts[5]) {
                        newCoordinates[currentCountry] = (latitude: lat, longitude: -lon)
                    }
                }
            }
        }
        
        if !newDatabase.isEmpty {
            lock.lock()
            self.database = newDatabase
            self.continentDatabase = newContinents
            self.cqZoneDatabase = newCQZones
            self.ituZoneDatabase = newITUZones
            self.countryCoordinates = newCoordinates
            lock.unlock()
        }
    }
    
    private func loadBasicData() {
        let basic = "Germany: 14: 28: EU: 51.0: -10.0: -1.0: DL:\r\n DA,DB,DC,DD,DE,DF,DG,DH,DI,DJ,DK,DL,DM,DN,DO,DP,DQ,DR,Y2,Y3,Y4,Y5,Y6,Y7,Y8,Y9;\r\n" +
                    "United States: 05: 08: NA: 40.0: 100.0: 5.0: K:\r\n K,W,N,AA,AB,AC,AD,AE,AF,AG,AH,AI,AJ,AK,AL;\r\n" +
                    "Canada: 05: 09: NA: 60.0: 95.0: 5.0: VE:\r\n VE,VA,VO,VY,XJ,XK,XL,XM,XN,XO;\r\n" +
                    "United Kingdom: 14: 27: EU: 54.0: 2.0: 0.0: G:\r\n G,GX,M,MQ,2A,2E,2I,2M,2O,2Q,2W;\r\n" +
                    "France: 14: 27: EU: 46.0: -2.0: -1.0: F:\r\n F,HW,HX,HY,TK,TM,TO,TP,TQ,TV,TX;\r\n" +
                    "Spain: 14: 37: EU: 40.0: 4.0: 0.0: EA:\r\n EA,EB,EC,ED,EE,EF,EG,EH,AM,AN,AO;\r\n" +
                    "Italy: 15: 28: EU: 43.0: -12.0: -1.0: I:\r\n I,IK,IZ,IU,IA,IB,IC,ID,IE,IF,IG,IH,II,IL,IM,IN,IO,IP,IQ,IR,IS,IT,IV,IW,IX,IY;\r\n" +
                    "Japan: 25: 45: AS: 36.0: -138.0: -9.0: JA:\r\n JA,JE,JF,JG,JH,JI,JJ,JK,JL,JM,JN,JO,JP,JQ,JR,JS,7J,7K,7L,7M,7N,8J,8K,8L,8M,8N;\r\n" +
                    "Australia: 30: 59: OC: -25.0: -135.0: -10.0: VK:\r\n VK,AX;\r\n" +
                    "New Zealand: 32: 60: OC: -42.0: -174.0: -12.0: ZL:\r\n ZL,ZM;\r\n" +
                    "Brazil: 11: 18: SA: -10.0: 55.0: 3.0: PY:\r\n PP,PR,PS,PT,PU,PV,PW,PX,PY,ZV,ZW,ZX,ZY,ZZ;\r\n" +
                    "Argentina: 13: 14: SA: -34.0: 64.0: 3.0: LU:\r\n AY,AZ,L1,L2,L3,L4,L5,L6,L7,L8,L9,LO,LP,LQ,LR,LS,LT,LU,LV,LW;\r\n" +
                    "South Africa: 38: 57: AF: -29.0: -24.0: -2.0: ZS:\r\n ZR,ZS,ZT,ZU;\r\n" +
                    "Austria: 15: 28: EU: 47.3: -13.3: -1.0: OE:\r\n OE;\r\n" +
                    "Switzerland: 14: 28: EU: 47.0: -8.0: -1.0: HB:\r\n HB,HE,HB0;\r\n" +
                    "Netherlands: 14: 27: EU: 52.3: -5.5: -1.0: PA:\r\n PA,PB,PC,PD,PE,PF,PG,PH,PI;\r\n" +
                    "Belgium: 14: 27: EU: 50.8: -4.3: -1.0: ON:\r\n ON,OO,OP,OQ,OR,OS,OT;\r\n" +
                    "Poland: 15: 28: EU: 52.0: -20.0: -1.0: SP:\r\n 3Z,HF,SN,SO,SP,SQ,SR;\r\n" +
                    "Czech Republic: 15: 28: EU: 50.0: -15.0: -1.0: OK:\r\n OK,OL;\r\n" +
                    "Slovak Republic: 15: 28: EU: 48.7: -19.7: -1.0: OM:\r\n OM;\r\n" +
                    "Sweden: 14: 18: EU: 62.0: -15.0: -1.0: SM:\r\n 7S,8S,SA,SB,SC,SD,SE,SF,SG,SH,SI,SJ,SK,SL,SM;\r\n" +
                    "Norway: 14: 18: EU: 62.0: -10.0: -1.0: LA:\r\n 3Y,JW,JX,LA,LB,LC,LD,LE,LF,LG,LH,LI,LJ,LN;\r\n" +
                    "Finland: 15: 18: EU: 64.0: -26.0: -2.0: OH:\r\n OF,OG,OH,OI,OJ;\r\n" +
                    "Denmark: 14: 18: EU: 56.0: -10.0: -1.0: OZ:\r\n 5P,5Q,OU,OV,OW,OX,OY,OZ;\r\n" +
                    "Russia: 16: 20: EU: 55.0: -37.0: -3.0: UA:\r\n R,UA,UB,UC,UD,UE,UF,UG,UH,UI,RA,RN,RU,RV,RW,RX,RY,RZ;\r\n" +
                    "China: 24: 44: AS: 35.0: -105.0: -8.0: BY:\r\n B,BA,BD,BG,BH,BI,BJ,BL,BM,BN,BO,BP,BQ,BR,BS,BT,BU,BV,BW,BX,BY,BZ,XS;\r\n" +
                    "India: 22: 41: AS: 20.0: -77.0: -5.5: VU:\r\n AT,AU,AV,AW,VU;\r\n" +
                    "Madeira Islands: 33: 36: AF: 32.7: 16.8: 0.0: CT3:\r\n CT3,CQ3,CR3,CS3;\r\n"
        parseCtyDat(basic)
    }
    
    // MARK: - CTY.DAT Caching & Auto-Refresh
    private var ctyCacheURL: URL {
        let paths = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupport = paths[0].appendingPathComponent("com.dj6gi.AutoQSL", isDirectory: true)
        try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
        return appSupport.appendingPathComponent("cty_cache.dat")
    }

    public func loadCtyDatabase() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let cacheURL = self.ctyCacheURL
            if let savedDate = UserDefaults.standard.object(forKey: "autoqsl_cty_cache_date") as? Date,
               let content = try? String(contentsOf: cacheURL, encoding: .utf8) {
                self.parseCtyDat(content)
                self.lastUpdate = savedDate
                if abs(savedDate.timeIntervalSinceNow) > 1209600 {
                    self.updateCtyData()
                }
            } else {
                self.updateCtyData()
            }
        }
    }
    
    public func updateCtyData() {
        guard let url = URL(string: "https://www.country-files.com/cty/cty.dat") else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self = self else { return }
            if let data = data, let content = String(data: data, encoding: .utf8) {
                let now = Date()
                try? content.write(to: self.ctyCacheURL, atomically: true, encoding: .utf8)
                UserDefaults.standard.set(now, forKey: "autoqsl_cty_cache_date")
                self.parseCtyDat(content)
                self.lastUpdate = now
            }
        }.resume()
    }
}
