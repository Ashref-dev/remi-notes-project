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
                if !sidebarCollapsed {
                    SidebarView(
                        selectedNook: $selectedNook,
                        showingSettings: $showingSettings
                    )
                    .frame(width: 300)
                    .background(theme.backgroundSecondary)
                    
                    Divider()
                }
                
                // Column 2: Editor (Full width for focus)
                EditorColumn(selectedNook: selectedNook)
                    .background(theme.background)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
