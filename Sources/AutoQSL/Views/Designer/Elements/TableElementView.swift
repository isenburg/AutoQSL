import SwiftUI

public struct TableElementView: View {
    public let element: CardElement
    public let qso: QSO?
    public let defaultComment: String
    public let dateOrder: DateOrder
    public let dateSeparator: DateSeparator
    public let dateHeaderStyle: DateHeaderStyle
    public let tableWidth: CGFloat
    
    public init(
        element: CardElement,
        qso: QSO?,
        defaultComment: String = "",
        dateOrder: DateOrder = .ddMMyyyy,
        dateSeparator: DateSeparator = .dot,
        dateHeaderStyle: DateHeaderStyle = .singleDate,
        tableWidth: CGFloat = 700
    ) {
        self.element = element
        self.qso = qso
        self.defaultComment = defaultComment
        self.dateOrder = dateOrder
        self.dateSeparator = dateSeparator
        self.dateHeaderStyle = dateHeaderStyle
        self.tableWidth = tableWidth
    }
    
    private var activeQSO: QSO {
        if let q = qso, !q.dxCall.isEmpty { return q }
        var dateComponents = DateComponents()
        dateComponents.year = 2026
        dateComponents.month = 8
        dateComponents.day = 23
        dateComponents.hour = 11
        dateComponents.minute = 15
        dateComponents.timeZone = TimeZone(secondsFromGMT: 0)
        let sampleDate = Calendar(identifier: .gregorian).date(from: dateComponents) ?? Date()
        
        return QSO(
            dxCall: "DJ6GI",
            band: "20m",
            mode: "FT8",
            frequencyHz: 14074000,
            qsoDate: sampleDate,
            rstSent: "-12",
            rstRcvd: "-08",
            comment: element.tableComment.isEmpty ? (defaultComment.isEmpty ? "73, Thanks for the QSO." : defaultComment) : element.tableComment
        )
    }
    
    private var formattedDateString: String {
        return activeQSO.formattedDate(order: dateOrder, separator: dateSeparator)
    }
    
    private var freqString: String {
        if let f = activeQSO.frequencyHz, f > 0 {
            return String(format: "%.3f MHz", f / 1_000_000.0)
        }
        if !activeQSO.band.isEmpty {
            return activeQSO.band
        }
        return "14.074 MHz"
    }
    
    public var body: some View {
        let totalW = max(tableWidth, 400.0)
        let isSplit = (dateHeaderStyle == .splitSubheaders)
        let wCall = totalW * (isSplit ? 0.24 : 0.25)
        let wDate = totalW * (isSplit ? 0.26 : 0.23)
        let wDateSub = wDate / 3.0
        let wTime = totalW * 0.13
        let wFreq = totalW * (isSplit ? 0.13 : 0.15)
        let wRST  = totalW * 0.12
        let wMode = totalW * 0.12
        
        VStack(spacing: 0) {
            // Header Row
            HStack(spacing: 0) {
                headerCell("Confirming QSO With", width: wCall)
                
                dividerVertical()
                
                if dateHeaderStyle == .splitSubheaders {
                    if dateOrder == .ddMMyyyy {
                        HStack(spacing: 0) {
                            subHeaderCell("Day", width: wDateSub)
                            subHeaderCell("Month", width: wDateSub)
                            subHeaderCell("Year", width: wDateSub)
                        }
                        .frame(width: wDate)
                    } else {
                        HStack(spacing: 0) {
                            subHeaderCell("Year", width: wDateSub)
                            subHeaderCell("Month", width: wDateSub)
                            subHeaderCell("Day", width: wDateSub)
                        }
                        .frame(width: wDate)
                    }
                } else {
                    headerCell("Date", width: wDate)
                }
                
                dividerVertical()
                
                headerCell("UTC Time", width: wTime)
                
                dividerVertical()
                
                headerCell("Frequency", width: wFreq)
                
                dividerVertical()
                
                headerCell("Report", width: wRST)
                
                dividerVertical()
                
                headerCell("Mode", width: wMode)
            }
            .frame(width: totalW)
            .background(Color(hex: element.tableHeaderBackgroundHex).opacity(element.tableHeaderBackgroundOpacity))
            
            dividerHorizontal()
            
            // Data Row
            HStack(spacing: 0) {
                dataCell(activeQSO.dxCall.isEmpty ? "DJ6GI" : activeQSO.dxCall, width: wCall, isBold: true)
                
                dividerVertical()
                
                if dateHeaderStyle == .splitSubheaders {
                    if dateOrder == .ddMMyyyy {
                        HStack(spacing: 0) {
                            subDataCell(activeQSO.formattedDateDay, width: wDateSub)
                            subDataCell(activeQSO.formattedDateMonth, width: wDateSub)
                            subDataCell(activeQSO.formattedDateYear, width: wDateSub)
                        }
                        .frame(width: wDate)
                    } else {
                        HStack(spacing: 0) {
                            subDataCell(activeQSO.formattedDateYear, width: wDateSub)
                            subDataCell(activeQSO.formattedDateMonth, width: wDateSub)
                            subDataCell(activeQSO.formattedDateDay, width: wDateSub)
                        }
                        .frame(width: wDate)
                    }
                } else {
                    dataCell(formattedDateString, width: wDate)
                }
                
                dividerVertical()
                
                dataCell(activeQSO.formattedUTCTime.isEmpty ? "11:15" : activeQSO.formattedUTCTime, width: wTime)
                
                dividerVertical()
                
                dataCell(freqString, width: wFreq)
                
                dividerVertical()
                
                dataCell(activeQSO.rstSent.isEmpty ? "-12" : activeQSO.rstSent, width: wRST)
                
                dividerVertical()
                
                dataCell(activeQSO.mode.isEmpty ? "FT8" : activeQSO.mode, width: wMode)
            }
            .frame(width: totalW)
            
            dividerHorizontal()
            
            // Remarks Row
            HStack(spacing: 0) {
                Text(remarksText)
                    .font(getFont(size: CGFloat(element.fontSize * 0.85), isHeader: false))
                    .foregroundColor(Color(hex: element.textColorHex))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                Spacer()
            }
            .frame(width: totalW, alignment: .leading)
        }
        .frame(width: totalW)
        .background(Color(hex: element.tableBackgroundColorHex).opacity(element.tableBackgroundOpacity))
        .overlay(
            Rectangle()
                .stroke(Color(hex: element.tableBorderColorHex), lineWidth: CGFloat(element.tableBorderWidth))
        )
        .shadow(color: element.isShadowEnabled ? .black.opacity(element.shadowOpacity) : .clear, radius: element.isShadowEnabled ? CGFloat(element.shadowRadius) : 0, x: element.isShadowEnabled ? CGFloat(element.shadowX) : 0, y: element.isShadowEnabled ? CGFloat(element.shadowY) : 0)
    }
    
