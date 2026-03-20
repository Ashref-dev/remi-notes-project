import Foundation

private struct NookMetadata: Codable {
    let id: String
    let iconName: String
    let iconColor: String
    let order: Int
    let hasBeenAutoTitled: Bool
    let createdAt: Date
    let updatedAt: Date
    let lastOpenedAt: Date?
    let isPinned: Bool
    let tags: [String]
    let captureSource: String
    let pendingAIProposal: PendingAIProposal?

    enum CodingKeys: String, CodingKey {
        case id
        case iconName
        case iconColor
        case order
        case hasBeenAutoTitled
        case createdAt
        case updatedAt
        case lastOpenedAt
        case isPinned
        case tags
        case captureSource
        case pendingAIProposal
    }

    init(
        id: String = UUID().uuidString,
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
        self.iconName = iconName
        self.iconColor = iconColor.rawValue
        self.order = order
        self.hasBeenAutoTitled = hasBeenAutoTitled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastOpenedAt = lastOpenedAt
        self.isPinned = isPinned
        self.tags = tags
        self.captureSource = captureSource.rawValue
        self.pendingAIProposal = pendingAIProposal
    }

    init(from nook: Nook) {
        self.id = nook.id.uuidString
        self.iconName = nook.iconName
        self.iconColor = nook.iconColor.rawValue
        self.order = nook.order
        self.hasBeenAutoTitled = nook.hasBeenAutoTitled
        self.createdAt = nook.createdAt
        self.updatedAt = nook.updatedAt
        self.lastOpenedAt = nook.lastOpenedAt
        self.isPinned = nook.isPinned
        self.tags = nook.tags
        self.captureSource = nook.captureSource.rawValue
        self.pendingAIProposal = nook.pendingAIProposal
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let now = Date()
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "doc.text.fill"
        self.iconColor = try container.decodeIfPresent(String.self, forKey: .iconColor) ?? NookIconColor.blue.rawValue
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        self.hasBeenAutoTitled = try container.decodeIfPresent(Bool.self, forKey: .hasBeenAutoTitled) ?? false
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? now
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? now
        self.lastOpenedAt = try container.decodeIfPresent(Date.self, forKey: .lastOpenedAt)
        self.isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        self.tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        self.captureSource = try container.decodeIfPresent(String.self, forKey: .captureSource) ?? NookCaptureSource.manual.rawValue
        self.pendingAIProposal = try container.decodeIfPresent(PendingAIProposal.self, forKey: .pendingAIProposal)
    }
}

final class NookManager {
    static let shared = NookManager()

    private let fileManager = FileManager.default
    private let metadataFileName = ".nook-metadata.json"
    private let tasksFileName = "tasks.md"
    private var nooksDirectory: URL

    private init() {
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDirectory.appendingPathComponent("Remi")
        self.nooksDirectory = appDirectory.appendingPathComponent("Nooks")

        setupInitialDirectory()
    }

    private func setupInitialDirectory() {
        guard !fileManager.fileExists(atPath: nooksDirectory.path) else { return }

        do {
            try fileManager.createDirectory(at: nooksDirectory, withIntermediateDirectories: true, attributes: nil)
            if let nook = createNook(named: "Welcome") {
                let initialContent = """
                # Welcome to Remi!

                This is your first note.

                - Write in plain text or Markdown.
                - Use the bottom strip to switch notes smoothly.
                - Ask the AI assistant when you want to rewrite or organize content.
                """
                saveTasks(for: nook, content: initialContent)
                var welcomeNook = nook
                welcomeNook.iconName = "heart.fill"
                welcomeNook.iconColor = .pink
                welcomeNook.hasBeenAutoTitled = true
                updateNookMetadata(welcomeNook)
            }
        } catch {
            print("Error creating Nooks directory: \(error)")
        }
    }

