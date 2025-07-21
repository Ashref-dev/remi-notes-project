import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @FocusState private var isInputFocused: Bool
    @State private var textView: NSTextView?
    @State private var isMarkdownPreviewEnabled = UserDefaults.standard.bool(forKey: "isMarkdownPreviewEnabled")
    @State private var isQuickActionsVisible = false // Quick Actions closed by default
    
    @Environment(\.undoManager) private var undoManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var isAIInputVisible = false
    
    let nook: Nook // Keep reference to current nook

    init(nook: Nook) {
        self.nook = nook
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
                        .id("editor-\(isMarkdownPreviewEnabled ? "markdown" : "plain")")
                        .opacity(viewModel.isProcessingAI ? 0.6 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isProcessingAI)
                        
                        // Simple loading indicator
                        if viewModel.isProcessingAI {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .tint(theme.accent)
                                
                                Text("AI is improving your notes...")
                                    .font(.caption)
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.top, 8)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(theme.background)
                                    .shadow(color: Color.black.opacity(0.1), radius: 8)
                            )
                            .transition(.scale(scale: 0.8).combined(with: .opacity))
                            .zIndex(2)
                        }
                    }

                    Divider()

                    // Smart suggestions bar - Modern and Compact
                    VStack(spacing: 0) {
                        // Header with elegant toggle button
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isQuickActionsVisible.toggle()
                                }
                            }) {
                                HStack(spacing: 8) {
                                    // Modern icon with subtle background
                                    ZStack {
                                        Circle()
                                            .fill(theme.accent.opacity(0.08))
                                            .frame(width: 20, height: 20)
                                        
                                        Image(systemName: isQuickActionsVisible ? "chevron.down" : "chevron.right")
                                            .font(.system(size: 9, weight: .semibold))
                                            .foregroundColor(theme.accent)
                                    }
                                    
                                    Text("AI Quick Actions")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(theme.textPrimary)
                                    
                                    // Status indicator
                                    if isQuickActionsVisible {
                                        Text("•")
                                            .font(.system(size: 8))
                                            .foregroundColor(theme.accent)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                            .help(isQuickActionsVisible ? "Hide AI Quick Actions" : "Show AI Quick Actions")
                            
                            Spacer()
                            
                            // Subtle count indicator when collapsed
                            if !isQuickActionsVisible {
                                Text("4")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(theme.textSecondary.opacity(0.6))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(theme.backgroundSecondary)
                                    )
                            }
                        }
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, 10)
                        
                        // Collapsible content with smooth animations
                        if isQuickActionsVisible {
                            SmartSuggestionsView { suggestion in
                                handleAIInput(prompt: suggestion)
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 12)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10)),
                                removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top))
                            ))
                        }
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(theme.background)
                    )
                    
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
            // Enhanced keyboard shortcuts and state monitoring for undo/redo
            .onReceive(NotificationCenter.default.publisher(for: .init("UndoRequest"))) { _ in
                if undoManager?.canUndo == true {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        undoManager?.undo()
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .init("RedoRequest"))) { _ in
                if undoManager?.canRedo == true {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        undoManager?.redo()
                    }
                }
            }
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
                Divider()
                    .frame(height: 20)
                
                // Markdown Preview Toggle - Enhanced responsiveness
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isMarkdownPreviewEnabled.toggle()
                        // Save preference to UserDefaults
                        UserDefaults.standard.set(isMarkdownPreviewEnabled, forKey: "isMarkdownPreviewEnabled")
                        // Force immediate update of the text view
                        if let textView = textView {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                textView.needsDisplay = true
                            }
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isMarkdownPreviewEnabled ? "doc.richtext" : "doc.plaintext")
                            .font(.system(size: 14, weight: .medium))
                        
                        Text(isMarkdownPreviewEnabled ? "Markdown" : "Plain Text")
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
                .help(isMarkdownPreviewEnabled ? "Switch to Plain Text View" : "Switch to Markdown Preview")
                
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
            // Undo/Redo buttons - Enhanced and crash-safe
            HStack(spacing: 8) {
                Button(action: { 
                    guard let undoManager = undoManager, undoManager.canUndo else { return }
                    withAnimation(.easeInOut(duration: 0.1)) {
                        undoManager.undo()
                    }
                }) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(undoManager?.canUndo == true ? theme.accent : theme.textSecondary.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(undoManager?.canUndo == true ? theme.accent.opacity(0.1) : theme.background.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(undoManager?.canUndo == true ? theme.accent.opacity(0.3) : theme.border.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(undoManager?.canUndo == true ? 1.0 : 0.95)
                }
                .buttonStyle(.plain)
                .disabled(undoManager?.canUndo != true)
                .help("Undo (⌘Z)")
                .animation(.easeInOut(duration: 0.2), value: undoManager?.canUndo)
                
                Button(action: { 
                    guard let undoManager = undoManager, undoManager.canRedo else { return }
                    withAnimation(.easeInOut(duration: 0.1)) {
                        undoManager.redo()
                    }
                }) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(undoManager?.canRedo == true ? theme.accent : theme.textSecondary.opacity(0.4))
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(undoManager?.canRedo == true ? theme.accent.opacity(0.1) : theme.background.opacity(0.3))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(undoManager?.canRedo == true ? theme.accent.opacity(0.3) : theme.border.opacity(0.2), lineWidth: 0.5)
                        )
                        .scaleEffect(undoManager?.canRedo == true ? 1.0 : 0.95)
                }
                .buttonStyle(.plain)
                .disabled(undoManager?.canRedo != true)
                .help("Redo (⌘⇧Z)")
                .animation(.easeInOut(duration: 0.2), value: undoManager?.canRedo)
            }
            
            Divider()
                .frame(height: 20)

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
        case "strikethrough": return "Strikethrough"
        case "list.bullet": return "Bullet List"
        case "list.number": return "Numbered List"
        case "h.square": return "Heading"
        case "arrow.uturn.backward": return "Undo (Cmd+Z)"
        case "arrow.uturn.forward": return "Redo (Cmd+Shift+Z)"
        default: return ""
        }
    }    // MARK: - Private Methods
    
    private func handleAIInput(prompt: String) {
        Task {
            await viewModel.processAIQuery(prompt: prompt)
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
