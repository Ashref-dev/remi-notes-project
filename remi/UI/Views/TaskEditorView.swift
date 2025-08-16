import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @FocusState private var isInputFocused: Bool
    @State private var isMarkdownPreviewEnabled = UserDefaults.standard.bool(forKey: "isMarkdownPreviewEnabled")
    @State private var isQuickActionsVisible = false // Quick Actions closed by default
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
                            autoFocus: true,
                            onTextViewReady: { textView in
                                // Connect NSTextView's undo manager to ViewModel for AI-safe registrations
                                viewModel.textViewUndoManager = textView.undoManager
                                viewModel.textView = textView
                            }
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
                    .overlay(alignment: .topTrailing) {
                        VStack(alignment: .trailing, spacing: 8) {
                            // Compact save confirmation indicator
                            if viewModel.showSaveConfirmation {
                                HStack(spacing: 6) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.green)
                                    Text("Saved")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(theme.textPrimary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.background)
                                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                                )
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                            
                            // Copy success confirmation indicator
                            if viewModel.showCopySuccess {
                                HStack(spacing: 6) {
                                    Image(systemName: "doc.on.clipboard.fill")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.blue)
                                    Text("Copied!")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(theme.textPrimary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(theme.background)
                                        .shadow(color: Color.black.opacity(0.08), radius: 2, x: 0, y: 1)
                                )
                                .transition(.scale(scale: 0.9).combined(with: .opacity))
                            }
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 16)
                        .zIndex(4)
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
                // No global hotkey registration - use local key events instead
            }
            .onDisappear {
                // Force save when view disappears
                viewModel.forceSave()
            }
            .background(
                // Invisible button to capture keyboard shortcut when view has focus
                Button("") {
                    viewModel.copyAllContent(format: .markdown)
                }
                .keyboardShortcut("c", modifiers: [.command, .shift])
                .hidden()
            )
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
                Divider()
                    .frame(height: 20)
                
                // Markdown Preview Toggle - Enhanced responsiveness
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isMarkdownPreviewEnabled.toggle()
                        // Save preference to UserDefaults
                        UserDefaults.standard.set(isMarkdownPreviewEnabled, forKey: "isMarkdownPreviewEnabled")
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
                
                // Copy All Button - Modern and Elegant
                Menu {
                    Button(action: { viewModel.copyAllContent(format: .markdown) }) {
                        Label("Copy as Markdown", systemImage: "doc.text")
                    }
                    
                    Button(action: { viewModel.copyAllContent(format: .plainText) }) {
                        Label("Copy as Plain Text", systemImage: "doc.plaintext")
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(theme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(theme.backgroundSecondary)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .help("Copy content to clipboard (⌘⇧C)")
                
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
            // Elegant undo/redo hints
            HStack(spacing: 16) {
                // Undo hint
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                    
                    Text("⌘Z")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.textSecondary.opacity(0.8))
                }
                
                // Redo hint
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.forward")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                    
                    Text("⌘⇧Z")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.textSecondary.opacity(0.8))
                }
                
                // Copy hint
                HStack(spacing: 4) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary.opacity(0.7))
                    
                    Text("⌘⇧C")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(theme.textSecondary.opacity(0.8))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundSecondary.opacity(0.6))
            )
            
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
    
    // MARK: - Private Methods
    
    private func handleAIInput(prompt: String) {
        Task {
            await viewModel.processAIQuery(prompt: prompt)
        }
    }
}

struct TaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNook = Nook(name: "Preview Nook", url: URL(fileURLWithPath: "/dev/null"))
        TaskEditorView(nook: previewNook)
    }
}
