import SwiftUI

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared

    var body: some View {
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
            .transition(.opacity.animation(.easeInOut))
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
