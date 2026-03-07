import Foundation

// MARK: - Nook Metadata Structure

private struct NookMetadata: Codable {
    let id: String
    let iconName: String
    let iconColor: String
    let lastModified: Date
    let order: Int
    let hasBeenAutoTitled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case iconName
        case iconColor
        case lastModified
        case order
        case hasBeenAutoTitled
    }

    init(id: String = UUID().uuidString, iconName: String = "doc.text.fill", iconColor: NookIconColor = .blue, order: Int = 0, hasBeenAutoTitled: Bool = false) {
        self.id = id
        self.iconName = iconName
        self.iconColor = iconColor.rawValue
        self.lastModified = Date()
        self.order = order
        self.hasBeenAutoTitled = hasBeenAutoTitled
    }

    init(from nook: Nook) {
        self.id = nook.id.uuidString
        self.iconName = nook.iconName
        self.iconColor = nook.iconColor.rawValue
        self.lastModified = Date()
        self.order = nook.order
        self.hasBeenAutoTitled = nook.hasBeenAutoTitled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(String.self, forKey: .id) ?? UUID().uuidString
        self.iconName = try container.decodeIfPresent(String.self, forKey: .iconName) ?? "doc.text.fill"
        self.iconColor = try container.decodeIfPresent(String.self, forKey: .iconColor) ?? NookIconColor.blue.rawValue
        self.lastModified = try container.decodeIfPresent(Date.self, forKey: .lastModified) ?? Date()
        self.order = try container.decodeIfPresent(Int.self, forKey: .order) ?? 0
        self.hasBeenAutoTitled = try container.decodeIfPresent(Bool.self, forKey: .hasBeenAutoTitled) ?? false
    }
}

class NookManager {
    static let shared = NookManager()

    private let fileManager = FileManager.default
    private var nooksDirectory: URL

    private init() {
        // Get the application support directory
        let appSupportDirectory = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = appSupportDirectory.appendingPathComponent("Remi")
        self.nooksDirectory = appDirectory.appendingPathComponent("Nooks")

        setupInitialDirectory()
    }

    private func setupInitialDirectory() {
        if !fileManager.fileExists(atPath: nooksDirectory.path) {
            do {
                try fileManager.createDirectory(at: nooksDirectory, withIntermediateDirectories: true, attributes: nil)
                // Create a default Nook
                if let nook = createNook(named: "Welcome") {
                    let initialContent = """
                    # Welcome to Remi!

                    This is your first Nook. A Nook is a simple folder containing a `tasks.md` file.

                    - You can write tasks here using Markdown.
                    - Use the input field below to add new tasks.
                    - You can also ask the AI assistant for help.
                    """
                    self.saveTasks(for: nook, content: initialContent)
                    // Set a custom icon for the welcome nook
                    var welcomeNook = nook
                    welcomeNook.iconName = "heart.fill"
                    welcomeNook.iconColor = .pink
                    welcomeNook.hasBeenAutoTitled = true // Don't auto-title the welcome nook
                    self.updateNookMetadata(welcomeNook)
                }
            } catch {
                print("Error creating Nooks directory: \(error)")
            }
        }
    }

    func fetchNooks() -> [Nook] {
        var nooks: [Nook] = []
        do {
            let nookURLs = try fileManager.contentsOfDirectory(at: nooksDirectory, includingPropertiesForKeys: nil, options: .skipsHiddenFiles)
            for url in nookURLs where url.hasDirectoryPath {
                let name = url.lastPathComponent
                let metadata = loadNookMetadata(at: url)
                let iconColor = NookIconColor(rawValue: metadata.iconColor) ?? .blue
                let nookId = UUID(uuidString: metadata.id) ?? UUID()
                if nookId.uuidString != metadata.id {
                    let repairedMetadata = NookMetadata(
                        id: nookId.uuidString,
                        iconName: metadata.iconName,
                        iconColor: iconColor,
                        order: metadata.order
                    )
                    saveNookMetadata(repairedMetadata, at: url)
                }
                let nook = Nook(
                    id: nookId,
                    name: name,
                    url: url,
                    iconName: metadata.iconName,
                    iconColor: iconColor,
                    order: metadata.order,
                    hasBeenAutoTitled: metadata.hasBeenAutoTitled
                )
                nooks.append(nook)
            }
        } catch {
            print("Error fetching nooks: \(error)")
        }
        return nooks.sorted { nook1, nook2 in
            // Sort by order first, then by name if orders are equal
            if nook1.order != nook2.order {
                return nook1.order < nook2.order
            }
            return nook1.name < nook2.name
        }
    }

