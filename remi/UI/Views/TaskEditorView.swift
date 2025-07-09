import SwiftUI


struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var textView: NSTextView? // Reference to the NSTextView
    
    // Access the undo manager from the environment
    @Environment(\.undoManager) private var undoManager

    init(nook: Nook) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .center) {
                LiveMarkdownEditor(text: $viewModel.taskContent, textViewBinding: { self.textView = $0 })
                
                if viewModel.isSendingQuery {
                    ElegantProgressView()
                }
            }

            Divider()

            HStack(spacing: 12) {
                // Formatting buttons
                Group {
                    Button(action: { applyMarkdown("**", to: textView) }) {
                        Image(systemName: "bold")
                    }
                    Button(action: { applyMarkdown("*", to: textView) }) {
                        Image(systemName: "italic")
                    }
                    Button(action: { applyMarkdown("# ", to: textView, prefixOnly: true) }) {
                        Image(systemName: "h.square")
                    }
                }
                .buttonStyle(.plain)
                .font(.title2)
                
                Spacer()
                
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
    
    private func applyMarkdown(_ markdown: String, to textView: NSTextView?, prefixOnly: Bool = false) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        let currentText = textView.string as NSString
        
        if selectedRange.length > 0 {
            // If text is selected, wrap it
            let selectedText = currentText.substring(with: selectedRange)
            let newText: String
            if prefixOnly {
                newText = markdown + selectedText
            } else {
                newText = markdown + selectedText + markdown
            }
            textView.insertText(newText, replacementRange: selectedRange)
        } else {
            // If no text is selected, insert at cursor
            textView.insertText(markdown, replacementRange: selectedRange)
        }
    }
}

struct TaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNook = Nook(name: "Preview Nook", url: URL(fileURLWithPath: "/dev/null"))
        TaskEditorView(nook: previewNook)
    }
}
