import Foundation

struct LibraryTransferSettings: Codable, Hashable {
    var colorSchemeOptionRawValue: String
    var aboutMeContext: String
    var selectedModelId: String
    var modelParameters: ModelParameters
    var aiSystemPrompt: String
    var aiQuickActions: [String]
    var ambientSuggestionsEnabled: Bool
    var captureDefaultRoute: CaptureRoute
    var historyRetentionDays: Int
    var historyMaxRevisions: Int
}

struct ArchivedNote: Codable, Hashable, Identifiable {
    let id: UUID
    let name: String
    let content: String
    let iconName: String
    let iconColorRawValue: String
    let order: Int
    let hasBeenAutoTitled: Bool
    let createdAt: Date
    let updatedAt: Date
    let lastOpenedAt: Date?
    let isPinned: Bool
    let tags: [String]
    let captureSource: NookCaptureSource
    let pendingAIProposal: PendingAIProposal?

    init(
        id: UUID,
        name: String,
        content: String,
        iconName: String,
        iconColorRawValue: String,
        order: Int,
        hasBeenAutoTitled: Bool,
        createdAt: Date,
        updatedAt: Date,
        lastOpenedAt: Date?,
        isPinned: Bool,
        tags: [String],
        captureSource: NookCaptureSource,
        pendingAIProposal: PendingAIProposal?
    ) {
        self.id = id
        self.name = name
        self.content = content
        self.iconName = iconName
        self.iconColorRawValue = iconColorRawValue
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

    init(nook: Nook, content: String) {
        self.init(
            id: nook.id,
            name: nook.name,
            content: content,
            iconName: nook.iconName,
            iconColorRawValue: nook.iconColor.rawValue,
            order: nook.order,
            hasBeenAutoTitled: nook.hasBeenAutoTitled,
            createdAt: nook.createdAt,
            updatedAt: nook.updatedAt,
            lastOpenedAt: nook.lastOpenedAt,
            isPinned: nook.isPinned,
            tags: nook.tags,
            captureSource: nook.captureSource,
            pendingAIProposal: nook.pendingAIProposal
        )
    }
}

struct RemiLibraryArchive: Codable, Hashable {
    static let currentVersion = 1

    let version: Int
    let exportedAt: Date
    let settings: LibraryTransferSettings
    let notes: [ArchivedNote]

    init(
        version: Int = Self.currentVersion,
        exportedAt: Date = Date(),
        settings: LibraryTransferSettings,
        notes: [ArchivedNote]
    ) {
        self.version = version
        self.exportedAt = exportedAt
        self.settings = settings
        self.notes = notes
    }
}

enum LibraryTransferError: LocalizedError {
    case unsupportedVersion(Int)
    case invalidArchive

    var errorDescription: String? {
        switch self {
        case .unsupportedVersion(let version):
            return "This JSON export uses an unsupported Remi archive format (version \(version))."
        case .invalidArchive:
            return "This file is not a valid Remi JSON export."
        }
    }
}

final class LibraryTransferService {
    static let shared = LibraryTransferService()

    private static let fractionalDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let fallbackDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    private init() {}

    func exportData(notes: [ArchivedNote], settings: LibraryTransferSettings) throws -> Data {
        let archive = RemiLibraryArchive(settings: settings, notes: notes)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Self.fractionalDateFormatter.string(from: date))
        }
        return try encoder.encode(archive)
    }

    func importArchive(from data: Data) throws -> RemiLibraryArchive {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let rawValue = try container.decode(String.self)
            if let date = Self.fractionalDateFormatter.date(from: rawValue) ?? Self.fallbackDateFormatter.date(from: rawValue) {
                return date
            }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid ISO8601 date: \(rawValue)")
        }

        let archive: RemiLibraryArchive
        do {
            archive = try decoder.decode(RemiLibraryArchive.self, from: data)
        } catch {
            throw LibraryTransferError.invalidArchive
        }

        guard archive.version == RemiLibraryArchive.currentVersion else {
            throw LibraryTransferError.unsupportedVersion(archive.version)
        }

        return archive
    }
}
