import Foundation
import OSLog

enum NoteRevisionSource: String, Codable, CaseIterable {
    case automatic
    case aiProposal
    case contentReplacement
    case restore
}

struct NoteRevision: Identifiable, Codable, Hashable {
    let id: UUID
    let noteID: UUID
    let createdAt: Date
    let source: NoteRevisionSource
    let summary: String
    let snapshotURL: URL
}

final class NoteHistoryService {
    static let shared = NoteHistoryService()

    private let fileManager = FileManager.default
    private let historyDirectory: URL
    private let logger = Logger(subsystem: "ashref.tn.remi", category: "NoteHistory")

    private init() {
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        self.historyDirectory = appSupportDirectory
            .appendingPathComponent("Remi")
            .appendingPathComponent("History")
    }

    @discardableResult
    func recordRevision(
        for note: Nook,
        content: String,
        source: NoteRevisionSource,
        summary: String? = nil
    ) -> NoteRevision? {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        do {
            let noteDirectory = try noteHistoryDirectory(for: note.id, createIfNeeded: true)
            let revisionID = UUID()
            let snapshotURL = noteDirectory.appendingPathComponent("\(revisionID.uuidString).md")
            let metadataURL = noteDirectory.appendingPathComponent("\(revisionID.uuidString).json")

            try trimmed.write(to: snapshotURL, atomically: true, encoding: .utf8)

            let revision = NoteRevision(
                id: revisionID,
                noteID: note.id,
                createdAt: Date(),
                source: source,
                summary: summary ?? defaultSummary(for: trimmed),
                snapshotURL: snapshotURL
            )

            let data = try JSONEncoder().encode(revision)
            try data.write(to: metadataURL, options: .atomic)

            pruneRevisions(for: note.id)
            return revision
        } catch {
            logger.error("Failed to record history revision: \(error.localizedDescription)")
            return nil
        }
    }

    func fetchRevisions(for noteID: UUID) -> [NoteRevision] {
        guard let noteDirectory = try? noteHistoryDirectory(for: noteID, createIfNeeded: false) else {
            return []
        }

        guard let urls = try? fileManager.contentsOfDirectory(
            at: noteDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        return urls
            .filter { $0.pathExtension == "json" }
            .compactMap { url in
                guard let data = try? Data(contentsOf: url) else { return nil }
                return try? JSONDecoder().decode(NoteRevision.self, from: data)
            }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func restoreRevision(_ revision: NoteRevision) throws -> String {
        try String(contentsOf: revision.snapshotURL, encoding: .utf8)
    }

    private func pruneRevisions(for noteID: UUID) {
        let revisions = fetchRevisions(for: noteID)
        let retentionDays = SettingsManager.shared.historyRetentionDays
        let maxRevisions = SettingsManager.shared.historyMaxRevisions
        let cutoff = Calendar.current.date(byAdding: .day, value: -retentionDays, to: Date()) ?? .distantPast

        for revision in revisions where revision.createdAt < cutoff {
            deleteRevisionFiles(for: revision)
        }

        let remaining = fetchRevisions(for: noteID)
        if remaining.count > maxRevisions {
            for revision in remaining.dropFirst(maxRevisions) {
                deleteRevisionFiles(for: revision)
            }
        }
    }

    private func deleteRevisionFiles(for revision: NoteRevision) {
        let metadataURL = revision.snapshotURL.deletingPathExtension().appendingPathExtension("json")
        try? fileManager.removeItem(at: revision.snapshotURL)
        try? fileManager.removeItem(at: metadataURL)
    }

    private func noteHistoryDirectory(for noteID: UUID, createIfNeeded: Bool) throws -> URL {
        let root = historyDirectory.appendingPathComponent(noteID.uuidString, isDirectory: true)
        if createIfNeeded, !fileManager.fileExists(atPath: root.path) {
            try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
        }
        return root
    }

    private func defaultSummary(for content: String) -> String {
        let firstLine = content
            .components(separatedBy: .newlines)
            .first { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            ?? "Revision"
        return String(firstLine.prefix(80))
    }
}
