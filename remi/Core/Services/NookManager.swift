import Foundation

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
                let nook = Nook(name: name, url: url)
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
}
