import Foundation
import SwiftUI

enum NookCaptureSource: String, Codable, CaseIterable, Hashable {
    case manual
    case quickCapture
    case service
    case shareExtension
    case appIntent
}

struct PendingAIProposal: Codable, Hashable {
    var prompt: String
    var proposedText: String
    var summary: String
    var createdAt: Date
}

struct Nook: Identifiable, Hashable {
    let id: UUID
    var name: String
    var url: URL
    var iconName: String
    var iconColor: NookIconColor
    var order: Int
    var hasBeenAutoTitled: Bool
    var createdAt: Date
    var updatedAt: Date
    var lastOpenedAt: Date?
    var isPinned: Bool
    var tags: [String]
    var captureSource: NookCaptureSource
    var pendingAIProposal: PendingAIProposal?

    init(
        id: UUID = UUID(),
        name: String,
        url: URL,
        iconName: String = "doc.text.fill",
        iconColor: NookIconColor = .blue,
        order: Int = 0,
        hasBeenAutoTitled: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        isPinned: Bool = false,
        tags: [String] = [],
        captureSource: NookCaptureSource = .manual,
        pendingAIProposal: PendingAIProposal? = nil
    ) {
        self.id = id
        self.name = name
        self.url = url
        self.iconName = iconName
        self.iconColor = iconColor
        self.order = order
        self.hasBeenAutoTitled = hasBeenAutoTitled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.isPinned = isPinned
        self.tags = tags
        self.captureSource = captureSource
        self.pendingAIProposal = pendingAIProposal
    }

    static let inboxTag = "Inbox"

    var isInbox: Bool {
        tags.contains(Self.inboxTag)
    }

    var hasPendingAIWork: Bool {
        pendingAIProposal != nil
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
        case .blue: return Color(red: 0.3, green: 0.6, blue: 0.9)
        case .purple: return Color(red: 0.6, green: 0.4, blue: 0.8)
        case .pink: return Color(red: 0.9, green: 0.4, blue: 0.6)
        case .red: return Color(red: 0.85, green: 0.3, blue: 0.35)
        case .orange: return Color(red: 0.9, green: 0.55, blue: 0.2)
        case .yellow: return Color(red: 0.9, green: 0.75, blue: 0.2)
        case .green: return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .teal: return Color(red: 0.2, green: 0.65, blue: 0.65)
        case .indigo: return Color(red: 0.4, green: 0.45, blue: 0.85)
        case .gray: return Color(red: 0.55, green: 0.55, blue: 0.6)
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
