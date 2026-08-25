import SwiftUI

public struct StickerElementView: View {
    public let stickerType: StickerType
    public let customImagePath: String?
    public let tintColor: Color?
    
    public init(stickerType: StickerType, customImagePath: String? = nil, tintColor: Color? = nil) {
        self.stickerType = stickerType
        self.customImagePath = customImagePath
        self.tintColor = tintColor
    }
    
    public var body: some View {
        Group {
            switch stickerType {
            case .arrl:
                ARRLDiamondShape()
            case .pota:
                POTABadgeView()
            case .iota:
                IOTABadgeView()
            case .sota:
                SOTABadgeView()
            case .cq:
                CQBadgeView()
            case .was:
                WASBadgeView()
            case .custom:
                if let path = customImagePath, let nsImage = NSImage(contentsOfFile: path) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Image(systemName: "photo.badge.checkmark")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.white)
                }
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

public struct ARRLDiamondShape: View {
    public var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let scale = s / 100.0
            
            ZStack {
                // Outer Diamond
                Diamond()
                    .fill(Color(red: 0.96, green: 0.77, blue: 0.09))
                    .overlay(Diamond().stroke(Color.black, lineWidth: max(1, 3 * scale)))
                
                // Inner Diamond
                Diamond()
                    .inset(by: 8 * scale)
                    .fill(Color.black)
                    .overlay(Diamond().inset(by: 8 * scale).stroke(Color(red: 0.96, green: 0.77, blue: 0.09), lineWidth: max(1, 2 * scale)))
                
                // Stylized ARRL Letters and Antenna symbol
                VStack(spacing: 2 * scale) {
                    Text("A")
                        .font(.system(size: 20 * scale, weight: .black, design: .serif))
                        .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                    
                    HStack(spacing: 6 * scale) {
                        Text("R")
                            .font(.system(size: 15 * scale, weight: .black, design: .serif))
                            .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                        
                        // Center Antenna Coil
                        VStack(spacing: 1 * scale) {
                            Rectangle()
                                .fill(Color(red: 0.96, green: 0.77, blue: 0.09))
                                .frame(width: max(1, 2 * scale), height: 9 * scale)
                            Circle()
                                .stroke(Color(red: 0.96, green: 0.77, blue: 0.09), lineWidth: max(1, 1.5 * scale))
                                .frame(width: 12 * scale, height: 5 * scale)
                            Circle()
                                .stroke(Color(red: 0.96, green: 0.77, blue: 0.09), lineWidth: max(1, 1.5 * scale))
                                .frame(width: 12 * scale, height: 5 * scale)
                            Rectangle()
                                .fill(Color(red: 0.96, green: 0.77, blue: 0.09))
                                .frame(width: max(1, 2 * scale), height: 9 * scale)
                        }
                        
                        Text("R")
                            .font(.system(size: 15 * scale, weight: .black, design: .serif))
                            .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                    }
                    
                    Text("L")
                        .font(.system(size: 20 * scale, weight: .black, design: .serif))
                        .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                }
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: .black.opacity(0.4), radius: 3 * scale, x: 1 * scale, y: 1 * scale)
        }
    }
}

public struct Diamond: InsettableShape {
    var insetAmount: CGFloat = 0

    public func inset(by amount: CGFloat) -> some InsettableShape {
        var diamond = self
        diamond.insetAmount += amount
        return diamond
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let minX = rect.minX + insetAmount
        let maxX = rect.maxX - insetAmount
        let minY = rect.minY + insetAmount
        let maxY = rect.maxY - insetAmount
        let midX = rect.midX
        let midY = rect.midY

        path.move(to: CGPoint(x: midX, y: minY))
        path.addLine(to: CGPoint(x: maxX, y: midY))
        path.addLine(to: CGPoint(x: midX, y: maxY))
        path.addLine(to: CGPoint(x: minX, y: midY))
        path.closeSubpath()
        return path
    }
}

