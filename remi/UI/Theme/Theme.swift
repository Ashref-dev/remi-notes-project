import SwiftUI
import Foundation
import CoreGraphics

// Defines the color palette for the Remi app, with support for both light and dark modes.
// These colors are defined in the App/Assets.xcassets file.
struct AppColors {
    static let background: Color = Color("BackgroundColor")
    static let backgroundSecondary: Color = Color("BackgroundSecondaryColor")
    
    static let textPrimary: Color = Color("TextPrimaryColor")
    static let textSecondary: Color = Color("TextSecondaryColor")
    
    static let cardBackground: Color = Color("CardBackgroundColor")
    static let cardBackgroundHover: Color = Color("CardBackgroundHoverColor")
    static let cardBackgroundSelected: Color = Color.accentColor.opacity(0.3) // Programmatically defined
    
    static let accent: Color = .accentColor
    static let border: Color = Color.primary.opacity(0.1) // Programmatically defined
}

// Defines spacing, corner radius, and other layout constants for the Remi app.
struct AppTheme {
    struct Spacing {
        static let xsmall: CGFloat = 4.0
        static let small: CGFloat = 8.0
        static let medium: CGFloat = 12.0
        static let large: CGFloat = 16.0
        static let xlarge: CGFloat = 24.0
    }
    
    struct CornerRadius {
        static let small: CGFloat = 8.0
        static let medium: CGFloat = 12.0
    }

    struct Fonts {
        static let editor: NSFont = .monospacedSystemFont(ofSize: 16, weight: .regular)
    }
    
    struct Popover {
        static let width: CGFloat = 480
        static let height: CGFloat = 520
    }
}