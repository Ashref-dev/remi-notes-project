import Foundation
import SwiftUI
import Combine

@MainActor
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

    func existingNook(named name: String) -> Nook? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return allNooks.first { $0.name.lowercased() == trimmedName.lowercased() }
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
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            ErrorHandlingService.shared.showWarning(message: "Please enter a note name.")
            return nil
        }

        // Prevent creating duplicate nooks
        if let existingNook = allNooks.first(where: { $0.name.lowercased() == trimmedName.lowercased() }) {
            // Optionally, select the existing nook
            self.selectedNook = existingNook
            SettingsManager.shared.setLastViewedNook(existingNook)
            ErrorHandlingService.shared.showInfo(message: "Opened existing note \"\(existingNook.name)\".")
            return existingNook
        }

        let newNook = nookManager.createNook(named: trimmedName)
        if let newNook = newNook {
            self.fetchNooks()
            self.selectedNook = newNook
            SettingsManager.shared.setLastViewedNook(newNook)
            self.searchText = "" // Clear search text after creation
        } else {
            ErrorHandlingService.shared.showError(
                message: "Could not create note. Please try a different name.",
                severity: .warning
            )
        }
        return newNook
    }

    @discardableResult
    func deleteNook(_ nook: Nook) -> Bool {
        guard nookManager.deleteNook(nook) else {
            ErrorHandlingService.shared.showError(
                message: "Failed to delete \"\(nook.name)\". Please try again.",
                severity: .error
            )
            return false
        }

        self.allNooks.removeAll { $0.id == nook.id }
        if selectedNook == nook {
            selectedNook = allNooks.first
            if let selectedNook {
                SettingsManager.shared.setLastViewedNook(selectedNook)
            } else {
                SettingsManager.shared.clearLastViewedNook()
            }
        }
        return true
    }
    
    func renameNook(_ nook: Nook, to newName: String) {
        if let updatedNook = nookManager.renameNook(nook, to: newName) {
            self.fetchNooks()
            // Re-select the nook after renaming
            self.selectedNook = updatedNook
            SettingsManager.shared.setLastViewedNook(updatedNook)
            HapticsService.shared.perform(.noteUpdated)
        } else {
            ErrorHandlingService.shared.showWarning(message: "Couldn't rename note. That name may already be in use.")
        }
    }
    
    @discardableResult
    func updateNook(_ nook: Nook) -> Nook? {
        if let updatedNook = nookManager.updateNook(nook) {
            // Update the nook in our local array
            if let index = allNooks.firstIndex(where: { $0.id == nook.id }) {
                allNooks[index] = updatedNook
            } else {
                fetchNooks()
            }
            
            // Update selected nook if it's the one being edited
            if selectedNook?.id == nook.id {
                selectedNook = updatedNook
            }
            SettingsManager.shared.setLastViewedNook(updatedNook)
            HapticsService.shared.perform(.noteUpdated)
            return updatedNook
        }
        ErrorHandlingService.shared.showWarning(message: "Couldn't save note changes. Please try a different name.")
        return nil
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
