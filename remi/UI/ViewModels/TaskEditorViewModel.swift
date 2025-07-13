import Foundation
import Combine

@MainActor
class TaskEditorViewModel: ObservableObject {
    @Published var nook: Nook
    @Published var taskContent: String = ""
    @Published var isSendingQuery: Bool = false
    
    private var thinkingText: String = ""
    private let nookManager = NookManager.shared
    private let groqService = GroqService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // UndoManager for handling undo/redo
    var undoManager: UndoManager? {
        didSet {
            // Clear undo history when a new manager is set
            undoManager?.removeAllActions()
        }
    }

    init(nook: Nook) {
        self.nook = nook
        self.taskContent = nookManager.fetchTasks(for: nook)
        
        // Debounce saving
        $taskContent
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .dropFirst() // Don't save on initial load
            .sink { [weak self] content in
                self?.saveContent(content)
            }
            .store(in: &cancellables)
    }

    private func saveContent(_ content: String) {
        nookManager.saveTasks(for: nook, content: content)
    }
    
    private func setTaskContent(_ newContent: String) {
        let oldContent = self.taskContent
        undoManager?.registerUndo(withTarget: self) { target in
            Task {
                await target.setTaskContent(oldContent)
            }
        }
        self.taskContent = newContent
    }
    
    func deleteNook() {
        nookManager.deleteNook(nook)
    }
    
    func sendQuery(prompt: String) async {
        isSendingQuery = true
        var accumulatedResponse = ""
        
        let initialContent = self.taskContent
        
        do {
            // Use retry service for network operations
            try await RetryService.shared.execute(
                maxRetries: 3,
                baseDelay: 1.0,
                maxDelay: 10.0,
                retryCondition: RetryService.shouldRetryGroqError
            ) {
                let stream = self.groqService.streamQuery(prompt: prompt, context: initialContent)
                var tempResponse = ""
                
                for try await chunk in stream {
                    tempResponse += chunk
                }
                
                accumulatedResponse = tempResponse
            }
            
            // The response is the full, updated content.
            setTaskContent(accumulatedResponse)
            
            // Show success feedback for critical operations
            if let groqError = accumulatedResponse.isEmpty ? GroqError.decodingError(NSError(domain: "EmptyResponse", code: 0)) : nil {
                throw groqError
            }
            
        } catch {
            let groqError = error as? GroqError
            let errorMessage = groqError?.errorDescription ?? "An unexpected error occurred."
            let canRetry = groqError?.canRetry ?? false
            let severity = groqError?.severity ?? .error
            
            ErrorHandlingService.shared.showError(
                message: errorMessage,
                severity: severity,
                canRetry: canRetry,
                retryAction: canRetry ? { [weak self] in
                    Task {
                        await self?.sendQuery(prompt: prompt)
                    }
                } : nil
            )
            
            // Restore original content on error
            setTaskContent(initialContent)
        }
        
        isSendingQuery = false
    }
}
