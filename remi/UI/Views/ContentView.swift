import SwiftUI

struct ContentView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared

    var body: some View {
        ZStack {
            if settingsManager.hasCompletedOnboarding {
                NookListView()
                    .frame(width: 600, height: 700)
                    .transition(.opacity.animation(.easeInOut))
            } else {
                OnboardingView()
                    .transition(.opacity.animation(.easeInOut))
            }
            
            ToastView()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
