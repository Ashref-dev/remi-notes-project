import SwiftUI

struct EditorColumn: View {
    let selectedNook: Nook?
    @State private var taskContent = ""
    @State private var isAIInputVisible = false
    @State private var viewModel: TaskEditorViewModel?
    
    init(selectedNook: Nook?) {
        self.selectedNook = selectedNook
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Editor Header
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
                    }
                    
                    Spacer()
                    
                    if selectedNook != nil {
                        HStack(spacing: AppTheme.Spacing.medium) {
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
                .background(theme.backgroundSecondary)
                
                Divider()
                
                // Editor Content
                ZStack {
                        if selectedNook != nil, let vm = viewModel {
                        VStack(spacing: 0) {
                            // Main Editor
                            editorView(theme: theme, viewModel: vm)
                                .background(
                                    Rectangle()
                                        .fill(theme.background)
                                )
                                .overlay(
                                    Rectangle()
                                        .stroke(
                                            Color.clear,
                                            lineWidth: 2
                                        )
                                        .animation(.easeInOut(duration: 0.3), value: isAIInputVisible)
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
            }
        }
        .onChange(of: selectedNook) { _, newNook in
            if let nook = newNook {
                viewModel = TaskEditorViewModel(nook: nook)
                loadContent()
            } else {
                viewModel = nil
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
            .padding(AppTheme.Spacing.large)
            .animation(.easeInOut(duration: 0.3), value: isAIInputVisible)
            .opacity(viewModel.isSendingQuery ? 0.3 : (viewModel.isReceivingResponse ? 0.6 : 1.0))
            .animation(.easeInOut(duration: 0.2), value: viewModel.isSendingQuery)
            .animation(.easeInOut(duration: 0.2), value: viewModel.isReceivingResponse)
            
            // Modern Loading Overlay with enhanced animation
            if viewModel.isSendingQuery || viewModel.isReceivingResponse {
                AILoadingView(
                    isLoading: viewModel.isSendingQuery,
                    isReceiving: viewModel.isReceivingResponse,
                    streamingContent: viewModel.streamingContent,
                    theme: theme
                )
                .transition(.scale(scale: 0.8).combined(with: .opacity))
                .zIndex(2)
                
                // Show streaming preview if receiving
                if viewModel.isReceivingResponse && !viewModel.streamingContent.isEmpty {
                    VStack {
                        Spacer()
                        StreamingTextPreview(
                            content: viewModel.streamingContent,
                            theme: theme
                        )
                        .padding(.bottom, 100)
                    }
                    .zIndex(1)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
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
