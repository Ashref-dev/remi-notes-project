import Foundation
import Combine

struct AppError: Identifiable {
    let id = UUID()
    let message: String
    let isCritical: Bool
}

@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published private(set) var currentError: AppError? = nil
    
    private init() {}
    
    func showError(message: String, isCritical: Bool = false) {
        self.currentError = AppError(message: message, isCritical: isCritical)
    }
    
    func clearError() {
        self.currentError = nil
    }
}
