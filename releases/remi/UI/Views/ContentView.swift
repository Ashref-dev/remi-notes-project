import SwiftUI

enum WorkspaceMode {
    case quickPopover
    case focusWindow
}

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var showingSettings = false

    let workspaceMode: WorkspaceMode

    private var surfaceWidth: CGFloat {
        workspaceMode == .focusWindow ? 1100 : AppTheme.Popover.width
    }

    private var surfaceHeight: CGFloat {
        workspaceMode == .focusWindow ? 760 : AppTheme.Popover.height
    }

    init(workspaceMode: WorkspaceMode = .quickPopover) {
        self.workspaceMode = workspaceMode
    }

    var body: some View {
        Themed { _ in
            Group {
                if settingsManager.hasCompletedOnboarding {
                    if showingSettings {
                        IntegratedSettingsView(showingSettings: $showingSettings)
                            .frame(width: surfaceWidth, height: surfaceHeight)
                    } else {
                        WorkspaceShell(
                            showingSettings: $showingSettings,
                            workspaceMode: workspaceMode
                        )
                        .frame(width: surfaceWidth, height: surfaceHeight)
                    }
                } else {
                    OnboardingView()
                        .frame(width: surfaceWidth, height: surfaceHeight)
                }
            }
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.06, fallbackMaterial: .ultraThinMaterial)
            }
        }
        .errorBanner()
        .onReceive(NotificationCenter.default.publisher(for: .openSettings)) { _ in
            showingSettings = true
        }
    }
}

struct WorkspaceShell: View {
    @Binding var showingSettings: Bool
    let workspaceMode: WorkspaceMode

    @StateObject private var railViewModel = NookListViewModel.shared
    @State private var isManagingNooks = false
    @State private var isShowingCommandPalette = false
    @State private var editorRequest: NookEditorRequest?
    @State private var pendingAIPreset: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        Themed { theme in
            ZStack {
                if let nook = railViewModel.selectedNook {
                    TaskEditorView(
                        nook: nook,
                        workspaceMode: workspaceMode,
                        showingSettings: $showingSettings,
                        pendingAIPreset: $pendingAIPreset
                    )
                    .id(nook.id)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyState(theme: theme)
                }

                VStack {
                    Spacer()
                    FloatingNookStrip(
                        viewModel: railViewModel,
                        selectedNook: selectedNookBinding,
                        glassNamespace: glassNamespace,
                        onManageTapped: {
                            isManagingNooks = true
                        }
                    )
                }

                if isManagingNooks {
                    ManageNooksOverlay(
                        viewModel: railViewModel,
                        selectedNook: selectedNookBinding,
                        isPresented: isManagingNooks,
                        onEditNote: { nook, area in
                            editorRequest = NookEditorRequest(nook: nook, focusArea: area)
                        },
                        onClose: { withOptionalAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { isManagingNooks = false } }
                    )
                    .zIndex(10)
                }

                if isShowingCommandPalette {
                    ZStack {
                        Color.black.opacity(0.15)
                            .ignoresSafeArea()
                            .onTapGesture {
                                isShowingCommandPalette = false
                            }

                        CommandPaletteView(
                            nookListViewModel: railViewModel,
                            isPresented: $isShowingCommandPalette,
                            theme: theme,
                            commandContext: commandContext
                        )
                        .padding(.top, 100)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .zIndex(20)
                    .transition(.opacity)
                }
            }
            .background(
                Button("") {
                    withOptionalAnimation(.easeInOut(duration: 0.15)) {
                        isShowingCommandPalette.toggle()
                    }
                }
                .keyboardShortcut("k", modifiers: .command)
                .hidden()
            )
            .onAppear {
                railViewModel.fetchNooks()
                if railViewModel.selectedNook == nil {
                    railViewModel.select(railViewModel.filteredNooks.first)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .toggleCommandPalette)) { _ in
                withOptionalAnimation(.easeInOut(duration: 0.15)) {
                    isShowingCommandPalette.toggle()
                }
            }
            .sheet(item: $editorRequest) { request in
                NookEditorSheetHost(initialRequest: request) { updatedNook in
                    if let savedNook = railViewModel.updateNook(updatedNook),
                       railViewModel.selectedNook?.id == savedNook.id {
                        railViewModel.select(savedNook)
                    }
                }
            }
        }
    }

    private var selectedNookBinding: Binding<Nook?> {
        Binding(
            get: { railViewModel.selectedNook },
            set: { railViewModel.select($0) }
        )
    }

    private var commandContext: CommandContext {
        CommandContext(
            currentNook: railViewModel.selectedNook,
            nooks: railViewModel.filteredNooks,
            quickActions: SettingsManager.shared.aiQuickActions,
            openNote: { nook in
                railViewModel.select(nook)
            },
            createNote: { name in
                if railViewModel.createNook(named: name) != nil {
                    HapticsService.shared.perform(.noteCreated)
                }
            },
            deleteNote: { nook in
                if railViewModel.deleteNook(nook) {
                    HapticsService.shared.perform(.noteDeleted)
                }
            },
            editNote: { nook, area in
                editorRequest = NookEditorRequest(nook: nook, focusArea: area)
            },
            openFocusWindow: {
                NotificationCenter.default.post(name: .openFocusWindow, object: nil)
            },
            openSettings: {
                showingSettings = true
            },
            setTheme: { option in
                SettingsManager.shared.colorSchemeOption = option
            },
            applyAIPreset: { preset in
                pendingAIPreset = preset
            }
        )
    }

    @ViewBuilder
    private func emptyState(theme: Theme) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "note.text")
                .font(.system(size: 32))
                .foregroundStyle(theme.textSecondary)
            Text("No Notes Found")
                .font(.system(size: 14, weight: .semibold))
            Button("Create a Note") {
                isManagingNooks = true
            }
            .liquidGlassButtonStyle(prominent: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func withOptionalAnimation(_ animation: Animation, _ updates: @escaping () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }
}

private struct NookEditorSheetHost: View {
    let initialRequest: NookEditorRequest
    let onSave: (Nook) -> Void

    @State private var draftNook: Nook
    @State private var isPresented = true
    @Environment(\.dismiss) private var dismiss

    init(initialRequest: NookEditorRequest, onSave: @escaping (Nook) -> Void) {
        self.initialRequest = initialRequest
        self.onSave = onSave
        _draftNook = State(initialValue: initialRequest.nook)
    }

    var body: some View {
        NookEditorSheet(
            nook: $draftNook,
            isPresented: $isPresented,
            focusArea: initialRequest.focusArea
        )
        .onChange(of: isPresented) { _, newValue in
            guard !newValue else { return }
            if draftNook != initialRequest.nook {
                onSave(draftNook)
            }
            dismiss()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
