import SwiftUI

// MARK: - Color Palette
extension Color {
    // Pine (Primary) – deep forest greens
    static let pineDark    = Color(hex: "#1A2421")
    static let pineMedium  = Color(hex: "#2C4C3B")

    // Soil (Accent) – earthy orange/brown
    static let soil        = Color(hex: "#C85A28")

    // Moonlit (Background) – warm off-white
    static let moonlit     = Color(hex: "#F5F7F2")
    static let moonlitCard = Color(hex: "#EDEEF0")

    // Utility
    static let glassFill   = Color.white.opacity(0.12)
    static let glassBorder = Color.white.opacity(0.25)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red:   Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Gradients
extension LinearGradient {
    static let pinePrimary = LinearGradient(
        colors: [Color.pineDark, Color.pineMedium],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let soilAccent = LinearGradient(
        colors: [Color.soil, Color(hex: "#E07040")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let logShiftButton = LinearGradient(
        colors: [Color(hex: "#2C4C3B"), Color(hex: "#1A5C40"), Color(hex: "#C85A28")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Typography
struct AppFont {
    // Serif for headers — uses New York if available, falls back to Georgia
    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.custom("NewYork", size: size)
            .weight(weight)
    }

    // Sans-serif for body/UI — SF Pro Rounded
    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        Font.system(size: size, weight: weight, design: .rounded)
    }
}

// MARK: - Design Constants
enum AppDesign {
    static let cornerRadius: CGFloat      = 24
    static let smallCornerRadius: CGFloat = 14
    static let cardPadding: CGFloat       = 16
    static let screenPadding: CGFloat     = 20

    // Glassmorphism card shadow
    static var cardShadow: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.glassFill)
            .shadow(color: Color.pineDark.opacity(0.15), radius: 12, x: 0, y: 6)
    }
}
