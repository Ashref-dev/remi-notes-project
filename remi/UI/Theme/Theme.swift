import CoreFoundation
import AppKit


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
