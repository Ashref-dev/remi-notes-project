import Foundation
import Combine

enum ErrorSeverity {
    case info
    case warning
    case error
    case critical
}

struct AppError: Identifiable {
    let id = UUID()
    let message: String
    let severity: ErrorSeverity
    let timestamp: Date
    let canRetry: Bool
    let retryAction: (() -> Void)?
    
    init(message: String, severity: ErrorSeverity = .error, canRetry: Bool = false, retryAction: (() -> Void)? = nil) {
        self.message = message
        self.severity = severity
        self.timestamp = Date()
        self.canRetry = canRetry
        self.retryAction = retryAction
    }
}

@MainActor
class ErrorHandlingService: ObservableObject {
    static let shared = ErrorHandlingService()
    
    @Published private(set) var currentError: AppError? = nil
    @Published private(set) var errorHistory: [AppError] = []
    
    private init() {}
    
    func showError(
        message: String, 
        severity: ErrorSeverity = .error, 
        canRetry: Bool = false, 
        retryAction: (() -> Void)? = nil
    ) {
        let error = AppError(
            message: message, 
            severity: severity, 
            canRetry: canRetry, 
            retryAction: retryAction
        )
        
        self.currentError = error
        self.errorHistory.append(error)
        
        // Auto-dismiss non-critical errors after 5 seconds
        if severity != .critical {
            Task {
                try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                if self.currentError?.id == error.id {
                    self.clearError()
                }
            }
        }
    }
    
    func showInfo(message: String) {
        showError(message: message, severity: .info)
    }
    
    func showWarning(message: String) {
        showError(message: message, severity: .warning)
    }
    
    func clearError() {
        self.currentError = nil
    }
    
    func retry() {
        guard let error = currentError, error.canRetry else { return }
        clearError()
        error.retryAction?()
    }
    
    func clearErrorHistory() {
        self.errorHistory.removeAll()
    }
}
