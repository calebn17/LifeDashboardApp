import SwiftUI

enum AppTheme {
    enum Colors {
        static let background = Color(hex: 0x000000)
        static let surface = Color(hex: 0x131317)
        static let cardBackground = Color.white.opacity(0.05)
        static let accentGreen = Color(hex: 0x4EDEA3)
        static let accentBlue = Color(hex: 0xADC6FF)
        static let onSurface = Color(hex: 0xE4E1E7)
        static let onSurfaceSecondary = Color(hex: 0xE4E1E7).opacity(0.6)
        static let cardBorderStart = Color.white.opacity(0.10)
        static let cardBorderEnd = Color.white.opacity(0.0)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 16
        static let button: CGFloat = 8
    }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1.0) {
        let red = Double((hex >> 16) & 0xFF) / 255.0
        let green = Double((hex >> 8) & 0xFF) / 255.0
        let blue = Double(hex & 0xFF) / 255.0
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