    func fetchNooks() -> [Nook] {
        var nooks: [Nook] = []

        do {
            let nookURLs = try fileManager.contentsOfDirectory(
                at: nooksDirectory,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )

            for url in nookURLs where url.hasDirectoryPath {
                let name = url.lastPathComponent
                let metadata = loadNookMetadata(at: url)
                let iconColor = NookIconColor(rawValue: metadata.iconColor) ?? .blue
                let nookID = UUID(uuidString: metadata.id) ?? UUID()
                let repairedMetadata = metadata.id == nookID.uuidString
                    ? metadata
                    : NookMetadata(
                        id: nookID.uuidString,
                        iconName: metadata.iconName,
                        iconColor: iconColor,
                        order: metadata.order,
                        hasBeenAutoTitled: metadata.hasBeenAutoTitled,
                        createdAt: metadata.createdAt,
                        updatedAt: metadata.updatedAt,
                        lastOpenedAt: metadata.lastOpenedAt,
                        isPinned: metadata.isPinned,
                        tags: metadata.tags,
                        captureSource: NookCaptureSource(rawValue: metadata.captureSource) ?? .manual,
                        pendingAIProposal: metadata.pendingAIProposal
                    )
                if repairedMetadata.id != metadata.id {
                    saveNookMetadata(repairedMetadata, at: url)
                }

                let nook = Nook(
                    id: nookID,
                    name: name,
                    url: url,
                    iconName: repairedMetadata.iconName,
                    iconColor: iconColor,
                    order: repairedMetadata.order,
                    hasBeenAutoTitled: repairedMetadata.hasBeenAutoTitled,
                    createdAt: repairedMetadata.createdAt,
                    updatedAt: repairedMetadata.updatedAt,
                    lastOpenedAt: repairedMetadata.lastOpenedAt,
                    isPinned: repairedMetadata.isPinned,
                    tags: repairedMetadata.tags,
                    captureSource: NookCaptureSource(rawValue: repairedMetadata.captureSource) ?? .manual,
                    pendingAIProposal: repairedMetadata.pendingAIProposal
                )
                nooks.append(nook)
            }
        } catch {
            print("Error fetching nooks: \(error)")
        }

        return nooks.sorted { lhs, rhs in
            if lhs.order != rhs.order {
                return lhs.order < rhs.order
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    func fetchNook(for url: URL) -> Nook? {
        fetchNooks().first { $0.url == url }
    }

    func createNook(
        named name: String,
        initialContent: String = "",
        iconName: String = "doc.text.fill",
        iconColor: NookIconColor = .blue,
        tags: [String] = [],
        captureSource: NookCaptureSource = .manual,
        isPinned: Bool = false,
        pendingAIProposal: PendingAIProposal? = nil
    ) -> Nook? {
        let sanitizedName = sanitizeNookName(name)
        guard !sanitizedName.isEmpty else {
            return nil
        }

        let newNookURL = nooksDirectory.appendingPathComponent(sanitizedName)
        if fileManager.fileExists(atPath: newNookURL.path) {
            return fetchNooks().first {
                $0.name.localizedCaseInsensitiveCompare(sanitizedName) == .orderedSame
            }
        }

        do {
            try fileManager.createDirectory(at: newNookURL, withIntermediateDirectories: true, attributes: nil)
            let tasksFileURL = tasksURL(for: newNookURL)
            fileManager.createFile(atPath: tasksFileURL.path, contents: Data(), attributes: nil)

            let nextOrder = (fetchNooks().map(\.order).max() ?? -1) + 1
            let isAlreadyNamed = sanitizedName != "New Nook"
            let normalizedTags = normalizeTags(tags)
            let now = Date()
            let newNook = Nook(
                name: sanitizedName,
                url: newNookURL,
                iconName: iconName,
                iconColor: iconColor,
                order: nextOrder,
                hasBeenAutoTitled: isAlreadyNamed,
                createdAt: now,
                updatedAt: now,
                isPinned: isPinned,
                tags: normalizedTags,
                captureSource: captureSource,
                pendingAIProposal: pendingAIProposal
            )
            updateNookMetadata(newNook)

            if !initialContent.isEmpty {
                saveTasks(for: newNook, content: initialContent)
            }

            return fetchNook(for: newNookURL)
        } catch {
            print("Error creating nook: \(error)")
            return nil
        }
    }

    func renameNook(_ nook: Nook, to newName: String) -> Nook? {
        let sanitizedName = sanitizeNookName(newName)
        guard !sanitizedName.isEmpty else {
            return nil
        }

        if sanitizedName == nook.url.lastPathComponent {
            return nook
        }

        let newURL = nooksDirectory.appendingPathComponent(sanitizedName)
        if fileManager.fileExists(atPath: newURL.path) {
            return nil
        }

        do {
            try fileManager.moveItem(at: nook.url, to: newURL)
            var updatedNook = nook
            updatedNook.name = sanitizedName
            updatedNook.url = newURL
            updatedNook.updatedAt = Date()
            updateNookMetadata(updatedNook)
            return updatedNook
        } catch {
            print("Error renaming nook: \(error)")
            return nil
        }
    }

    @discardableResult
    func deleteNook(_ nook: Nook) -> Bool {
        do {
            try fileManager.removeItem(at: nook.url)
            return true
        } catch {
            print("Error deleting nook: \(error)")
            return false
        }
    }

    func fetchTasks(for nook: Nook) -> String {
        let targetURL = tasksURL(for: nook.url)
        do {
            return try String(contentsOf: targetURL, encoding: .utf8)
        } catch {
            print("Error fetching tasks: \(error)")
            return ""
        }
    }

    func saveTasks(for nook: Nook, content: String) {
        let targetURL = tasksURL(for: nook.url)
        do {
            try content.write(to: targetURL, atomically: true, encoding: .utf8)
            var updatedNook = nook
            updatedNook.updatedAt = Date()
            updateNookMetadata(updatedNook)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }

    func appendTasks(for nook: Nook, content: String) {
        let existing = fetchTasks(for: nook)
        let separator = existing.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : "\n\n"
        saveTasks(for: nook, content: existing + separator + content)
    }

    @discardableResult
    func touchNookOpened(_ nook: Nook) -> Nook? {
        var updatedNook = nook
        updatedNook.lastOpenedAt = Date()
        updateNookMetadata(updatedNook)
        return fetchNook(for: updatedNook.url) ?? updatedNook
    }

    func setPendingAIProposal(_ proposal: PendingAIProposal?, for nook: Nook) -> Nook? {
        var updatedNook = nook
        updatedNook.pendingAIProposal = proposal
        updatedNook.updatedAt = Date()
        return updateNook(updatedNook)
    }

    func clearPendingAIProposal(for nook: Nook) -> Nook? {
        setPendingAIProposal(nil, for: nook)
    }

    func updateNookMetadata(_ nook: Nook) {
        var normalized = nook
        normalized.tags = normalizeTags(nook.tags)
        let metadata = NookMetadata(from: normalized)
        saveNookMetadata(metadata, at: normalized.url)
    }

    func updateNook(_ nook: Nook) -> Nook? {
        var normalizedNook = nook
        normalizedNook.name = sanitizeNookName(nook.name)
        normalizedNook.tags = normalizeTags(nook.tags)
        normalizedNook.updatedAt = Date()

        guard !normalizedNook.name.isEmpty else { return nil }

        updateNookMetadata(normalizedNook)

        let currentName = normalizedNook.url.lastPathComponent
        if normalizedNook.name != currentName {
            return renameNook(normalizedNook, to: normalizedNook.name)
        }

        return fetchNook(for: normalizedNook.url) ?? normalizedNook
    }

    func reorderNooks(_ nooks: [Nook]) {
        for (index, var nook) in nooks.enumerated() {
            nook.order = index
            updateNookMetadata(nook)
        }
    }

    func moveNook(from sourceIndex: Int, to destinationIndex: Int, in nooks: inout [Nook]) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < nooks.count,
              destinationIndex >= 0, destinationIndex < nooks.count else {
            return
        }

        let movedNook = nooks.remove(at: sourceIndex)
        nooks.insert(movedNook, at: destinationIndex)

        for (index, var nook) in nooks.enumerated() {
            nook.order = index
            nook.updatedAt = Date()
            nooks[index] = nook
        }

        reorderNooks(nooks)
    }

    private func loadNookMetadata(at url: URL) -> NookMetadata {
        let metadataURL = url.appendingPathComponent(metadataFileName)
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()
            let metadata = try decoder.decode(NookMetadata.self, from: data)
            return repairMetadataIfNeeded(metadata, at: url)
        } catch {
            let metadata = NookMetadata()
            saveNookMetadata(metadata, at: url)
            return metadata
        }
    }

    private func repairMetadataIfNeeded(_ metadata: NookMetadata, at url: URL) -> NookMetadata {
        guard let raw = try? JSONSerialization.jsonObject(with: (try? Data(contentsOf: url.appendingPathComponent(metadataFileName))) ?? Data()) as? [String: Any] else {
            return metadata
        }

        let hasLegacyFields =
            raw["id"] == nil ||
            raw["createdAt"] == nil ||
            raw["updatedAt"] == nil ||
            raw["tags"] == nil ||
            raw["captureSource"] == nil

        if hasLegacyFields {
            saveNookMetadata(metadata, at: url)
        }

        return metadata
    }

    private func saveNookMetadata(_ metadata: NookMetadata, at url: URL) {
        let metadataURL = url.appendingPathComponent(metadataFileName)
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            print("Error saving nook metadata: \(error)")
        }
    }

    private func tasksURL(for url: URL) -> URL {
        url.appendingPathComponent(tasksFileName)
    }

    private func sanitizeNookName(_ name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        let forbidden = CharacterSet(charactersIn: "/\\:?%*|\"<>\n\r\t")
        let cleanedScalars = trimmed.unicodeScalars.map { forbidden.contains($0) ? " " : Character($0) }
        let cleaned = String(cleanedScalars)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    }

    private func normalizeTags(_ tags: [String]) -> [String] {
        var seen = Set<String>()
        return tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .filter { tag in
                let key = tag.lowercased()
                if seen.contains(key) {
                    return false
                }
                seen.insert(key)
                return true
            }
    }
}
