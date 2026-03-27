import Foundation
import SwiftUI
import Combine

@MainActor
final class NookListViewModel: ObservableObject {
    static let shared = NookListViewModel()

    @Published private(set) var allNooks: [Nook] = []
    @Published var selectedNook: Nook?
    @Published var searchText = ""

    private let nookManager = NookManager.shared
    private var cancellables = Set<AnyCancellable>()

    var filteredNooks: [Nook] {
        let base = allNooks
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    init() {
        fetchNooks()
        restoreLastViewedNookIfNeeded()
        setupHotkeyObserver()
        setupNookHotkeys()
        setupRefreshObserver()
    }

    func existingNook(named name: String) -> Nook? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return nil }
        return allNooks.first { $0.name.lowercased() == trimmedName.lowercased() }
    }

    func select(_ nook: Nook?) {
        guard let nook else {
            selectedNook = nil
            SettingsManager.shared.clearLastViewedNook()
            return
        }

        let updatedSelection = nookManager.touchNookOpened(nook) ?? nook
        if let index = allNooks.firstIndex(where: { $0.id == updatedSelection.id }) {
            allNooks[index] = updatedSelection
        }
        selectedNook = updatedSelection
        SettingsManager.shared.setLastViewedNook(updatedSelection)
    }

    func selectNookByIndex(_ index: Int) {
        let nooks = filteredNooks
        guard index < nooks.count else { return }
        select(nooks[index])
    }

    func selectNextNook() {
        let nooks = filteredNooks
        guard !nooks.isEmpty else { return }

        if let currentNook = selectedNook,
           let currentIndex = nooks.firstIndex(of: currentNook) {
            let nextIndex = (currentIndex + 1) % nooks.count
            select(nooks[nextIndex])
        } else {
            select(nooks.first)
        }
    }

    func selectPreviousNook() {
        let nooks = filteredNooks
        guard !nooks.isEmpty else { return }

        if let currentNook = selectedNook,
           let currentIndex = nooks.firstIndex(of: currentNook) {
            let previousIndex = currentIndex == 0 ? nooks.count - 1 : currentIndex - 1
            select(nooks[previousIndex])
        } else {
            select(nooks.last)
        }
    }

    func fetchNooks() {
        allNooks = nookManager.fetchNooks()

        if let current = selectedNook {
            selectedNook = allNooks.first(where: { $0.id == current.id }) ?? allNooks.first
        } else {
            restoreLastViewedNookIfNeeded()
        }
    }

    func createNook(named name: String) -> Nook? {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            ErrorHandlingService.shared.showWarning(message: "Please enter a note name.")
            return nil
        }

        if let existingNook = existingNook(named: trimmedName) {
            select(existingNook)
            ErrorHandlingService.shared.showInfo(message: "Opened existing note \"\(existingNook.name)\".")
            return existingNook
        }

        guard let newNook = nookManager.createNook(named: trimmedName) else {
            ErrorHandlingService.shared.showError(
                message: "Could not create note. Please try a different name.",
                severity: .warning
            )
            return nil
        }

        fetchNooks()
        select(allNooks.first(where: { $0.id == newNook.id }) ?? newNook)
        searchText = ""
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        return selectedNook
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

        allNooks.removeAll { $0.id == nook.id }
        if selectedNook?.id == nook.id {
            if let fallback = allNooks.first {
                select(fallback)
            } else {
                select(nil)
            }
        }

        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        return true
    }

    func renameNook(_ nook: Nook, to newName: String) {
        guard let updatedNook = nookManager.renameNook(nook, to: newName) else {
            ErrorHandlingService.shared.showWarning(message: "Couldn't rename note. That name may already be in use.")
            return
        }

        fetchNooks()
        select(allNooks.first(where: { $0.id == updatedNook.id }) ?? updatedNook)
        HapticsService.shared.perform(.noteUpdated)
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
    }

    @discardableResult
    func updateNook(_ nook: Nook) -> Nook? {
        guard let updatedNook = nookManager.updateNook(nook) else {
            ErrorHandlingService.shared.showWarning(message: "Couldn't save note changes. Please try a different name.")
            return nil
        }

        fetchNooks()
        if selectedNook?.id == nook.id {
            select(allNooks.first(where: { $0.id == updatedNook.id }) ?? updatedNook)
        }
        HapticsService.shared.perform(.noteUpdated)
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        return updatedNook
    }

    func moveNook(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex,
              sourceIndex >= 0, sourceIndex < allNooks.count,
              destinationIndex >= 0, destinationIndex < allNooks.count else {
            return
        }

        nookManager.moveNook(from: sourceIndex, to: destinationIndex, in: &allNooks)
        fetchNooks()
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
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
        var sortedNooks = allNooks.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        for (index, var nook) in sortedNooks.enumerated() {
            nook.order = index
            sortedNooks[index] = nook
        }

        nookManager.reorderNooks(sortedNooks)
        fetchNooks()
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
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
                Task { @MainActor in
                    self?.selectNookByIndex(nookIndex)
                }
            }
        }
    }

    private func setupRefreshObserver() {
        NotificationCenter.default.publisher(for: .nooksDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchNooks()
            }
            .store(in: &cancellables)
    }

    private func restoreLastViewedNookIfNeeded() {
        guard selectedNook == nil else { return }

        if let lastURL = SettingsManager.shared.lastViewedNookURL(),
           let lastViewed = allNooks.first(where: { $0.url == lastURL }) {
            selectedNook = lastViewed
        } else {
            selectedNook = allNooks.first
        }
    }
}