public struct POTABadgeView: View {
    public var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let scale = s / 100.0
            
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.45, blue: 0.25), Color(red: 0.08, green: 0.28, blue: 0.15)], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(Color.white, lineWidth: max(1, 3 * scale)))
                
                VStack(spacing: 2 * scale) {
                    Image(systemName: "tree.fill")
                        .font(.system(size: 24 * scale))
                        .foregroundColor(.white)
                    Text("POTA")
                        .font(.system(size: 18 * scale, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("PARKS ON THE AIR")
                        .font(.system(size: 6.5 * scale, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(1)
                }
                .padding(4 * scale)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: .black.opacity(0.4), radius: 3 * scale, x: 1 * scale, y: 1 * scale)
        }
    }
}

public struct IOTABadgeView: View {
    public var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let scale = s / 100.0
            
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.05, green: 0.45, blue: 0.75), Color(red: 0.01, green: 0.25, blue: 0.55)], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(Color.white, lineWidth: max(1, 3 * scale)))
                
                VStack(spacing: 2 * scale) {
                    Image(systemName: "water.waves")
                        .font(.system(size: 22 * scale))
                        .foregroundColor(.white)
                    Text("IOTA")
                        .font(.system(size: 18 * scale, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("ISLANDS ON THE AIR")
                        .font(.system(size: 6.2 * scale, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(1)
                }
                .padding(4 * scale)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: .black.opacity(0.4), radius: 3 * scale, x: 1 * scale, y: 1 * scale)
        }
    }
}

public struct SOTABadgeView: View {
    public var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let scale = s / 100.0
            
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color(red: 0.75, green: 0.45, blue: 0.15), Color(red: 0.45, green: 0.25, blue: 0.08)], startPoint: .top, endPoint: .bottom))
                    .overlay(Circle().stroke(Color.white, lineWidth: max(1, 3 * scale)))
                
                VStack(spacing: 2 * scale) {
                    Image(systemName: "mountain.2.fill")
                        .font(.system(size: 22 * scale))
                        .foregroundColor(.white)
                    Text("SOTA")
                        .font(.system(size: 18 * scale, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                    Text("SUMMITS ON THE AIR")
                        .font(.system(size: 6.0 * scale, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(1)
                }
                .padding(4 * scale)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: .black.opacity(0.4), radius: 3 * scale, x: 1 * scale, y: 1 * scale)
        }
    }
}

public struct CQBadgeView: View {
    public var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let scale = s / 100.0
            
            ZStack {
                RoundedRectangle(cornerRadius: 12 * scale)
                    .fill(LinearGradient(colors: [Color.red, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 12 * scale).stroke(Color.white, lineWidth: max(1, 2.5 * scale)))
                
                VStack(spacing: 2 * scale) {
                    Text("CQ")
                        .font(.system(size: 24 * scale, weight: .black))
                        .foregroundColor(.white)
                    Text("WPX / DX")
                        .font(.system(size: 9 * scale, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(4 * scale)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: .black.opacity(0.4), radius: 3 * scale, x: 1 * scale, y: 1 * scale)
        }
    }
}

public struct WASBadgeView: View {
    public var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            let scale = s / 100.0
            
            ZStack {
                RoundedRectangle(cornerRadius: 12 * scale)
                    .fill(LinearGradient(colors: [Color.blue, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 12 * scale).stroke(Color.white, lineWidth: max(1, 2.5 * scale)))
                
                VStack(spacing: 2 * scale) {
                    Text("WAS")
                        .font(.system(size: 22 * scale, weight: .black))
                        .foregroundColor(.white)
                    Text("ALL STATES")
                        .font(.system(size: 7.5 * scale, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
                .padding(4 * scale)
            }
            .frame(width: s, height: s)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
            .shadow(color: .black.opacity(0.4), radius: 3 * scale, x: 1 * scale, y: 1 * scale)
        }
    }
}
