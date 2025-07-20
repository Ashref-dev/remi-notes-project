import Foundation
import SwiftUI
import Combine

@MainActor
class TaskEditorViewModel: ObservableObject {
    @Published var nook: Nook
    @Published var taskContent: String = ""
    @Published var isProcessingAI: Bool = false
    
    private let nookManager = NookManager.shared
    private let groqService = GroqService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // UndoManager for handling undo/redo
    var undoManager: UndoManager? {
        didSet {
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
    
    // Simple, direct AI processing
    func processAIQuery(prompt: String) async {
        guard !isProcessingAI else { return }
        
        isProcessingAI = true
        let originalContent = taskContent
        
        do {
            // Get AI response
            let improvedContent = try await groqService.processQuery(
                prompt: prompt, 
                context: originalContent
            )
            
            // Apply the content directly with smooth animation
            withAnimation(.easeInOut(duration: 0.3)) {
                setTaskContent(improvedContent)
            }
            
        } catch {
            // Show error and restore original content
            let groqError = error as? GroqError
            let errorMessage = groqError?.errorDescription ?? "AI request failed"
            
            ErrorHandlingService.shared.showError(
                message: errorMessage,
                severity: .error,
                canRetry: true,
                retryAction: { [weak self] in
                    Task {
                        await self?.processAIQuery(prompt: prompt)
                    }
                }
            )
            
            // Restore original content on error
            setTaskContent(originalContent)
        }
        
        isProcessingAI = false
    }
}
