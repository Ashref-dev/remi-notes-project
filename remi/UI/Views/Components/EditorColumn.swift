import SwiftUI

struct EditorColumn: View {
    let selectedNook: Nook?
    @State private var taskContent = ""
    @State private var isEditorFocused = false
    @State private var isAIInputVisible = false
    @State private var viewModel: TaskEditorViewModel?
    @State private var focusOpacity: Double = 0.85
    
    init(selectedNook: Nook?) {
        self.selectedNook = selectedNook
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Editor Header with Focus Mode Indicator
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let nook = selectedNook {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(nook.name)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(theme.textPrimary)
                                
                                Text("Markdown editor with task support")
                                    .font(.system(size: 11))
                                    .foregroundColor(theme.textSecondary)
                            }
                        } else {
                            Text("Editor")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textSecondary)
                        }
                        
                        // Focus mode indicator
                        if isEditorFocused && selectedNook != nil {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(theme.accent)
                                    .frame(width: 4, height: 4)
                                    .opacity(0.8)
                                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isEditorFocused)
                                
                                Text("Focus Mode")
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(theme.accent.opacity(0.8))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    if selectedNook != nil {
                        HStack(spacing: AppTheme.Spacing.medium) {
                            // Focus toggle button
                            Button(action: { 
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isEditorFocused.toggle()
                                    focusOpacity = isEditorFocused ? 1.0 : 0.85
                                }
                            }) {
                                Image(systemName: isEditorFocused ? "eye.fill" : "eye")
                                    .font(.system(size: 16))
                                    .foregroundColor(isEditorFocused ? theme.accent : theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                            .help("Toggle Focus Mode")
                            
                            // AI input button
                            Button(action: { 
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isAIInputVisible.toggle()
                                }
                            }) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                                    .foregroundColor(isAIInputVisible ? theme.accent : theme.textSecondary)
                                    .scaleEffect(isAIInputVisible ? 1.1 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .help("AI Assistant")
                        }
                    }
                }
                .padding(AppTheme.Spacing.large)
                .background(theme.backgroundSecondary.opacity(isEditorFocused ? 0.5 : 1.0))
                .animation(.easeInOut(duration: 0.3), value: isEditorFocused)
                
                Divider()
                    .opacity(isEditorFocused ? 0.3 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: isEditorFocused)
                
                // Editor Content with Focus Effects
                ZStack {
                        if selectedNook != nil, let vm = viewModel {
                        VStack(spacing: 0) {
                            // Main Editor with Focus Enhancement
                            editorView(theme: theme, viewModel: vm)
                                .background(
                                    Rectangle()
                                        .fill(isEditorFocused ? theme.background : theme.background.opacity(0.98))
                                        .animation(.easeInOut(duration: 0.3), value: isEditorFocused)
                                )
                                .overlay(
                                    // Focus border
                                    Rectangle()
                                        .stroke(
                                            isEditorFocused ? theme.accent.opacity(0.3) : Color.clear,
                                            lineWidth: 2
                                        )
                                        .animation(.easeInOut(duration: 0.3), value: isEditorFocused)
                                )
                            
                            // AI Input Overlay with perfect sizing
                            if isAIInputVisible {
                                // Subtle overlay background
                                Rectangle()
                                    .fill(Color.black.opacity(0.15))
                                    .ignoresSafeArea()
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.2)) {
                                            isAIInputVisible = false
                                        }
                                    }
                                    .overlay(
                                        // Perfectly centered and sized AI Input
                                        VStack {
                                            Spacer()
                                            
                                            AIInputView(isVisible: $isAIInputVisible) { prompt in
                                                handleAIInput(prompt: prompt, viewModel: vm)
                                            }
                                            .fixedSize() // Size to content
                                            
                                            Spacer()
                                            Spacer() // Extra space to position slightly above center
                                        }
                                        .frame(maxWidth: 400) // Limit max width for large screens
                                    )
                                    .zIndex(1)
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            }
                        }
                    } else {
                        noNookSelectedView(theme: theme)
                    }
                }
                .background(theme.background)
                .opacity(focusOpacity)
                .animation(.easeInOut(duration: 0.3), value: focusOpacity)
            }
        }
        .onChange(of: selectedNook) { _, newNook in
            if let nook = newNook {
                viewModel = TaskEditorViewModel(nook: nook)
                loadContent()
            } else {
                viewModel = nil
                isEditorFocused = false
                isAIInputVisible = false
            }
        }
        .onAppear {
            if let nook = selectedNook {
                viewModel = TaskEditorViewModel(nook: nook)
            }
            loadContent()
        }
    }
    
    private func editorView(theme: Theme, viewModel: TaskEditorViewModel) -> some View {
        ZStack {
            // Main Editor
            LiveMarkdownEditor(
                text: Binding(
                    get: { viewModel.taskContent },
                    set: { viewModel.taskContent = $0 }
                ),
                theme: theme,
                textViewBinding: { _ in }
            )
            .padding(isEditorFocused ? AppTheme.Spacing.xlarge : AppTheme.Spacing.large)
            .animation(.easeInOut(duration: 0.3), value: isEditorFocused)
            .opacity(viewModel.isSendingQuery ? 0.3 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isSendingQuery)
            
            // Modern Loading Overlay with enhanced animation
            if viewModel.isSendingQuery {
                VStack(spacing: 20) {
                    // Enhanced animated thinking indicator
                    HStack(spacing: 6) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(theme.accent)
                                .frame(width: 6, height: 6)
                                .scaleEffect(viewModel.isSendingQuery ? 1.2 : 0.8)
                                .animation(
                                    .easeInOut(duration: 0.6)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(index) * 0.15),
                                    value: viewModel.isSendingQuery
                                )
                        }
                    }
                    
                    VStack(spacing: 8) {
                        Text("AI is thinking...")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Processing your request")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(theme.backgroundSecondary)
                        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(theme.accent.opacity(0.1), lineWidth: 1)
                        )
                )
                .scaleEffect(viewModel.isSendingQuery ? 1.0 : 0.9)
                .opacity(viewModel.isSendingQuery ? 1.0 : 0.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.isSendingQuery)
                .zIndex(2)
            }
        }
    }
    
    private func noNookSelectedView(theme: Theme) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(theme.textSecondary)
            Text("Ready to Create")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textSecondary)
            Text("Select a Nook to start writing with Markdown and task support")
                .font(.system(size: 14))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            
            // Task format hint
            VStack(alignment: .leading, spacing: 4) {
                Text("Task Format:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(theme.textSecondary)
                HStack(alignment: .top, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("- [ ] Incomplete task")
                        Text("- [x] Complete task")
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(theme.textSecondary.opacity(0.8))
                }
            }
            .padding(12)
            .background(theme.backgroundSecondary.opacity(0.5))
            .cornerRadius(8)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
    
    private func loadContent() {
        guard let nook = selectedNook else { return }
        taskContent = NookManager.shared.fetchTasks(for: nook)
        // TaskEditorViewModel loads content in its init, so no need to call loadContent
    }
    
    private func handleAIInput(prompt: String, viewModel: TaskEditorViewModel) {
        Task {
            await viewModel.sendQuery(prompt: prompt)
        }
    }
}

// Custom FocusState for binding
private struct FocusedBinding {
    @FocusState static var isEditorFocused: Bool
}

// Extension to add focus binding to LiveMarkdownEditor
extension LiveMarkdownEditor {
    func focused(_ binding: FocusState<Bool>.Binding) -> some View {
        self // Return self for now, we'll implement proper focus handling later
    }
}
