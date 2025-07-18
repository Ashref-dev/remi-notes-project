import Foundation
import SwiftUI
import Combine

@MainActor
class TaskEditorViewModel: ObservableObject {
    @Published var nook: Nook
    @Published var taskContent: String = ""
    @Published var isSendingQuery: Bool = false
    @Published var isReceivingResponse: Bool = false
    @Published var streamingContent: String = ""
    
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
        isReceivingResponse = false
        streamingContent = ""
        
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
                var accumulatedResponse = ""
                
                // Start receiving response - show different loading state
                await MainActor.run {
                    self.isSendingQuery = false
                    self.isReceivingResponse = true
                }
                
                for try await chunk in stream {
                    accumulatedResponse += chunk
                    
                    // Update streaming content for real-time preview
                    await MainActor.run {
                        self.streamingContent = accumulatedResponse
                    }
                }
                
                // Apply the final content with smooth animation
                await MainActor.run {
                    self.applyFinalContent(accumulatedResponse)
                }
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
            await MainActor.run {
                self.setTaskContent(initialContent)
                self.resetStreamingState()
            }
        }
    }
    
    private func applyFinalContent(_ content: String) {
        // Ensure proper formatting is preserved
        let formattedContent = preserveMarkdownFormatting(content)
        
        // Apply content with modern, smooth animation sequence
        withAnimation(.easeOut(duration: 0.5)) {
            // Clear streaming content with fade out
            streamingContent = ""
            isReceivingResponse = false
        }
        
        // Brief pause for visual clarity, then apply the formatted content with elegant spring animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.9, blendDuration: 0.4)) {
                self.setTaskContent(formattedContent)
            }
            
            // Complete the process with a smooth fade out of the loading state
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    self.isSendingQuery = false
                }
            }
        }
    }
    
    private func resetStreamingState() {
        isSendingQuery = false
        isReceivingResponse = false
        streamingContent = ""
    }
    
    private func preserveMarkdownFormatting(_ content: String) -> String {
        // Ensure proper line breaks and spacing for Markdown
        var formatted = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Fix common formatting issues while preserving intentional structure
        
        // 1. Remove excessive blank lines (more than 2 consecutive)
        formatted = formatted.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
        
        // 2. Ensure headers have proper spacing (blank line before headers)
        formatted = formatted.replacingOccurrences(of: "([^\n])\n(#{1,6}\\s)", with: "$1\n\n$2", options: .regularExpression)
        
        // 3. Ensure lists have proper spacing (blank line before lists)
        formatted = formatted.replacingOccurrences(of: "([^\n])\n(-\\s|\\*\\s|\\+\\s|\\d+\\.\\s)", with: "$1\n\n$2", options: .regularExpression)
        
        // 4. Ensure task lists have proper spacing
        formatted = formatted.replacingOccurrences(of: "([^\n])\n(-\\s\\[[\\sx]\\])", with: "$1\n\n$2", options: .regularExpression)
        
        // 5. Ensure code blocks have proper spacing
        formatted = formatted.replacingOccurrences(of: "([^\n])\n(```)", with: "$1\n\n$2", options: .regularExpression)
        formatted = formatted.replacingOccurrences(of: "(```[^\n]*)\n([^\n`])", with: "$1\n\n$2", options: .regularExpression)
        
        // 6. Fix spacing after code blocks
        formatted = formatted.replacingOccurrences(of: "(```)\n([^\n])", with: "$1\n\n$2", options: .regularExpression)
        
        // 7. Preserve blockquotes spacing
        formatted = formatted.replacingOccurrences(of: "([^\n])\n(>\\s)", with: "$1\n\n$2", options: .regularExpression)
        
        // 8. Ensure paragraphs are properly separated
        formatted = formatted.replacingOccurrences(of: "([.!?])([A-Z])", with: "$1\n\n$2", options: [])
        
        return formatted
    }
}
