import SwiftUI

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared

    var body: some View {
        NavigationStack {
            Themed { theme in
                Group {
                    if settingsManager.hasCompletedOnboarding {
                        NookListView()
                    } else {
                        OnboardingView()
                    }
                }
                .frame(width: AppTheme.Popover.width, height: AppTheme.Popover.height)
                .background(theme.background)
            }
        }
        .errorBanner() // Add error banner support
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
