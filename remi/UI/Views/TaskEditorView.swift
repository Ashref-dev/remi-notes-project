import SwiftUI
import MarkdownUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var showMarkdownPreview = false
    
    // Access the undo manager from the environment
    @Environment(\.undoManager) private var undoManager

    init(nook: Nook) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                if showMarkdownPreview {
                    ScrollView {
                        Markdown(viewModel.taskContent)
                            .markdownTextStyle { 
                                FontSize(16)
                                ForegroundColor(.primary)
                            }
                            .padding()
                    }
                } else {
                    TextEditor(text: $viewModel.taskContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                }
                
                if viewModel.isSendingQuery {
                    ElegantProgressView()
                }
            }

            Divider()

            HStack(spacing: 12) {
                Button(action: { showMarkdownPreview.toggle() }) {
                    Image(systemName: showMarkdownPreview ? "doc.text.fill" : "doc.text")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                
                TextField("Ask Remi to edit your tasks...", text: $userInput)
                    .textFieldStyle(.plain)
                    .focused($isInputFocused)
                    .onSubmit(handleInput)
                
                Button(action: handleInput) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(userInput.isEmpty || viewModel.isSendingQuery)
            }
            .padding()
            .background(Material.bar)
        }
        .navigationTitle(viewModel.nook.name)
        .onAppear {
            // Pass the undo manager to the view model
            viewModel.undoManager = self.undoManager
            isInputFocused = true
        }
    }
    
    private func handleInput() {
        let input = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !input.isEmpty else { return }
        
        Task {
            await viewModel.sendQuery(prompt: input)
        }
        
        userInput = ""
    }
}

struct TaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNook = Nook(name: "Preview Nook", url: URL(fileURLWithPath: "/dev/null"))
        TaskEditorView(nook: previewNook)
    }
}
