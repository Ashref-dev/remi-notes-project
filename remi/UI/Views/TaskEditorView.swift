import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var isMarkdownPreviewEnabled = false
    @State private var isAIInputVisible = false
    @State private var shouldFocusAIInput = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    let nook: Nook
    let workspaceMode: WorkspaceMode
    @Binding var showingSettings: Bool

    init(nook: Nook, workspaceMode: WorkspaceMode = .quickPopover, showingSettings: Binding<Bool> = .constant(false)) {
        self.nook = nook
        self.workspaceMode = workspaceMode
        self._showingSettings = showingSettings
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
        _isMarkdownPreviewEnabled = State(initialValue: UserDefaults.standard.bool(forKey: "isMarkdownPreviewEnabled"))
    }

    var body: some View {
        Themed { theme in
            ZStack(alignment: .top) {
                // Editor
                VStack(spacing: 0) {
                    // Spacer for the top floating bar
                    Color.clear.frame(height: 50)
                    
                    LiveMarkdownEditor(
                        text: $viewModel.taskContent,
                        theme: theme,
                        isMarkdownPreviewEnabled: isMarkdownPreviewEnabled,
                        autoFocus: true,
                        onTextViewReady: { textView in
                            viewModel.textViewUndoManager = textView.undoManager
                            viewModel.textView = textView
                        }
                    )
                    .id("editor-\(isMarkdownPreviewEnabled ? "markdown" : "plain")")
                    .opacity(viewModel.isProcessingAI ? 0.6 : 1.0)
                    .overlay {
                        if viewModel.isProcessingAI {
                            AIShimmerOverlay(theme: theme)
                                .allowsHitTesting(false)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    // Padding at the bottom for the strip so we don't type implicitly behind it
                    Color.clear.frame(height: 70)
                }

                // Top Accessory Bar
                floatingTopBar(theme: theme)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                // Toast chips — bottom-left, above the nook strip, never hidden under buttons
                VStack {
                    Spacer()
                    statusChips(theme: theme)
                        .padding(.leading, 16)
                        .padding(.bottom, 70)   // clears the nook strip height + padding
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                // AI Processing overlay
                if viewModel.isProcessingAI {
                    VStack {
                        Spacer()
                        ProgressView("Applying AI edit...")
                            .padding(14)
                            .background(
                                Color.clear
                                    .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.08, fallbackMaterial: .regularMaterial)
                                    .shadow(radius: 10)
                            )
                        Spacer()
                    }
                }
                
                // AI Diff overlay
                if viewModel.showAIDiff {
                    VStack {
                        Spacer()
                        AIDiffView(
                            originalText: viewModel.aiDiffOriginalText,
                            proposedText: viewModel.aiDiffProposedText,
                            theme: theme,
                            onAccept: {
                                viewModel.acceptAIDiff()
                            },
                            onReject: {
                                viewModel.rejectAIDiff()
                            }
                        )
                        .padding(.horizontal, 24)
                        .padding(.bottom, 80) // Stay above the nook strip
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

                // AI Prompt Input
                if isAIInputVisible {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                            .onTapGesture {
                                closeAIInput()
                            }

                        AIInputView(
                            isVisible: $isAIInputVisible,
                            shouldFocus: $shouldFocusAIInput,
                            onSend: handleAIInput
                        )
                        .padding(.horizontal, 40)
                        .padding(.top, 80)
                        .frame(maxHeight: .infinity, alignment: .top)
                        .liquidGlassMorph("editor.aiInput", in: glassNamespace)
                    }
                    .transition(.opacity)
                }
            }
            .onDisappear {
                viewModel.forceSave()
            }
            .onExitCommand {
                if isAIInputVisible {
                    closeAIInput()
                }
            }
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.16), value: isAIInputVisible)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDrop(providers: providers)
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, error in
                    if let data = item as? Data,
                       let urlStr = String(data: data, encoding: .utf8),
                       let url = URL(string: urlStr) {
                        
                        DispatchQueue.main.async {
                            let filename = url.lastPathComponent
                            let absoluteString = url.absoluteString
                            let isImage = ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(url.pathExtension.lowercased())
                            
                            let markdownLink = isImage ? "![\\(filename)](\\(absoluteString))" : "[\\(filename)](\\(absoluteString))"
                            
                            self.viewModel.enhanceContent(with: markdownLink, actionName: "Drop File")
                        }
                    }
                }
                handled = true
            }
        }
        return handled
    }

    @ViewBuilder
    private func floatingTopBar(theme: Theme) -> some View {
        HStack(spacing: 12) {
            // App Identity Pill – tapping opens Settings
            Button {
                showingSettings = true
            } label: {
                HStack(spacing: 8) {
                    if let appIcon = NSImage(named: "AppIcon") {
                        Image(nsImage: appIcon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    } else {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(theme.accent)
                    }
                    Text("Remi")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.textPrimary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .frame(height: 38)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.08, fallbackMaterial: .thinMaterial)
            }
            .help("Settings")

            Spacer()

            // General App Actions & Editor Actions
            HStack(spacing: 8) {
                // Formatting toggle
                Button {
                    isMarkdownPreviewEnabled.toggle()
                    UserDefaults.standard.set(isMarkdownPreviewEnabled, forKey: "isMarkdownPreviewEnabled")
                } label: {
                    Label(
                        isMarkdownPreviewEnabled ? "MD" : "TXT",
                        systemImage: isMarkdownPreviewEnabled ? "doc.richtext" : "doc.plaintext"
                    )
                    .font(.system(size: 12, weight: .semibold))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background {
                    Color.clear
                        .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.08, fallbackMaterial: .thinMaterial)
                }
                .help(isMarkdownPreviewEnabled ? "Show Plain Text" : "Show Markdown Preview")

                // AI toggle
                Button {
                    let willShow = !isAIInputVisible
                    withOptionalAnimation(.easeInOut(duration: 0.16)) {
                        isAIInputVisible = willShow
                    }
                    if willShow { shouldFocusAIInput = true }
                } label: {
                    Label("AI", systemImage: "sparkles")
                        .font(.system(size: 12, weight: .bold))
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 10)
                .frame(height: 38)
                .background {
                    Color.clear
                        .liquidGlassSurface(
                            cornerRadius: 12,
                            strokeOpacity: isAIInputVisible ? 0.25 : 0.08,
                            interactive: true,
                            fallbackMaterial: .thinMaterial
                        )
                }
                .liquidGlassMorph("editor.aiInput", in: glassNamespace)
                .help("Open AI editing tools")

                // More actions — plain Menu, no liquidGlassButtonStyle wrapping to avoid icon doubling
                Menu {
                    Button("Copy as Markdown") { viewModel.copyAllContent(format: .markdown) }
                    Button("Copy as Plain Text") { viewModel.copyAllContent(format: .plainText) }
                    Divider()
                    Button("Undo") { viewModel.textViewUndoManager?.undo() }
                    Button("Redo") { viewModel.textViewUndoManager?.redo() }
                    Divider()
                    if workspaceMode == .quickPopover {
                        Button("Open Focus Window") {
                            NotificationCenter.default.post(name: .openFocusWindow, object: nil)
                        }
                        
                        Divider()
                        
                        Button("Pin to Desktop") {
                            NotificationCenter.default.post(name: .toggleStickyWindow, object: nook)
                        }
                    }
                    Button("Settings") { showingSettings = true }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .bold))
                        .frame(width: 36, height: 38)
                        .contentShape(Rectangle())
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("More Actions")
            }
        }
    }

    @ViewBuilder
    private func statusChips(theme: Theme) -> some View {
        HStack(spacing: 6) {
            if viewModel.showSaveConfirmation {
                statusChip(
                    text: "Saved",
                    icon: "checkmark.circle.fill",
                    tint: .green,
                    theme: theme
                )
            }

            if viewModel.showCopySuccess {
                statusChip(
                    text: "Copied",
                    icon: "doc.on.clipboard.fill",
                    tint: .blue,
                    theme: theme
                )
            }
        }
    }

    @ViewBuilder
    private func statusChip(text: String, icon: String, tint: Color, theme: Theme) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(tint)
            Text(text)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(theme.textPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.08, fallbackMaterial: .thickMaterial)
        }
        .transition(.scale.combined(with: .opacity))
    }

    private var wordCount: Int {
        viewModel.taskContent
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
    }

    private func handleAIInput(prompt: String) {
        Task {
            await viewModel.processAIQuery(prompt: prompt)
        }
    }

    private func closeAIInput() {
        withOptionalAnimation(.easeInOut(duration: 0.16)) {
            isAIInputVisible = false
        }
    }

    private func withOptionalAnimation(
        _ animation: Animation,
        _ updates: @escaping () -> Void
    ) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }
}

struct TaskEditorView_Previews: PreviewProvider {
    static var previews: some View {
        let previewNook = Nook(name: "Preview", url: URL(fileURLWithPath: "/tmp/preview"))
        TaskEditorView(nook: previewNook)
    }
}

struct AIShimmerOverlay: View {
    let theme: Theme
    @State private var isAnimating = false

    var body: some View {
        GeometryReader { geometry in
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0.0),
                    .init(color: theme.accent.opacity(0.3), location: 0.5),
                    .init(color: .clear, location: 1.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: geometry.size.width * 2, height: geometry.size.height * 2)
            .offset(x: isAnimating ? geometry.size.width : -geometry.size.width * 2,
                    y: isAnimating ? geometry.size.height : -geometry.size.height * 2)
            .blendMode(.plusLighter)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
