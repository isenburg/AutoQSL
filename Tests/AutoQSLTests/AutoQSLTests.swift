import XCTest
@testable import AutoQSL

final class AutoQSLTests: XCTestCase {
    
    func testRUMlogN1MMXMLParser() {
        let n1mmXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <contactinfo>
            <app>RUMlogNG</app>
            <station_name>DJ6GI</station_name>
            <timestamp>2026-08-25 14:05:00</timestamp>
            <mycall>DJ6GI</mycall>
            <band>20M</band>
            <rxfreq>1407400</rxfreq>
            <txfreq>1407400</txfreq>
            <operator>DJ6GI</operator>
            <mode>FT8</mode>
            <call>W1AW</call>
            <countryprefix>K</countryprefix>
            <snt>599</snt>
            <rcv>599</rcv>
            <grid>FN31pr</grid>
            <comment>73 via RUMlog</comment>
            <name>Hiram</name>
        </contactinfo>
        """
        
        let records = ADIFParser.parse(text: n1mmXML)
        XCTAssertEqual(records.count, 1)
        
        let rec = records[0]
        XCTAssertEqual(rec.dxCall, "W1AW")
        XCTAssertEqual(rec.band, "20m")
        XCTAssertEqual(rec.mode, "FT8")
        XCTAssertEqual(rec.freqMHz, 14.074)
        XCTAssertEqual(rec.rstSent, "599")
        XCTAssertEqual(rec.rstRcvd, "599")
        XCTAssertEqual(rec.dxGrid, "FN31pr")
        XCTAssertEqual(rec.dxName, "Hiram")
        XCTAssertEqual(rec.comment, "73 via RUMlog")
        XCTAssertNotNil(rec.qsoDate)
    }
    
    func testRUMlogADIFBroadcastParser() {
        let adifBroadcast = """
        <CALL:4>W1AW <QSO_DATE:8>20260825 <TIME_ON:6>120000 <BAND:3>20M <MODE:3>FT8 <FREQ:8>14.07400 <RST_SENT:3>599 <RST_RCVD:3>599 <GRIDSQUARE:6>FN31pr <NAME:5>Hiram <EOR>
        """
        
        let records = ADIFParser.parse(text: adifBroadcast)
        XCTAssertEqual(records.count, 1)
        
        let rec = records[0]
        XCTAssertEqual(rec.dxCall, "W1AW")
        XCTAssertEqual(rec.band, "20m")
        XCTAssertEqual(rec.mode, "FT8")
        XCTAssertEqual(rec.freqMHz, 14.074)
        XCTAssertEqual(rec.rstSent, "599")
        XCTAssertEqual(rec.rstRcvd, "599")
        XCTAssertEqual(rec.dxGrid, "FN31pr")
        XCTAssertEqual(rec.dxName, "Hiram")
    }

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
    
    func testHamQTHXMLParser() {
        let sampleXML = """
        <HamQTH version="2.7" xmlns="https://www.hamqth.com/xml/dtd/2.7">
            <session>
                <session_id>hamqth-test-session-98765</session_id>
            </session>
            <search>
                <callsign>DJ6GI</callsign>
                <nick>Georg</nick>
                <name>Georg Isenburger</name>
                <adr_name>Georg Isenburger</adr_name>
                <adr_street1>Heeresfliegerstr. 16</adr_street1>
                <adr_city>Hohenlockstedt</adr_city>
                <adr_zip>25551</adr_zip>
                <adr_country>Germany</adr_country>
                <grid>JO43sx</grid>
                <email>dj6gi@darc.de</email>
                <cq>14</cq>
                <itu>28</itu>
                <lotw>Y</lotw>
                <eqsl>Y</eqsl>
            </search>
        </HamQTH>
        """
        
        let profile = HamQTHXMLParser.parseCallsignXML(sampleXML)
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile?.call, "DJ6GI")
        XCTAssertEqual(profile?.email, "dj6gi@darc.de")
        XCTAssertEqual(profile?.fname, "Georg")
        XCTAssertEqual(profile?.name, "Georg Isenburger")
        XCTAssertEqual(profile?.grid, "JO43sx")
        XCTAssertEqual(profile?.cqZone, "14")
        XCTAssertEqual(profile?.ituZone, "28")
        XCTAssertEqual(profile?.country, "Germany")
        XCTAssertTrue(profile?.lotw ?? false)
        XCTAssertTrue(profile?.eqsl ?? false)
        
        let sessionId = HamQTHXMLParser.extractTag("session_id", from: sampleXML)
        XCTAssertEqual(sessionId, "hamqth-test-session-98765")
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
    
    @MainActor
    func testQSOEditingAndCustomTemplate() {
        let appState = AppState()
        var qso = QSO(dxCall: "DL1ABC", band: "20m", mode: "FT8", rstSent: "-10", rstRcvd: "-12")
        defer {
            appState.deleteQSO(qsoId: qso.id)
        }
        appState.qsoQueue.append(qso)
        
        // Test updating QSO parameters
        qso.rstSent = "59"
        qso.rstRcvd = "59"
        qso.comment = "Special 73!"
        appState.updateQSO(qso, reRenderCard: false)
        
        let retrieved = appState.qsoQueue.first(where: { $0.id == qso.id })
        XCTAssertEqual(retrieved?.rstSent, "59")
        XCTAssertEqual(retrieved?.rstRcvd, "59")
        XCTAssertEqual(retrieved?.comment, "Special 73!")
        
        // Test custom template per QSO
        var customTmpl = QSLCardTemplate(name: "Custom DL1ABC Card")
        customTmpl.backgroundColorHex = "#FF0000"
        appState.setCustomTemplate(for: qso.id, template: customTmpl)
        
        let resolvedTmpl = appState.template(for: appState.qsoQueue.first(where: { $0.id == qso.id })!)
        XCTAssertEqual(resolvedTmpl.name, "Custom DL1ABC Card")
        XCTAssertEqual(resolvedTmpl.backgroundColorHex, "#FF0000")
    }

    func testRadioUtilsAndBandFrequencyCalculations() {
        XCTAssertEqual(RadioUtils.band(forFrequencyMHz: 14.074), "20m")
        XCTAssertEqual(RadioUtils.band(forFrequencyMHz: 7.074), "40m")
        XCTAssertEqual(RadioUtils.band(forFrequencyMHz: 3.573), "80m")
        XCTAssertEqual(RadioUtils.band(forFrequencyMHz: 144.174), "2m")
        XCTAssertEqual(RadioUtils.band(forFrequencyMHz: 432.174), "70cm")
        
        XCTAssertEqual(RadioUtils.defaultFrequencyMHz(for: "20m"), 14.074)
        XCTAssertEqual(RadioUtils.defaultFrequencyMHz(for: "40m"), 7.074)
        
        XCTAssertEqual(RadioUtils.parseFrequencyMHz(from: "14.074"), 14.074)
        XCTAssertEqual(RadioUtils.parseFrequencyMHz(from: "14,074"), 14.074)
        XCTAssertEqual(RadioUtils.parseFrequencyMHz(from: "14074 kHz"), 14.074)
        XCTAssertEqual(RadioUtils.parseFrequencyMHz(from: "14074000 Hz"), 14.074)
        XCTAssertEqual(RadioUtils.parseFrequencyMHz(from: "14.074 MHz"), 14.074)
    }
    
    @MainActor
    func testAddManualQSOWithCustomModeAndFrequency() {
        let appState = AppState()
        let initialCount = appState.qsoQueue.count
        
        appState.addManualQSO(
            dxCall: "W1AW",
            band: "60m",
            mode: "VARAC",
            frequencyHz: 5357000,
            rstSent: "+05",
            rstRcvd: "+02",
            comment: "Great custom mode QSO",
            dxEmail: "w1aw@arrl.org"
        )
        
        let added = appState.qsoQueue.first(where: { $0.dxCall == "W1AW" })
        defer {
            if let id = added?.id {
                appState.deleteQSO(qsoId: id)
            }
        }
        XCTAssertEqual(appState.qsoQueue.count, initialCount + 1)
        XCTAssertEqual(added?.dxCall, "W1AW")
        XCTAssertEqual(added?.band, "60m")
        XCTAssertEqual(added?.mode, "VARAC")
        XCTAssertEqual(added?.frequencyHz, 5357000)
        XCTAssertEqual(added?.rstSent, "+05")
        XCTAssertEqual(added?.comment, "Great custom mode QSO")
    }
}
