import Foundation

// MARK: - Nook Metadata Structure

private struct NookMetadata: Codable {
    let iconName: String
    let iconColor: String
    let lastModified: Date
    
    init(iconName: String = "doc.text.fill", iconColor: NookIconColor = .blue) {
        self.iconName = iconName
        self.iconColor = iconColor.rawValue
        self.lastModified = Date()
    }
    
    init(from nook: Nook) {
        self.iconName = nook.iconName
        self.iconColor = nook.iconColor.rawValue
        self.lastModified = Date()
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
                let nook = Nook(
                    name: name,
                    url: url,
                    iconName: metadata.iconName,
                    iconColor: iconColor
                )
                nooks.append(nook)
            }
        } catch {
            print("Error fetching nooks: \(error)")
        }
        return nooks.sorted { $0.name < $1.name }
    }

    func createNook(named name: String) -> Nook? {
        let newNookURL = nooksDirectory.appendingPathComponent(name)
        if !fileManager.fileExists(atPath: newNookURL.path) {
            do {
                try fileManager.createDirectory(at: newNookURL, withIntermediateDirectories: true, attributes: nil)
                let tasksFileURL = newNookURL.appendingPathComponent("tasks.md")
                fileManager.createFile(atPath: tasksFileURL.path, contents: "".data(using: .utf8), attributes: nil)
                let newNook = Nook(name: name, url: newNookURL)
                return newNook
            } catch {
                print("Error creating nook: \(error)")
                return nil
            }
        } else {
            print("Nook already exists.")
            return fetchNooks().first { $0.name == name }
        }
    }

    func renameNook(_ nook: Nook, to newName: String) -> Nook? {
        let newURL = nooksDirectory.appendingPathComponent(newName)
        do {
            try fileManager.moveItem(at: nook.url, to: newURL)
            var updatedNook = nook
            updatedNook.name = newName
            updatedNook.url = newURL
            return updatedNook
        } catch {
            print("Error renaming nook: \(error)")
            return nil
        }
    }

    func deleteNook(_ nook: Nook) {
        do {
            try fileManager.removeItem(at: nook.url)
        } catch {
            print("Error deleting nook: \(error)")
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
            return try JSONDecoder().decode(NookMetadata.self, from: data)
        } catch {
            // Return default metadata if file doesn't exist or can't be decoded
            return NookMetadata()
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
        // Update metadata
        updateNookMetadata(nook)
        
        // If name changed, rename the directory
        let currentName = nook.url.lastPathComponent
        if nook.name != currentName {
            return renameNook(nook, to: nook.name)
        }
        
        return nook
    }
}
