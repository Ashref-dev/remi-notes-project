import SwiftUI

struct OnboardingProgressBar: View {
    let currentStep: OnboardingService.OnboardingStep
    let totalSteps: Int
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalSteps, id: \.self) { index in
                Rectangle()
                    .fill(index <= currentStep.rawValue ? theme.accent : theme.textSecondary.opacity(0.25))
                    .frame(height: 4)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.xlarge)
        .padding(.top, AppTheme.Spacing.medium)
    }
}

struct OnboardingProgressBar_Previews: PreviewProvider {
    static var previews: some View {
        Themed { theme in
            OnboardingProgressBar(
                currentStep: .permissions,
                totalSteps: 5,
                theme: theme
            )
        }
        .frame(width: 400, height: 50)
    }
}
