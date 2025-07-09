import SwiftUI

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared

    var body: some View {
        Group {
            if settingsManager.hasCompletedOnboarding {
                NookListView()
            } else {
                OnboardingView()
            }
        }
        .transition(.opacity.animation(.easeInOut))
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
