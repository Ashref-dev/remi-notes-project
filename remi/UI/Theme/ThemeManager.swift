import SwiftUI

// MARK: - Theme Protocol
protocol Theme {
    var background: Color { get }
    var backgroundSecondary: Color { get }
    var textPrimary: Color { get }
    var textSecondary: Color { get }
    var cardBackground: Color { get }
    var cardBackgroundHover: Color { get }
    var cardBackgroundSelected: Color { get }
    var accent: Color { get }
    var border: Color { get }
}

// MARK: - Light Theme
struct LightTheme: Theme {
    let background = Color(hex: "#F2F2F7")
    let backgroundSecondary = Color(hex: "#FFFFFF")
    let textPrimary = Color(hex: "#000000")
    let textSecondary = Color(hex: "#6E6E73")
    let cardBackground = Color(hex: "#FFFFFF")
    let cardBackgroundHover = Color(hex: "#E5E5E7")
    let cardBackgroundSelected = Color.accentColor.opacity(0.2)
    let accent = Color.accentColor
    let border = Color(hex: "#D1D1D6")
}

// MARK: - Dark Theme
struct DarkTheme: Theme {
    let background = Color(hex: "#1C1C1E")
    let backgroundSecondary = Color(hex: "#2C2C2E")
    let textPrimary = Color(hex: "#E5E5E7")
    let textSecondary = Color(hex: "#8E8E93")
    let cardBackground = Color(hex: "#2C2C2E")
    let cardBackgroundHover = Color(hex: "#3A3A3C")
    let cardBackgroundSelected = Color.accentColor.opacity(0.3)
    let accent = Color.accentColor
    let border = Color(hex: "#38383A")
}

// MARK: - ThemeManager
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme = DarkTheme() // Default theme

    func applyTheme(for colorScheme: ColorScheme) {
        switch colorScheme {
        case .light:
            currentTheme = LightTheme()
        case .dark:
            currentTheme = DarkTheme()
        @unknown default:
            currentTheme = DarkTheme()
        }
    }
}
