
import SwiftUI

struct ColorPalette {
    // MARK: - Base Colors
    static let background = Color(hex: "#1C1C1E")
    static let backgroundSecondary = Color(hex: "#2C2C2E")
    
    // MARK: - Text Colors
    static let textPrimary = Color(hex: "#E5E5E7")
    static let textSecondary = Color(hex: "#8E8E93")
    
    // MARK: - Card Colors
    static let cardBackground = Color(hex: "#2C2C2E")
    static let cardBackgroundHover = Color(hex: "#3A3A3C")
    static let cardBackgroundSelected = Color.accentColor.opacity(0.3)
    
    // MARK: - Accent & Utility
    static let accent = Color.accentColor
    static let border = Color.primary.opacity(0.1)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
