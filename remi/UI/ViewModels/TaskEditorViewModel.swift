import Foundation
import Combine

@MainActor
class TaskEditorViewModel: ObservableObject {
    @Published var nook: Nook
    @Published var taskContent: String = ""
    @Published var isSendingQuery: Bool = false
    @Published var thinkingText: String = ""
    
    private let nookManager = NookManager.shared
    private let groqService = GroqService.shared
    private var cancellables = Set<AnyCancellable>()

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
    
    func sendQuery(prompt: String) async {
        isSendingQuery = true
        thinkingText = ""
        
        do {
            let stream = groqService.streamQuery(prompt: prompt, context: self.taskContent)
            for try await chunk in stream {
                thinkingText += chunk
            }
            // Once the stream is complete, update the actual task content
            self.taskContent = thinkingText
        } catch {
            // Handle errors appropriately
            print("Error during streaming: \(error)")
            thinkingText = "Error: \(error.localizedDescription)"
        }
        
        isSendingQuery = false
    }
}
