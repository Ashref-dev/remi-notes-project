import SwiftUI

enum WorkspaceMode {
    case quickPopover
    case focusWindow
}

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var selectedNook: Nook?
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
                            selectedNook: $selectedNook,
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
    }
}

struct WorkspaceShell: View {
    @Binding var selectedNook: Nook?
    @Binding var showingSettings: Bool
    let workspaceMode: WorkspaceMode

    @StateObject private var railViewModel = NookListViewModel()
    @State private var isManagingNooks = false
    @State private var isShowingCommandPalette = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var glassNamespace

    var body: some View {
        Themed { theme in
            ZStack {
                // Main Editor Background
                if let nook = selectedNook {
                    TaskEditorView(nook: nook, workspaceMode: workspaceMode, showingSettings: $showingSettings)
                        .id(nook.id)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    emptyState(theme: theme)
                }

                // Floating Nook Strip at the botttom
                VStack {
                    Spacer()
                    FloatingNookStrip(
                        viewModel: railViewModel,
                        selectedNook: $selectedNook,
                        glassNamespace: glassNamespace,
                        onManageTapped: {
                            isManagingNooks = true
                        }
                    )
                }

                // Manage Nooks Overlay
                if isManagingNooks {
                    ManageNooksOverlay(
                        viewModel: railViewModel,
                        selectedNook: $selectedNook,
                        isPresented: isManagingNooks,
                        onClose: { withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) { isManagingNooks = false } }
                    )
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                    .zIndex(10)
                }
                
                // Command Palette Overlay (⌘K)
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
                            theme: theme
                        )
                        .padding(.top, 100)
                        .frame(maxHeight: .infinity, alignment: .top)
                    }
                    .zIndex(20)
                    .transition(.opacity)
                }
            }
            // Invisible button to catch ⌘K for Command Palette anywhere in Workspace
            .background(
                Button("") {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        isShowingCommandPalette.toggle()
                    }
                }
                .keyboardShortcut("k", modifiers: .command)
                .hidden()
            )
            .onAppear {
                railViewModel.fetchNooks()
                if selectedNook == nil {
                    selectedNook = railViewModel.selectedNook ?? railViewModel.filteredNooks.first
                }
            }
            .onChange(of: railViewModel.selectedNook) { _, newValue in
                if selectedNook == nil {
                    selectedNook = newValue
                }
            }
        }
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
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
