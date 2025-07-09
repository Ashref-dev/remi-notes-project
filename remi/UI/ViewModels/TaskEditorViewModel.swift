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
                target.setTaskContent(oldContent)
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
            let stream = groqService.streamQuery(prompt: prompt, context: initialContent)
            for try await chunk in stream {
                accumulatedResponse += chunk
            }
            // Once the stream is complete, filter and update the actual task content
            let filteredContent = accumulatedResponse.replacingOccurrences(of: "<thinking>.*?</thinking>", with: "", options: .regularExpression)
            setTaskContent(filteredContent)
        } catch {
            let errorMessage = (error as? LocalizedError)?.errorDescription ?? "An unexpected error occurred."
            ErrorHandlingService.shared.showError(message: errorMessage)
            // Restore original content on error
            setTaskContent(initialContent)
        }
        
        isSendingQuery = false
    }
}
