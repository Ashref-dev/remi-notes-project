import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var textView: NSTextView? // Reference to the NSTextView
    
    @Environment(\.undoManager) private var undoManager
    
    init(nook: Nook) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                ZStack(alignment: .center) {
                    LiveMarkdownEditor(text: $viewModel.taskContent, theme: theme, textViewBinding: { self.textView = $0 })
                    
                    if viewModel.isSendingQuery {
                        ElegantProgressView()
                    }
                }

                Divider()

                BottomBar(theme: theme)
            }
            .background(theme.background)
            .navigationTitle(viewModel.nook.name)
            .onAppear {
                viewModel.undoManager = self.undoManager
            }
            .sheet(isPresented: $isAIInputVisible) {
                AIInputView(isVisible: $isAIInputVisible, onSend: handleAIInput)
            }
        }
    }
    
    @State private var isAIInputVisible = false

    // MARK: - Subviews
    
    @ViewBuilder
    private func BottomBar(theme: Theme) -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Formatting buttons
            Group {
                Button(action: { applyMarkdown("**", to: textView) }) { Image(systemName: "bold") }
                Button(action: { applyMarkdown("*", to: textView) }) { Image(systemName: "italic") }
                Button(action: { applyMarkdown("# ", to: textView, prefixOnly: true) }) { Image(systemName: "h.square") }
            }
            .buttonStyle(.plain)
            .font(.title3)
            .foregroundColor(theme.textSecondary)
            
            Spacer()
            
            Button(action: {
                isAIInputVisible.toggle()
            }) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.medium)
        .background(theme.backgroundSecondary)
    }
    
    // MARK: - Private Methods
    
    private func handleAIInput(prompt: String) {
        Task {
            await viewModel.sendQuery(prompt: prompt)
        }
    }
    
    private func applyMarkdown(_ markdown: String, to textView: NSTextView?, prefixOnly: Bool = false) {
        guard let textView = textView else { return }
        
        let selectedRange = textView.selectedRange()
        let currentText = textView.string as NSString
        
        if selectedRange.length > 0 {
            let selectedText = currentText.substring(with: selectedRange)
            let newText = prefixOnly ? (markdown + selectedText) : (markdown + selectedText + markdown)
            textView.insertText(newText, replacementRange: selectedRange)
        } else {
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
