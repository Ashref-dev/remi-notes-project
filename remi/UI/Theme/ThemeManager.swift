import SwiftUI
import AppKit

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
    let background = Color(NSColor.windowBackgroundColor)
    let backgroundSecondary = Color(NSColor.controlBackgroundColor)
    let textPrimary = Color(NSColor.labelColor)
    let textSecondary = Color(NSColor.secondaryLabelColor)
    let cardBackground = Color(NSColor.controlBackgroundColor)
    let cardBackgroundHover = Color(NSColor.selectedControlColor)
    let cardBackgroundSelected = Color(NSColor.controlAccentColor).opacity(0.2)
    let accent = Color(NSColor.controlAccentColor)
    let border = Color(NSColor.separatorColor)
}

// MARK: - Dark Theme
struct DarkTheme: Theme {
    let background = Color(NSColor.windowBackgroundColor)
    let backgroundSecondary = Color(NSColor.controlBackgroundColor)
    let textPrimary = Color(NSColor.labelColor)
    let textSecondary = Color(NSColor.secondaryLabelColor)
    let cardBackground = Color(NSColor.controlBackgroundColor)
    let cardBackgroundHover = Color(NSColor.selectedControlColor)
    let cardBackgroundSelected = Color(NSColor.controlAccentColor).opacity(0.3)
    let accent = Color(NSColor.controlAccentColor)
    let border = Color(NSColor.separatorColor)
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
