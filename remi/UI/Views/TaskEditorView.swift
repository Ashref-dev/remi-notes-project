import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var userInput: String = ""
    @FocusState private var isInputFocused: Bool
    @State private var textView: NSTextView? // Reference to the NSTextView
    
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss

    init(nook: Nook) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Header()
                
                Divider()

                ZStack(alignment: .center) {
                    LiveMarkdownEditor(text: $viewModel.taskContent, textViewBinding: { self.textView = $0 })
                        .padding(AppTheme.Spacing.medium)
                    
                    if viewModel.isSendingQuery {
                        ElegantProgressView()
                    }
                }

                Divider()

                BottomBar()
            }
            
            if isAIInputVisible {
                AIInputView(isVisible: $isAIInputVisible, onSend: handleAIInput)
            }
        }
        .background(AppColors.background)
        .frame(minWidth: 500, minHeight: 400) // Give the sheet a reasonable size
        .onAppear {
            viewModel.undoManager = self.undoManager
        }
    }
    
    @State private var isAIInputVisible = false

    // MARK: - Subviews

    @ViewBuilder
    private func Header() -> some View {
        HStack {
            Text(viewModel.nook.name)
                .font(.headline)
                .foregroundColor(AppColors.textPrimary)
            
            Spacer()
            
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(AppTheme.Spacing.xsmall)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColors.backgroundSecondary)
    }
    
    @ViewBuilder
    private func BottomBar() -> some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Formatting buttons
            Group {
                Button(action: { applyMarkdown("**", to: textView) }) { Image(systemName: "bold") }
                Button(action: { applyMarkdown("*", to: textView) }) { Image(systemName: "italic") }
                Button(action: { applyMarkdown("# ", to: textView, prefixOnly: true) }) { Image(systemName: "h.square") }
            }
            .buttonStyle(.plain)
            .font(.title3)
            .foregroundColor(AppColors.textSecondary)
            
            Spacer()
            
            Button(action: {
                withAnimation {
                    isAIInputVisible.toggle()
                }
            }) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(AppColors.accent)
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.medium)
        .background(AppColors.backgroundSecondary)
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