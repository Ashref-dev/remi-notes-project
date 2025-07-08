import Foundation
import SwiftUI

class NookListViewModel: ObservableObject {
    @Published var nooks: [Nook] = []
    @Published var selectedNook: Nook? {
        didSet {
            if let nook = selectedNook {
                SettingsManager.shared.setLastViewedNook(nook)
            }
        }
    }
    
    private let nookManager = NookManager.shared

    init() {
        fetchNooks()
        if let lastURL = SettingsManager.shared.lastViewedNookURL() {
            self.selectedNook = self.nooks.first { $0.url == lastURL }
        }
    }

    func fetchNooks() {
        self.nooks = nookManager.fetchNooks()
    }

    func createNook(named name: String) {
        nookManager.createNook(named: name) { [weak self] nook in
            if let nook = nook {
                self?.fetchNooks()
                self?.selectedNook = nook
            }
        }
    }

    func deleteNook(_ nook: Nook) {
        nookManager.deleteNook(nook) { [weak self] success in
            if success {
                self?.nooks.removeAll { $0.id == nook.id }
            }
        }
    }
    
    func renameNook(_ nook: Nook, to newName: String) {
        nookManager.renameNook(nook, to: newName) { [weak self] updatedNook in
            if updatedNook != nil {
                self?.fetchNooks()
            }
        }
    }
}
