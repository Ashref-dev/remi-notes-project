import SwiftUI

struct TaskEditorView: View {
    @StateObject private var viewModel: TaskEditorViewModel
    @State private var isMarkdownPreviewEnabled = false
    @State private var isAIInputVisible = false
    @State private var shouldFocusAIInput = false
    @State private var isShowingHistory = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    let nook: Nook
    let workspaceMode: WorkspaceMode
    @Binding var showingSettings: Bool
    @Binding var pendingAIPreset: String?

    init(
        nook: Nook,
        workspaceMode: WorkspaceMode = .quickPopover,
        showingSettings: Binding<Bool> = .constant(false),
        pendingAIPreset: Binding<String?> = .constant(nil)
    ) {
        self.nook = nook
        self.workspaceMode = workspaceMode
        self._showingSettings = showingSettings
        self._pendingAIPreset = pendingAIPreset
        _viewModel = StateObject(wrappedValue: TaskEditorViewModel(nook: nook))
        _isMarkdownPreviewEnabled = State(initialValue: UserDefaults.standard.bool(forKey: "isMarkdownPreviewEnabled"))
    }

    var body: some View {
        Themed { theme in
            ZStack(alignment: .top) {
                VStack(spacing: 0) {
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

                    Color.clear.frame(height: 70)
                }

                floatingTopBar(theme: theme)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                VStack {
                    Spacer()
                    statusChips(theme: theme)
                        .padding(.leading, 16)
                        .padding(.bottom, 70)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }

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
            .onAppear {
                viewModel.loadRevisions()
            }
            .onDisappear {
                viewModel.forceSave()
            }
            .onChange(of: nook) { _, newValue in
                viewModel.nook = newValue
            }
            .onChange(of: pendingAIPreset) { _, newValue in
                guard let newValue else { return }
                pendingAIPreset = nil
                viewModel.applyPreset(newValue)
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
            .sheet(isPresented: $isShowingHistory) {
                VersionHistoryView(revisions: viewModel.revisions) { revision in
                    viewModel.restore(revision)
                }
            }
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        var handled = false
        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier("public.file-url") {
                provider.loadItem(forTypeIdentifier: "public.file-url", options: nil) { item, _ in
                    if let data = item as? Data,
                       let urlStr = String(data: data, encoding: .utf8),
                       let url = URL(string: urlStr) {
                        DispatchQueue.main.async {
                            let filename = url.lastPathComponent
                            let markdownLink: String
                            let isImage = ["jpg", "jpeg", "png", "gif", "webp", "heic"].contains(url.pathExtension.lowercased())
                            if isImage {
                                markdownLink = "![\(filename)](\(url.absoluteString))"
                            } else {
                                markdownLink = "[\(filename)](\(url.absoluteString))"
                            }
                            viewModel.enhanceContent(with: markdownLink, actionName: "Drop File")
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

            HStack(spacing: 8) {
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

                Button {
                    let willShow = !isAIInputVisible
                    withOptionalAnimation(.easeInOut(duration: 0.16)) {
                        isAIInputVisible = willShow
                    }
                    if willShow {
                        shouldFocusAIInput = true
                    }
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

                Menu {
                    Menu("AI Presets") {
                        ForEach(SettingsManager.shared.aiQuickActions, id: \.self) { preset in
                            Button(preset) {
                                viewModel.applyPreset(preset)
                            }
                        }
                    }
                    Button("Version History…") {
                        viewModel.loadRevisions()
                        isShowingHistory = true
                    }
                    Divider()
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

            if let ambientSuggestion = viewModel.ambientSuggestion {
                ambientSuggestionChip(ambientSuggestion, theme: theme)
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

    @ViewBuilder
    private func ambientSuggestionChip(_ suggestion: AmbientSuggestion, theme: Theme) -> some View {
        HStack(spacing: 8) {
            Image(systemName: suggestion.systemImage)
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 1) {
                Text(suggestion.title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(theme.textPrimary)
                Text(suggestion.subtitle)
                    .font(.system(size: 9))
                    .foregroundStyle(theme.textSecondary)
                    .lineLimit(1)
            }

            Button {
                viewModel.applyAmbientSuggestion()
            } label: {
                Text("Apply")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(theme.accent)
            }
            .buttonStyle(.plain)

            Button {
                viewModel.dismissAmbientSuggestion()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(theme.textSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.08, fallbackMaterial: .thickMaterial)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(suggestion.title). \(suggestion.subtitle)")
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

    private func withOptionalAnimation(_ animation: Animation, _ updates: @escaping () -> Void) {
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
            .offset(
                x: isAnimating ? geometry.size.width : -geometry.size.width * 2,
                y: isAnimating ? geometry.size.height : -geometry.size.height * 2
            )
            .blendMode(.plusLighter)
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                isAnimating = true
            }
        }
    }
}
