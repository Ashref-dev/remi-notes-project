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

    func createNook(named name: String) -> Nook? {
        // Prevent creating duplicate nooks
        if let existingNook = allNooks.first(where: { $0.name.lowercased() == name.lowercased() }) {
            // Optionally, select the existing nook
            self.selectedNook = existingNook
            return existingNook
        }
        
        let newNook = nookManager.createNook(named: name)
        if let newNook = newNook {
            self.fetchNooks()
            self.selectedNook = newNook
            self.searchText = "" // Clear search text after creation
        }
        return newNook
    }

    func deleteNook(_ nook: Nook) {
        nookManager.deleteNook(nook)
        self.allNooks.removeAll { $0.id == nook.id }
        if selectedNook == nook {
            selectedNook = nil
        }
    }
    
    func renameNook(_ nook: Nook, to newName: String) {
        if let updatedNook = nookManager.renameNook(nook, to: newName) {
            self.fetchNooks()
            // Re-select the nook after renaming
            self.selectedNook = updatedNook
        }
    }
    
    func updateNook(_ nook: Nook) {
        if let updatedNook = nookManager.updateNook(nook) {
            // Update the nook in our local array
            if let index = allNooks.firstIndex(where: { $0.id == nook.id }) {
                allNooks[index] = updatedNook
            }
            
            // Update selected nook if it's the one being edited
            if selectedNook?.id == nook.id {
                selectedNook = updatedNook
            }
        }
    }
}