        private var remarksText: String {
        let elComment = element.tableComment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !elComment.isEmpty {
            return element.tableComment
        }
        let qComment = activeQSO.comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !qComment.isEmpty {
            return activeQSO.comment
        }
        return defaultComment.isEmpty ? "73, Thanks for the QSO." : defaultComment
    }

    private func headerCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(getFont(size: CGFloat(element.fontSize * 0.85), isHeader: true))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.60)
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .frame(width: width)
    }
    
    private func subHeaderCell(_ title: String, width: CGFloat) -> some View {
        Text(title)
            .font(getFont(size: CGFloat(element.fontSize * 0.85), isHeader: true))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.60)
            .padding(.vertical, 4)
            .frame(width: width)
    }
    
    private func dataCell(_ value: String, width: CGFloat, isBold: Bool = false) -> some View {
        Text(value)
            .font(getFont(size: CGFloat(element.fontSize * 0.95), isHeader: isBold))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.60)
            .padding(.vertical, 4)
            .padding(.horizontal, 2)
            .frame(width: width)
    }
    
    private func subDataCell(_ value: String, width: CGFloat) -> some View {
        Text(value)
            .font(getFont(size: CGFloat(element.fontSize * 0.95), isHeader: false))
            .foregroundColor(Color(hex: element.textColorHex))
            .multilineTextAlignment(.center)
            .lineLimit(1)
            .minimumScaleFactor(0.60)
            .padding(.vertical, 4)
            .frame(width: width)
    }
    
    private func getFont(size: CGFloat, isHeader: Bool) -> Font {
        var f: Font
        switch element.fontName {
        case "System": f = .system(size: size)
        case "System Rounded": f = .system(size: size, design: .rounded)
        case "System Serif": f = .system(size: size, design: .serif)
        case "System Monospaced": f = .system(size: size, design: .monospaced)
        case "Helvetica": f = .custom("Helvetica", size: size)
        case "Arial": f = .custom("Arial", size: size)
        case "Impact": f = .custom("Impact", size: size)
        case "Times New Roman": f = .custom("Times New Roman", size: size)
        case "Courier New", "Courier": f = .custom("Courier New", size: size)
        case "Georgia": f = .custom("Georgia", size: size)
        case "Menlo": f = .custom("Menlo", size: size)
        case "Trebuchet MS": f = .custom("Trebuchet MS", size: size)
        default: f = .system(size: size)
        }
        if element.isBold || isHeader {
            f = f.bold()
        }
        if element.isItalic {
            f = f.italic()
        }
        return f
    }
    
    private func dividerVertical() -> some View {
        Rectangle()
            .fill(Color(hex: element.tableBorderColorHex))
            .frame(width: CGFloat(element.tableBorderWidth))
    }
    
    private func dividerHorizontal() -> some View {
        Rectangle()
            .fill(Color(hex: element.tableBorderColorHex))
            .frame(height: CGFloat(element.tableBorderWidth))
    }
}
