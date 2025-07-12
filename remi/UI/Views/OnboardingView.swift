import SwiftUI

struct OnboardingView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                Spacer()
                
                // Welcome Section
                VStack {
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.system(size: 70))
                        .foregroundColor(theme.accent)
                        .padding(.bottom, AppTheme.Spacing.medium)
                    
                    Text("Welcome to Remi")
                        .font(.largeTitle.weight(.bold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("Your new AI-powered notepad. Jot down thoughts, tasks, and ideas, and let Remi help you organize and refine them.")
                        .font(.title3)
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 450)
                }
                .padding(AppTheme.Spacing.large)
                
                Spacer()

                // Features Section
                VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                    FeatureView(
                        imageName: "keyboard.fill",
                        title: "Global Hotkey",
                        description: "Bring up Remi from anywhere. Change the default (Cmd+Option+R) in Settings.",
                        theme: theme
                    )
                    FeatureView(
                        imageName: "wand.and.stars",
                        title: "AI Assistant",
                        description: "Ask Remi to edit, summarize, or add to your notes.",
                        theme: theme
                    )
                }
                .padding(.horizontal, AppTheme.Spacing.xlarge)
                
                Spacer()
                Spacer()

                // Get Started Button
                Button(action: {
                    withAnimation {
                        settingsManager.hasCompletedOnboarding = true
                    }
                }) {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(theme.accent)
                        .foregroundColor(theme.background)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
                .buttonStyle(.plain)
                .padding(AppTheme.Spacing.xlarge)
            }
            .background(theme.background)
        }
    }
}

struct FeatureView: View {
    let imageName: String
    let title: String
    let description: String
    let theme: Theme

    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: imageName)
                .font(.title)
                .foregroundColor(theme.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                Text(description)
                    .font(.body)
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
    }
}