    func createNook(named name: String) -> Nook? {
        let sanitizedName = sanitizeNookName(name)
        guard !sanitizedName.isEmpty else {
            return nil
        }

        let newNookURL = nooksDirectory.appendingPathComponent(sanitizedName)
        if !fileManager.fileExists(atPath: newNookURL.path) {
            do {
                try fileManager.createDirectory(at: newNookURL, withIntermediateDirectories: true, attributes: nil)
                let tasksFileURL = newNookURL.appendingPathComponent("tasks.md")
                fileManager.createFile(atPath: tasksFileURL.path, contents: "".data(using: .utf8), attributes: nil)
                let nextOrder = (fetchNooks().map(\.order).max() ?? -1) + 1
                
                // Only consider it 'auto-titled' inherently if the user named it themselves immediately,
                // but since our UI defaults to 'New Nook', we check that.
                let isAlreadyNamed = (sanitizedName != "New Nook")
                
                let newNook = Nook(name: sanitizedName, url: newNookURL, order: nextOrder, hasBeenAutoTitled: isAlreadyNamed)
                updateNookMetadata(newNook)
                return newNook
            } catch {
                print("Error creating nook: \(error)")
                return nil
            }
        } else {
            print("Nook already exists.")
            return fetchNooks().first { $0.name.localizedCaseInsensitiveCompare(sanitizedName) == .orderedSame }
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
        let tasksURL = nook.url.appendingPathComponent("tasks.md")
        do {
            return try String(contentsOf: tasksURL, encoding: .utf8)
        } catch {
            print("Error fetching tasks: \(error)")
            return ""
        }
    }

    func saveTasks(for nook: Nook, content: String) {
        let tasksURL = nook.url.appendingPathComponent("tasks.md")
        do {
            try content.write(to: tasksURL, atomically: true, encoding: .utf8)
        } catch {
            print("Error saving tasks: \(error)")
        }
    }
    
    // MARK: - Metadata Management
    
    private func loadNookMetadata(at url: URL) -> NookMetadata {
        let metadataURL = url.appendingPathComponent(".nook-metadata.json")
        do {
            let data = try Data(contentsOf: metadataURL)
            let decoder = JSONDecoder()

            let metadata = try decoder.decode(NookMetadata.self, from: data)

            if let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let hasId = raw["id"] is String
                let hasOrder = raw["order"] != nil
                if !hasId || !hasOrder {
                    saveNookMetadata(metadata, at: url)
                }
            }

            return metadata
        } catch {
            // Return default metadata if file doesn't exist or can't be decoded
            let metadata = NookMetadata()
            saveNookMetadata(metadata, at: url)
            return metadata
        }
    }
    
    func updateNookMetadata(_ nook: Nook) {
        let metadata = NookMetadata(from: nook)
        saveNookMetadata(metadata, at: nook.url)
    }
    
    private func saveNookMetadata(_ metadata: NookMetadata, at url: URL) {
        let metadataURL = url.appendingPathComponent(".nook-metadata.json")
        do {
            let data = try JSONEncoder().encode(metadata)
            try data.write(to: metadataURL)
        } catch {
            print("Error saving nook metadata: \(error)")
        }
    }
    
    func updateNook(_ nook: Nook) -> Nook? {
        var normalizedNook = nook
        normalizedNook.name = sanitizeNookName(nook.name)
        guard !normalizedNook.name.isEmpty else { return nil }

        // Update metadata
        updateNookMetadata(normalizedNook)

        // If name changed, rename the directory
        let currentName = normalizedNook.url.lastPathComponent
        if normalizedNook.name != currentName {
            return renameNook(normalizedNook, to: normalizedNook.name)
        }

        return normalizedNook
    }
    
    // MARK: - Nook Reordering
    
    func reorderNooks(_ nooks: [Nook]) {
        // Update order for each nook
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
        
        // Update order for all nooks
        for (index, var nook) in nooks.enumerated() {
            nook.order = index
            nooks[index] = nook
        }
        
        // Persist the new order
        reorderNooks(nooks)
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

        let visibleName = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "."))
        return visibleName
    }
}
