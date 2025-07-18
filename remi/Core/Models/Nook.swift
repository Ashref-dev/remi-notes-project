import Foundation
import SwiftUI

struct Nook: Identifiable, Hashable {
    let id: UUID
    var name: String
    var url: URL
    var iconName: String
    var iconColor: NookIconColor

    init(id: UUID = UUID(), name: String, url: URL, iconName: String = "doc.text.fill", iconColor: NookIconColor = .blue) {
        self.id = id
        self.name = name
        self.url = url
        self.iconName = iconName
        self.iconColor = iconColor
    }
}

// MARK: - Nook Icon Color

enum NookIconColor: String, CaseIterable, Hashable {
    case blue = "blue"
    case purple = "purple"
    case pink = "pink"
    case red = "red"
    case orange = "orange"
    case yellow = "yellow"
    case green = "green"
    case teal = "teal"
    case indigo = "indigo"
    case gray = "gray"
    
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .indigo: return .indigo
        case .gray: return .gray
        }
    }
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Predefined Nook Icons

struct NookIcons {
    static let categories: [NookIconCategory] = [
        NookIconCategory(
            name: "Documents",
            icons: [
                "doc.text.fill",
                "doc.fill",
                "doc.plaintext.fill",
                "doc.richtext.fill",
                "note.text",
                "text.book.closed.fill"
            ]
        ),
        NookIconCategory(
            name: "Creative",
            icons: [
                "paintbrush.fill",
                "pencil.tip.crop.circle.fill",
                "camera.fill",
                "photo.fill",
                "music.note",
                "theatermasks.fill"
            ]
        ),
        NookIconCategory(
            name: "Work & Projects",
            icons: [
                "briefcase.fill",
                "folder.fill",
                "archivebox.fill",
                "tray.full.fill",
                "calendar",
                "checkmark.circle.fill"
            ]
        ),
        NookIconCategory(
            name: "Science & Learning",
            icons: [
                "brain.head.profile",
                "atom",
                "flask.fill",
                "books.vertical.fill",
                "graduationcap.fill",
                "lightbulb.fill"
            ]
        ),
        NookIconCategory(
            name: "Nature & Travel",
            icons: [
                "leaf.fill",
                "tree.fill",
                "mountain.2.fill",
                "globe.americas.fill",
                "airplane",
                "car.fill"
            ]
        ),
        NookIconCategory(
            name: "Personal",
            icons: [
                "heart.fill",
                "star.fill",
                "crown.fill",
                "gift.fill",
                "house.fill",
                "person.fill"
            ]
        )
    ]
    
    static let allIcons: [String] = categories.flatMap { $0.icons }
}

struct NookIconCategory {
    let name: String
    let icons: [String]
}
