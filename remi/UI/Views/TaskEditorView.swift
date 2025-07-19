import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @FocusState private var isInputFocused: Bool
    @State private var textView: NSTextView?
    @State private var isMarkdownPreviewEnabled = true
    
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
                        LiveMarkdownEditor(
                            text: $viewModel.taskContent, 
                            theme: theme, 
                            isMarkdownPreviewEnabled: isMarkdownPreviewEnabled,
                            textViewBinding: { self.textView = $0 }
                        )
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
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundColor(theme.textPrimary)

            Spacer()
            
            HStack(spacing: 12) {
                // Markdown Preview Toggle
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isMarkdownPreviewEnabled.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isMarkdownPreviewEnabled ? "doc.richtext" : "doc.plaintext")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(isMarkdownPreviewEnabled ? "Preview" : "Plain")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(isMarkdownPreviewEnabled ? theme.accent : theme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isMarkdownPreviewEnabled ? theme.accent.opacity(0.15) : theme.backgroundSecondary)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isMarkdownPreviewEnabled ? theme.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
                .help(isMarkdownPreviewEnabled ? "Switch to Plain Text" : "Switch to Markdown Preview")
                
                // AI Assistant Button - Enhanced with gradient
                Button(action: { 
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isAIInputVisible.toggle()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text("AI")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.4, green: 0.3, blue: 0.8),   // Purple
                                Color(red: 0.2, green: 0.4, blue: 0.9)    // Blue
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(color: Color(red: 0.3, green: 0.3, blue: 0.8).opacity(0.3), radius: 4, x: 0, y: 2)
                    .scaleEffect(isAIInputVisible ? 1.05 : 1.0)
                }
                .buttonStyle(.plain)
                .help("Open AI Assistant")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(theme.backgroundSecondary)
    }
    
    @ViewBuilder
    private func BottomBar(theme: Theme) -> some View {
        HStack(spacing: 16) {
            // Formatting buttons with improved styling
            HStack(spacing: 12) {
                FormatButton(icon: "bold", action: { applyMarkdown("**", to: textView) }, theme: theme)
                FormatButton(icon: "italic", action: { applyMarkdown("*", to: textView) }, theme: theme)
                FormatButton(icon: "h.square", action: { applyMarkdown("# ", to: textView, prefixOnly: true) }, theme: theme)
            }
            
            Spacer()
            
            // Status indicators with modern styling
            HStack(spacing: 12) {
                ConnectionStatusIndicator()
                
                // Enhanced word count
                if !viewModel.taskContent.isEmpty {
                    let wordCount = viewModel.taskContent.components(separatedBy: .whitespacesAndNewlines)
                        .filter { !$0.isEmpty }.count
                    
                    HStack(spacing: 4) {
                        Image(systemName: "textformat.abc")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                        
                        Text("\(wordCount) words")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(theme.backgroundSecondary)
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(theme.backgroundSecondary)
    }
    
    // MARK: - Format Button Component
    @ViewBuilder
    private func FormatButton(icon: String, action: @escaping () -> Void, theme: Theme) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(theme.textSecondary)
                .frame(width: 32, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(theme.background.opacity(0.8))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(theme.border.opacity(0.5), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .help(getButtonHelpText(for: icon))
    }
    
    private func getButtonHelpText(for icon: String) -> String {
        switch icon {
        case "bold": return "Bold (Cmd+B)"
        case "italic": return "Italic (Cmd+I)"  
        case "h.square": return "Heading"
        default: return ""
        }
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
