import Foundation

public struct QRZProfile: Codable, Hashable {
    public var call: String
    public var email: String?
    public var fname: String?
    public var name: String?
    public var addr1: String?
    public var addr2: String?
    public var state: String?
    public var zip: String?
    public var country: String?
    public var grid: String?
    public var cqZone: String?
    public var ituZone: String?
    public var county: String?
    public var qslmgr: String?
    public var lotw: Bool
    public var eqsl: Bool
    public var imageURL: String?
    
    public init(
        call: String,
        email: String? = nil,
        fname: String? = nil,
        name: String? = nil,
        addr1: String? = nil,
        addr2: String? = nil,
        state: String? = nil,
        zip: String? = nil,
        country: String? = nil,
        grid: String? = nil,
        cqZone: String? = nil,
        ituZone: String? = nil,
        county: String? = nil,
        qslmgr: String? = nil,
        lotw: Bool = false,
        eqsl: Bool = false,
        imageURL: String? = nil
    ) {
        self.call = call
        self.email = email
        self.fname = fname
        self.name = name
        self.addr1 = addr1
        self.addr2 = addr2
        self.state = state
        self.zip = zip
        self.country = country
        self.grid = grid
        self.cqZone = cqZone
        self.ituZone = ituZone
        self.county = county
        self.qslmgr = qslmgr
        self.lotw = lotw
        self.eqsl = eqsl
        self.imageURL = imageURL
    }
    
    public var fullName: String {
        let first = fname ?? ""
        let last = name ?? ""
        let combined = "\(first) \(last)".trimmingCharacters(in: .whitespacesAndNewlines)
        return combined.isEmpty ? call : combined
    }
    
    public var fullAddressFormatted: String {
        var lines: [String] = []
        if !fullName.isEmpty && fullName != call {
            lines.append(fullName)
        }
        if let a1 = addr1, !a1.isEmpty { lines.append(a1) }
        var cityStateZip: [String] = []
        if let a2 = addr2, !a2.isEmpty { cityStateZip.append(a2) }
        if let st = state, !st.isEmpty { cityStateZip.append(st) }
        if let zp = zip, !zp.isEmpty { cityStateZip.append(zp) }
        if !cityStateZip.isEmpty {
            lines.append(cityStateZip.joined(separator: ", "))
        }
        if let cntry = country, !cntry.isEmpty { lines.append(cntry) }
        return lines.joined(separator: "\n")
    }
}
