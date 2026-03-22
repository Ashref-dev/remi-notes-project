import Foundation

enum TodaySectionKind: String, CaseIterable, Identifiable {
    case pinned
    case editedToday
    case recent
    case inbox
    case pendingAI

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pinned: return "Pinned"
        case .editedToday: return "Edited Today"
        case .recent: return "Recent"
        case .inbox: return "Inbox"
        case .pendingAI: return "Pending AI"
        }
    }

    var subtitle: String {
        switch self {
        case .pinned: return "Important notes kept close"
        case .editedToday: return "Changed since midnight"
        case .recent: return "Opened most recently"
        case .inbox: return "Captured for later triage"
        case .pendingAI: return "Unapplied AI drafts"
        }
    }

    var systemImage: String {
        switch self {
        case .pinned: return "pin.fill"
        case .editedToday: return "clock.arrow.circlepath"
        case .recent: return "clock.fill"
        case .inbox: return "tray.full.fill"
        case .pendingAI: return "sparkles"
        }
    }
}

struct TodaySection: Identifiable {
    let kind: TodaySectionKind
    let nooks: [Nook]

    var id: String { kind.id }
    var title: String { kind.title }
    var subtitle: String { kind.subtitle }
    var systemImage: String { kind.systemImage }
}

final class TodayWorkspaceService {
    static let shared = TodayWorkspaceService()

    private init() {}

    func sections(from nooks: [Nook], now: Date = Date()) -> [TodaySection] {
        let calendar = Calendar.current

        func sortedOptional(_ items: [Nook], by keyPath: KeyPath<Nook, Date?>) -> [Nook] {
            items.sorted {
                ($0[keyPath: keyPath] ?? .distantPast) > ($1[keyPath: keyPath] ?? .distantPast)
            }
        }

        func sorted(_ items: [Nook], by keyPath: KeyPath<Nook, Date>) -> [Nook] {
            items.sorted { $0[keyPath: keyPath] > $1[keyPath: keyPath] }
        }

        let pinned = nooks.filter(\.isPinned)
        let editedToday = sorted(
            nooks.filter { calendar.isDate($0.updatedAt, inSameDayAs: now) },
            by: \.updatedAt
        )
        let recent = sortedOptional(
            nooks.filter { $0.lastOpenedAt != nil },
            by: \.lastOpenedAt
        )
        let inbox = sorted(
            nooks.filter(\.isInbox),
            by: \.updatedAt
        )
        let pendingAI = sorted(
            nooks.filter(\.hasPendingAIWork),
            by: \.updatedAt
        )

        return [
            TodaySection(kind: .pinned, nooks: pinned),
            TodaySection(kind: .editedToday, nooks: editedToday),
            TodaySection(kind: .recent, nooks: recent),
            TodaySection(kind: .inbox, nooks: inbox),
            TodaySection(kind: .pendingAI, nooks: pendingAI)
        ]
        .filter { !$0.nooks.isEmpty }
    }
}
