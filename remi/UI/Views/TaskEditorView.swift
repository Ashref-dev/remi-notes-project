import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @FocusState private var isInputFocused: Bool
    @State private var textView: NSTextView?
    
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAIInputVisible = false

    init(nook: Nook) {
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
    }

    var body: some View {
        Themed { theme in
            ZStack(alignment: .bottom) {
                VStack(spacing: 0) {
                    TopBar(theme: theme)

                    // Main editor view
                    ZStack(alignment: .center) {
                        LiveMarkdownEditor(text: $viewModel.taskContent, theme: theme, textViewBinding: { self.textView = $0 })
                            .opacity(viewModel.isSendingQuery ? 0.3 : (viewModel.isReceivingResponse ? 0.6 : 1.0))
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isSendingQuery)
                            .animation(.easeInOut(duration: 0.2), value: viewModel.isReceivingResponse)
                        
                        if viewModel.isSendingQuery || viewModel.isReceivingResponse {
                            AILoadingView(
                                isLoading: viewModel.isSendingQuery,
                                isReceiving: viewModel.isReceivingResponse,
                                streamingContent: viewModel.streamingContent,
                                theme: theme
                            )
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .zIndex(2)
                        }
                        
                        // Show streaming preview if receiving
                        if viewModel.isReceivingResponse && !viewModel.streamingContent.isEmpty {
                            VStack {
                                Spacer()
                                StreamingTextPreview(
                                    content: viewModel.streamingContent,
                                    theme: theme
                                )
                                .padding(.bottom, 160) // Account for bottom toolbar
                            }
                            .zIndex(1)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }

                    Divider()

                    // Smart suggestions bar
                    VStack(spacing: 0) {
                        HStack {
                            Text("Quick Actions")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(theme.textSecondary)
                            Spacer()
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.top, 8)
                        
                        SmartSuggestionsView { suggestion in
                            handleAIInput(prompt: suggestion)
                        }
                        .padding(.vertical, 8)
                    }
                    .background(theme.background)
                    
                    Divider()

                    // Bottom toolbar
                    BottomBar(theme: theme)
                }
                
                // AI Input View - Slides from the bottom
                if isAIInputVisible {
                    AIInputView(isVisible: $isAIInputVisible, onSend: handleAIInput)
                        .frame(maxWidth: .infinity)
                        .padding(.bottom, 60)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(theme.background)
            .onAppear {
                viewModel.undoManager = self.undoManager
            }
            .animation(.easeInOut, value: isAIInputVisible)
        }
    }
    
    // MARK: - Subviews

    @ViewBuilder
    private func TopBar(theme: Theme) -> some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .semibold))
            }
            .buttonStyle(.plain)
            .foregroundColor(theme.textSecondary)

            Spacer()

            Text(viewModel.nook.name)
                .font(.headline)
                .foregroundColor(theme.textPrimary)

            Spacer()

            Button(action: { isAIInputVisible.toggle() }) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(theme.accent)
            }
            .buttonStyle(.plain)
        }
        .padding()
        .background(theme.backgroundSecondary)
    }
    
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
            
            // Status indicators
            HStack(spacing: 8) {
                ConnectionStatusIndicator()
                
                // Word count (if content is not empty)
                if !viewModel.taskContent.isEmpty {
                    let wordCount = viewModel.taskContent.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }.count
                    Text("\(wordCount) words")
                        .font(.system(size: 11))
                        .foregroundColor(theme.textSecondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(theme.background.opacity(0.5))
                        )
                }
            }
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
