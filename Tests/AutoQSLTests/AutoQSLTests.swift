import XCTest
@testable import AutoQSL

final class AutoQSLTests: XCTestCase {
    
    func testADIFParser() {
        let adifSample = """
        <CALL:5>DJ6GI<QSO_DATE:8>20260820<TIME_ON:4>2011<BAND:3>20m<MODE:3>FT4<RST_SENT:3>-13<RST_RCVD:3>-10<GRIDSQUARE:6>JN58td<NAME:9>Gerd Ihde<EMAIL:17>dj6gi@example.com<COMMENT:40>73, Thanks for the QSO. Good DX to you!<EOR>
        """
        
        let records = ADIFParser.parse(text: adifSample)
        XCTAssertEqual(records.count, 1)
        
        let rec = records[0]
        XCTAssertEqual(rec.dxCall, "DJ6GI")
        XCTAssertEqual(rec.band, "20m")
        XCTAssertEqual(rec.mode, "FT4")
        XCTAssertEqual(rec.rstSent, "-13")
        XCTAssertEqual(rec.rstRcvd, "-10")
        XCTAssertEqual(rec.dxGrid, "JN58td")
        XCTAssertEqual(rec.dxName, "Gerd Ihde")
        XCTAssertEqual(rec.dxEmail, "dj6gi@example.com")
        XCTAssertNotNil(rec.qsoDate)
    }
    
    func testQRZXMLParser() {
        let sampleXML = """
        <QRZDatabase version="1.36">
            <Callsign>
                <call>DJ6GI</call>
                <fname>Gerd</fname>
                <name>Ihde</name>
                <addr2>Munich</addr2>
                <country>Germany</country>
                <grid>JN58td</grid>
                <email>dj6gi@example.com</email>
                <cqzone>14</cqzone>
                <ituzone>28</ituzone>
            </Callsign>
            <Session>
                <Key>test-session-key-12345</Key>
                <Count>15</Count>
            </Session>
        </QRZDatabase>
        """
        
        let profile = QRZXMLParser.parseCallsignXML(sampleXML)
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.call, "DJ6GI")
        XCTAssertEqual(profile?.email, "dj6gi@example.com")
        XCTAssertEqual(profile?.fullName, "Gerd Ihde")
        XCTAssertEqual(profile?.grid, "JN58td")
        XCTAssertEqual(profile?.cqZone, "14")
        XCTAssertEqual(profile?.ituZone, "28")
        
        let sessionKey = QRZXMLParser.extractTag("Key", from: sampleXML)
        XCTAssertEqual(sessionKey, "test-session-key-12345")
    }
    
    func testEmailTemplateEngine() {
        let qso = QSO(
            dxCall: "DJ6GI",
            band: "20m",
            mode: "FT4",
            rstSent: "-13",
            rstRcvd: "-10",
            comment: "73, Thanks for the QSO!",
            myCall: "KG4OJT",
            myGrid: "FM18iv",
            myName: "Pete Norloff",
            dxName: "Gerd Ihde",
            dxEmail: "dj6gi@example.com"
        )
        let settings = AppSettings(
            myCallsign: "KG4OJT",
            myName: "Pete Norloff",
            myGrid: "FM18iv"
        )
        
        let template = "eQSL from {MY_CALL} to {DX_CALL} for {BAND} {MODE} QSO. 73 {DX_NAME}!"
        let rendered = EmailTemplateEngine.render(template: template, qso: qso, settings: settings)
        
        XCTAssertEqual(rendered, "eQSL from KG4OJT to DJ6GI for 20m FT4 QSO. 73 Gerd Ihde!")
    }
    
    func testWSJTXPacketParser() {
        var data = Data()
        // Magic
        var magic = UInt32(0xADBCCBDA).bigEndian
        data.append(Data(bytes: &magic, count: 4))
        // Schema
        var schema = UInt32(2).bigEndian
        data.append(Data(bytes: &schema, count: 4))
        // Type 5 (QSOLogged)
        var msgType = UInt32(5).bigEndian
        data.append(Data(bytes: &msgType, count: 4))
        
        // Helper to append Qt String
        func appendString(_ str: String) {
            var len = UInt32(str.utf8.count).bigEndian
            data.append(Data(bytes: &len, count: 4))
            data.append(contentsOf: str.utf8)
        }
        
        // ID
        appendString("WSJT-X")
        // Date-Off (Julian day 2460543, msecs 72660000, timespec 1)
        var jd = Int64(2460543).bigEndian
        data.append(Data(bytes: &jd, count: 8))
        var msecs = UInt32(72660000).bigEndian
        data.append(Data(bytes: &msecs, count: 4))
        let ts: UInt8 = 1
        data.append(ts)
        
        // DX Call
        appendString("DJ6GI")
        // DX Grid
        appendString("JN58td")
        // Freq Hz
        var freq = UInt64(14074000).bigEndian
        data.append(Data(bytes: &freq, count: 8))
        // Mode
        appendString("FT8")
        // RST Sent
        appendString("-10")
        // RST Rcvd
        appendString("-12")
        // TX Power
        appendString("50")
        // Comments
        appendString("73 TU")
        // Name
        appendString("Gerd")
        
        let record = WSJTXParser.parse(data: data)
        XCTAssertNotNil(record)
        XCTAssertEqual(record?.dxCall, "DJ6GI")
        XCTAssertEqual(record?.dxGrid, "JN58td")
        XCTAssertEqual(record?.mode, "FT8")
        XCTAssertEqual(record?.reportSent, "-10")
        XCTAssertEqual(record?.reportRcvd, "-12")
        XCTAssertEqual(record?.name, "Gerd")
        XCTAssertEqual(record?.comments, "73 TU")
    }
}
