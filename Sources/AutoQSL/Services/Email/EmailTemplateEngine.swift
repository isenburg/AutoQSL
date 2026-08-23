import Foundation

public final class EmailTemplateEngine {
    public static func render(template: String, qso: QSO, settings: AppSettings) -> String {
        var text = template
        
        let substitutions: [String: String] = [
            "{DX_CALL}": qso.dxCall,
            "{CALL}": qso.dxCall,
            "{DX_NAME}": qso.dxName.isEmpty ? qso.dxCall : qso.dxName,
            "{NAME}": qso.dxName.isEmpty ? qso.dxCall : qso.dxName,
            "{DX_GRID}": qso.dxGrid,
            "{DX_EMAIL}": qso.dxEmail,
            "{DX_COUNTRY}": qso.dxCountry,
            "{DATE}": qso.formattedDate(order: settings.dateOrder, separator: settings.dateSeparator),
            "{TIME}": qso.formattedUTCTime,
            "{YEAR}": qso.formattedDateYear,
            "{MONTH}": qso.formattedDateMonth,
            "{DAY}": qso.formattedDateDay,
            "{BAND}": qso.band,
            "{MODE}": qso.mode,
            "{FREQ}": qso.frequencyHz != nil ? String(format: "%.3f MHz", qso.frequencyHz! / 1_000_000.0) : "",
            "{RST_SENT}": qso.rstSent,
            "{RST_RCVD}": qso.rstRcvd,
            "{COMMENT}": qso.comment,
            "{MY_CALL}": settings.myCallsign,
            "{MY_NAME}": settings.myName,
            "{MY_STREET}": settings.myStreet,
            "{MY_CITY}": settings.myCity,
            "{MY_STATE}": settings.myState,
            "{MY_COUNTRY}": settings.myCountry,
            "{MY_GRID}": settings.myGrid,
            "{MY_CQ}": settings.myCQZone,
            "{MY_ITU}": settings.myITUZone,
            "{MY_COUNTY}": settings.myCounty
        ]
        
        for (key, val) in substitutions {
            text = text.replacingOccurrences(of: key, with: val, options: .caseInsensitive)
        }
        
        return text
    }
}
