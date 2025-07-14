import CoreFoundation
import AppKit
import SwiftUI


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
        static let editor: NSFont = .systemFont(ofSize: 16, weight: .regular)
        static let title: SwiftUI.Font = .title.weight(.bold)
        static let title2: SwiftUI.Font = .title2.weight(.bold)
        static let title3: SwiftUI.Font = .title3.weight(.semibold)
        static let body: SwiftUI.Font = .body
        static let caption: SwiftUI.Font = .caption
    }
    
    struct Popover {
        static let width: CGFloat = 900
        static let height: CGFloat = 720
    }
}
