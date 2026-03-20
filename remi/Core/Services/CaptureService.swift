import Foundation

enum CaptureRoute: String, CaseIterable, Codable, Identifiable {
    case createInboxNote
    case appendToCurrentNote

    var id: String { rawValue }

    var title: String {
        switch self {
        case .createInboxNote:
            return "Create Inbox Note"
        case .appendToCurrentNote:
            return "Append to Current Note"
        }
    }

    var subtitle: String {
        switch self {
        case .createInboxNote:
            return "Create a fresh note in Inbox"
        case .appendToCurrentNote:
            return "Append to the active note"
        }
    }
}

struct SharedCapturePayload: Codable, Identifiable {
    let id: UUID
    let text: String
    let route: CaptureRoute
    let source: NookCaptureSource
    let createdAt: Date
}

final class CaptureService {
    static let shared = CaptureService()
    static let appGroupIdentifier = "group.ashref.tn.remi"

    private let nookManager = NookManager.shared
    private let titleService = NoteTitleService.shared
    private let queueDirectoryName = "SharedCaptureQueue"

    private init() {}

    @discardableResult
    func capture(text: String, route: CaptureRoute, source: NookCaptureSource) -> Nook? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let result: Nook?
        switch route {
        case .createInboxNote:
            let placeholderName = nextPlaceholderName()
            result = nookManager.createNook(
                named: placeholderName,
                initialContent: trimmed,
                tags: [Nook.inboxTag],
                captureSource: source
            )
        case .appendToCurrentNote:
            if let current = currentNook() {
                nookManager.appendTasks(for: current, content: trimmed)
                result = nookManager.fetchNook(for: current.url)
            } else {
                result = capture(text: trimmed, route: .createInboxNote, source: source)
            }
        }

        guard let result else { return nil }

        if route == .createInboxNote {
            Task {
                await autoTitleIfNeeded(nook: result, content: trimmed)
            }
        }

        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        return result
    }

    func enqueueSharedCapture(text: String, route: CaptureRoute, source: NookCaptureSource) throws {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let payload = SharedCapturePayload(
            id: UUID(),
            text: trimmed,
            route: route,
            source: source,
            createdAt: Date()
        )
        let data = try JSONEncoder().encode(payload)
        let queueDirectory = try sharedQueueDirectory(createIfMissing: true)
        let fileURL = queueDirectory.appendingPathComponent("\(payload.id.uuidString).json")
        try data.write(to: fileURL, options: .atomic)
    }

    @discardableResult
    func importQueuedSharedCaptures() -> [Nook] {
        guard let queueDirectory = try? sharedQueueDirectory(createIfMissing: false) else {
            return []
        }

        guard let urls = try? FileManager.default.contentsOfDirectory(
            at: queueDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        ) else {
            return []
        }

        var imported: [Nook] = []
        for url in urls where url.pathExtension == "json" {
            do {
                let data = try Data(contentsOf: url)
                let payload = try JSONDecoder().decode(SharedCapturePayload.self, from: data)
                if let nook = capture(text: payload.text, route: payload.route, source: payload.source) {
                    imported.append(nook)
                }
                try FileManager.default.removeItem(at: url)
            } catch {
                continue
            }
        }

        return imported
    }

    private func currentNook() -> Nook? {
        guard let url = SettingsManager.shared.lastViewedNookURL() else { return nil }
        return nookManager.fetchNook(for: url)
    }

    private func autoTitleIfNeeded(nook: Nook, content: String) async {
        guard !nook.hasBeenAutoTitled else { return }
        let suggestion = await titleService.suggestTitle(for: content)
        var updatedNook = nook
        updatedNook.name = suggestion.title
        updatedNook.iconName = suggestion.iconName
        updatedNook.iconColor = suggestion.iconColor
        updatedNook.hasBeenAutoTitled = true
        _ = nookManager.updateNook(updatedNook)
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
    }

    private func sharedQueueDirectory(createIfMissing: Bool) throws -> URL {
        guard let root = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupIdentifier) else {
            throw CocoaError(.fileNoSuchFile)
        }
        let queueDirectory = root.appendingPathComponent(queueDirectoryName, isDirectory: true)
        if createIfMissing, !FileManager.default.fileExists(atPath: queueDirectory.path) {
            try FileManager.default.createDirectory(at: queueDirectory, withIntermediateDirectories: true)
        }
        return queueDirectory
    }

    private func nextPlaceholderName() -> String {
        let existingNames = Set(nookManager.fetchNooks().map { $0.name.lowercased() })
        if !existingNames.contains("new nook") {
            return "New Nook"
        }

        var index = 2
        while existingNames.contains("new nook \(index)") {
            index += 1
        }
        return "New Nook \(index)"
    }
}
