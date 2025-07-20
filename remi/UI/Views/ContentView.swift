import SwiftUI

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var selectedNook: Nook?
    @State private var showingSettings = false

    var body: some View {
        Themed { theme in
            Group {
                if settingsManager.hasCompletedOnboarding {
                    if showingSettings {
                        IntegratedSettingsView(showingSettings: $showingSettings)
                            .frame(width: AppTheme.Popover.width, height: AppTheme.Popover.height)
                            .background(theme.background)
                    } else {
                        ThreeColumnWorkspace(
                            selectedNook: $selectedNook,
                            showingSettings: $showingSettings
                        )
                        .frame(width: AppTheme.Popover.width, height: AppTheme.Popover.height)
                        .background(theme.background)
                    }
                } else {
                    OnboardingView()
                        .frame(width: AppTheme.Popover.width, height: AppTheme.Popover.height)
                        .background(theme.background)
                }
            }
        }
        .errorBanner() // Add error banner support
    }
}

struct ThreeColumnWorkspace: View {
    @Binding var selectedNook: Nook?
    @Binding var showingSettings: Bool
    @State private var sidebarCollapsed = false
    
    var body: some View {
        Themed { theme in
            HStack(spacing: 0) {
                // Column 1: Sidebar (Nook List)
                if sidebarCollapsed {
                    CollapsedSidebarView(
                        selectedNook: $selectedNook,
                        onExpand: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sidebarCollapsed = false
                            }
                        }
                    )
                    .frame(width: 60)
                    .background(theme.backgroundSecondary)
                } else {
                    SidebarView(
                        selectedNook: $selectedNook,
                        showingSettings: $showingSettings,
                        onCollapse: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                sidebarCollapsed = true
                            }
                        }
                    )
                    .frame(width: 300)
                    .background(theme.backgroundSecondary)
                }
                
                Divider()
                
                // Column 2: Editor (Full width for focus)
                if let nook = selectedNook {
                    TaskEditorView(nook: nook)
                        .background(theme.background)
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(theme.textSecondary.opacity(0.3))
                        
                        Text("Select a nook to start editing")
                            .font(.system(size: 16))
                            .foregroundColor(theme.textSecondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.background)
                }
            }
        }
    }
}

// MARK: - Collapsed Sidebar View

struct CollapsedSidebarView: View {
    @Binding var selectedNook: Nook?
    let onExpand: () -> Void
    @StateObject private var viewModel = NookListViewModel()
    @State private var showingSettings = false
    @State private var isHoveringExpand = false
    @State private var isHoveringSettings = false
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header with expand button
                VStack(spacing: AppTheme.Spacing.medium) {
                    Button(action: onExpand) {
                        Image(systemName: "sidebar.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.accent)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(theme.accent.opacity(isHoveringExpand ? 0.2 : 0.1))
                            )
                            .scaleEffect(isHoveringExpand ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isHoveringExpand)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHoveringExpand = hovering
                    }
                    .accessibilityLabel("Expand sidebar")
                    
                    Divider()
                        .padding(.horizontal, AppTheme.Spacing.small)
                }
                .padding(.top, AppTheme.Spacing.large)
                
                // Nook Icons
                ScrollView {
                    LazyVStack(spacing: AppTheme.Spacing.small) {
                        ForEach(viewModel.filteredNooks) { nook in
                            CollapsedNookItem(
                                nook: nook,
                                isSelected: selectedNook?.id == nook.id,
                                onTap: { selectedNook = nook },
                                theme: theme
                            )
                        }
                    }
                    .padding(.vertical, AppTheme.Spacing.medium)
                }
                
                Spacer()
                
                // Settings icon at bottom
                VStack(spacing: AppTheme.Spacing.medium) {
                    Divider()
                        .padding(.horizontal, AppTheme.Spacing.small)
                    
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(isHoveringSettings ? theme.accent : theme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isHoveringSettings ? theme.accent.opacity(0.1) : Color.clear)
                            )
                            .scaleEffect(isHoveringSettings ? 1.05 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isHoveringSettings)
                    }
                    .buttonStyle(.plain)
                    .onHover { hovering in
                        isHoveringSettings = hovering
                    }
                    .accessibilityLabel("Settings")
                }
                .padding(.bottom, AppTheme.Spacing.large)
            }
        }
        .onAppear {
            viewModel.fetchNooks()
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }
}

// MARK: - Collapsed Nook Item

struct CollapsedNookItem: View {
    let nook: Nook
    let isSelected: Bool
    let onTap: () -> Void
    let theme: Theme
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(isSelected ? nook.iconColor.color.opacity(0.2) : 
                          (isHovering ? theme.backgroundSecondary.opacity(0.8) : Color.clear))
                    .overlay(
                        Circle()
                            .stroke(
                                isSelected ? nook.iconColor.color.opacity(0.5) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: nook.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? nook.iconColor.color : theme.textSecondary)
                    .scaleEffect(isHovering ? 1.1 : 1.0)
            }
            .animation(.easeInOut(duration: 0.2), value: isSelected)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel(nook.name)
        .help(nook.name) // Tooltip on hover
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
