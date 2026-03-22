
import SwiftUI
import AppKit

struct ColorPalette {
    // MARK: - Native System Colors
    static let background = Color(NSColor.windowBackgroundColor)
    static let backgroundSecondary = Color(NSColor.controlBackgroundColor)
    
    // MARK: - Text Colors  
    static let textPrimary = Color(NSColor.labelColor)
    static let textSecondary = Color(NSColor.secondaryLabelColor)
    
    // MARK: - Card Colors
    static let cardBackground = Color(NSColor.controlBackgroundColor)
    static let cardBackgroundHover = Color(NSColor.selectedControlColor)
    static let cardBackgroundSelected = Color(NSColor.controlAccentColor).opacity(0.3)
    
    // MARK: - Accent & Utility
    static let accent = Color(NSColor.controlAccentColor)
    static let border = Color(NSColor.separatorColor)
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
