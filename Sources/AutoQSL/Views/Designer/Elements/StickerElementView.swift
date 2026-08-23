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
    }
}

public struct ARRLDiamondShape: View {
    public var body: some View {
        ZStack {
            // Outer Diamond
            Diamond()
                .fill(Color(red: 0.96, green: 0.77, blue: 0.09))
                .overlay(Diamond().stroke(Color.black, lineWidth: 3))
            
            // Inner Diamond
            Diamond()
                .inset(by: 8)
                .fill(Color.black)
                .overlay(Diamond().inset(by: 8).stroke(Color(red: 0.96, green: 0.77, blue: 0.09), lineWidth: 2))
            
            // Stylized ARRL Letters and Antenna symbol
            VStack(spacing: 2) {
                Text("A")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                
                HStack(spacing: 8) {
                    Text("R")
                        .font(.system(size: 16, weight: .black, design: .serif))
                        .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                    
                    // Center Antenna Coil
                    VStack(spacing: 1) {
                        Rectangle()
                            .fill(Color(red: 0.96, green: 0.77, blue: 0.09))
                            .frame(width: 2, height: 10)
                        Circle()
                            .stroke(Color(red: 0.96, green: 0.77, blue: 0.09), lineWidth: 1.5)
                            .frame(width: 14, height: 6)
                        Circle()
                            .stroke(Color(red: 0.96, green: 0.77, blue: 0.09), lineWidth: 1.5)
                            .frame(width: 14, height: 6)
                        Rectangle()
                            .fill(Color(red: 0.96, green: 0.77, blue: 0.09))
                            .frame(width: 2, height: 10)
                    }
                    
                    Text("R")
                        .font(.system(size: 16, weight: .black, design: .serif))
                        .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
                }
                
                Text("L")
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundColor(Color(red: 0.96, green: 0.77, blue: 0.09))
            }
        }
        .shadow(color: .black.opacity(0.6), radius: 4, x: 2, y: 2)
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
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.15, green: 0.45, blue: 0.25), Color(red: 0.08, green: 0.28, blue: 0.15)], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
            
            VStack(spacing: 2) {
                Image(systemName: "tree.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                Text("POTA")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("PARKS ON THE AIR")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
    }
}

public struct IOTABadgeView: View {
    public var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.05, green: 0.45, blue: 0.75), Color(red: 0.01, green: 0.25, blue: 0.55)], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
            
            VStack(spacing: 2) {
                Image(systemName: "water.waves")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text("IOTA")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("ISLANDS ON THE AIR")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
    }
}

public struct SOTABadgeView: View {
    public var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [Color(red: 0.75, green: 0.45, blue: 0.15), Color(red: 0.45, green: 0.25, blue: 0.08)], startPoint: .top, endPoint: .bottom))
                .overlay(Circle().stroke(Color.white, lineWidth: 3))
            
            VStack(spacing: 2) {
                Image(systemName: "mountain.2.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.white)
                Text("SOTA")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("SUMMITS ON THE AIR")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
    }
}

public struct CQBadgeView: View {
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color.red, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 2))
            VStack(spacing: 2) {
                Text("CQ")
                    .font(.system(size: 24, weight: .black))
                    .foregroundColor(.white)
                Text("WPX / DX")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
    }
}

public struct WASBadgeView: View {
    public var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(LinearGradient(colors: [Color.blue, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white, lineWidth: 2))
            VStack(spacing: 2) {
                Text("WAS")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.white)
                Text("ALL STATES")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 4, x: 2, y: 2)
    }
}
