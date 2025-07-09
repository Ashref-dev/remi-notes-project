import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @State private var selectedTab = 0

    var body: some View {
        VStack {
            TabView(selection: $selectedTab) {
                OnboardingPageView(
                    imageName: "sparkles",
                    title: "Welcome to Remi",
                    description: "Your new AI-powered notepad. Jot down thoughts, tasks, and ideas, and let Remi help you organize and refine them."
                ).tag(0)
                
                OnboardingPageView(
                    imageName: "keyboard.fill",
                    title: "Global Hotkey",
                    description: "Bring up Remi from anywhere with a quick keyboard shortcut. The default is Cmd+Option+R. You can change this in Settings."
                ).tag(1)
                
                OnboardingPageView(
                    imageName: "mic.fill",
                    title: "Dictate Your Thoughts",
                    description: "Use your voice to quickly add notes. The AI assistant can understand your speech and transcribe it for you."
                ).tag(2)
                
                OnboardingPageView(
                    imageName: "wand.and.stars",
                    title: "AI Assistant",
                    description: "Ask Remi to edit, summarize, or add to your notes. Just type your request and let the AI do the work."
                ).tag(3)
            }
            .tabViewStyle(.automatic)
            
            Button(action: {
                withAnimation {
                    settingsManager.hasCompletedOnboarding = true
                }
            }) {
                Text("Get Started")
                    .font(.headline)
                    .padding(.horizontal, 50)
                    .padding(.vertical, 15)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(15)
            }
            .padding(.bottom, 40)
        }
        .frame(width: 600, height: 700)
        .background(Color(.windowBackgroundColor))
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
            
            VStack(spacing: 10) {
                Text(title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Text(description)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
        }
        .padding(40)
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
