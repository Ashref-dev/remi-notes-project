import Foundation
import SwiftUI
import Combine

class NookListViewModel: ObservableObject {
    @Published private var allNooks: [Nook] = []
    @Published var selectedNook: Nook?
    @Published var searchText = ""

    private let nookManager = NookManager.shared
    private var cancellables = Set<AnyCancellable>()
    
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
        
        setupHotkeyObserver()
        setupNookHotkeys()
    }
    
    private func setupHotkeyObserver() {
        NotificationCenter.default.publisher(for: .selectNookByIndex)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                if let nookIndex = notification.object as? Int {
                    self?.selectNookByIndex(nookIndex)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupNookHotkeys() {
        if SettingsManager.shared.enableNookHotkeys {
            HotkeyManager.shared.registerCustomNookHotkeys(modifiers: SettingsManager.shared.nookHotkeyModifiers) { [weak self] nookIndex in
                self?.selectNookByIndex(nookIndex)
            }
        }
    }
    
    func selectNookByIndex(_ index: Int) {
        let nooks = filteredNooks
        guard index < nooks.count else { return }
        selectedNook = nooks[index]
        SettingsManager.shared.setLastViewedNook(nooks[index])
    }
    
    func selectNextNook() {
        let nooks = filteredNooks
        guard !nooks.isEmpty else { return }
        
        if let currentNook = selectedNook,
           let currentIndex = nooks.firstIndex(of: currentNook) {
            let nextIndex = (currentIndex + 1) % nooks.count
            selectedNook = nooks[nextIndex]
        } else {
            selectedNook = nooks.first
        }
        
        if let selectedNook = selectedNook {
            SettingsManager.shared.setLastViewedNook(selectedNook)
        }
    }
    
    func selectPreviousNook() {
        let nooks = filteredNooks
        guard !nooks.isEmpty else { return }
        
        if let currentNook = selectedNook,
           let currentIndex = nooks.firstIndex(of: currentNook) {
            let previousIndex = currentIndex == 0 ? nooks.count - 1 : currentIndex - 1
            selectedNook = nooks[previousIndex]
        } else {
            selectedNook = nooks.last
        }
        
        if let selectedNook = selectedNook {
            SettingsManager.shared.setLastViewedNook(selectedNook)
        }
    }

    func fetchNooks() {
        self.allNooks = nookManager.fetchNooks() // Already sorted by order in NookManager
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
    
    // MARK: - Nook Reordering
    
    func moveNook(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < allNooks.count,
              destinationIndex >= 0, destinationIndex < allNooks.count else {
            return
        }
        
        nookManager.moveNook(from: sourceIndex, to: destinationIndex, in: &allNooks)
        
        // Refresh to get the updated order
        fetchNooks()
    }
    
    func moveNookUp(_ nook: Nook) {
        guard let currentIndex = allNooks.firstIndex(of: nook), currentIndex > 0 else { return }
        moveNook(from: currentIndex, to: currentIndex - 1)
    }
    
    func moveNookDown(_ nook: Nook) {
        guard let currentIndex = allNooks.firstIndex(of: nook), currentIndex < allNooks.count - 1 else { return }
        moveNook(from: currentIndex, to: currentIndex + 1)
    }
    
    func resetToAlphabeticalOrder() {
        // Sort nooks alphabetically and update their order
        var sortedNooks = allNooks.sorted { $0.name < $1.name }
        for (index, var nook) in sortedNooks.enumerated() {
            nook.order = index
            sortedNooks[index] = nook
        }
        
        // Update the order in the manager
        nookManager.reorderNooks(sortedNooks)
        
        // Refresh the list
        fetchNooks()
    }
}
