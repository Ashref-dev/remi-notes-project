import Foundation
import SwiftUI

class NookListViewModel: ObservableObject {
    @Published private var allNooks: [Nook] = []
    @Published var selectedNook: Nook?
    @Published var searchText = ""

    private let nookManager = NookManager.shared
    
    var filteredNooks: [Nook] {
        if searchText.isEmpty {
            return allNooks
        } else {
            return allNooks.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    init() {
        fetchNooks()
        if let lastURL = SettingsManager.shared.lastViewedNookURL() {
            self.selectedNook = self.allNooks.first { $0.url == lastURL }
        }
    }

    func fetchNooks() {
        self.allNooks = nookManager.fetchNooks().sorted(by: { $0.name < $1.name })
    }

    func createNook(named name: String) {
        // Prevent creating duplicate nooks
        guard !allNooks.contains(where: { $0.name.lowercased() == name.lowercased() }) else {
            // Optionally, select the existing nook
            self.selectedNook = allNooks.first(where: { $0.name.lowercased() == name.lowercased() })
            return
        }
        
        nookManager.createNook(named: name) { [weak self] nook in
            if let nook = nook {
                self?.fetchNooks()
                self?.selectedNook = nook
                self?.searchText = "" // Clear search text after creation
            }
        }
    }

    func deleteNook(_ nook: Nook) {
        nookManager.deleteNook(nook)
        self.allNooks.removeAll { $0.id == nook.id }
        if selectedNook == nook {
            selectedNook = nil
        }
    }
    
    func renameNook(_ nook: Nook, to newName: String) {
        nookManager.renameNook(nook, to: newName) { [weak self] updatedNook in
            if let updatedNook = updatedNook {
                self?.fetchNooks()
                // Re-select the nook after renaming
                self?.selectedNook = updatedNook
            }
        }
    }
}
