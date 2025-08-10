import SwiftUI

struct OnboardingNavigationBar: View {
    @ObservedObject var onboardingService: OnboardingService
    let onSkip: () -> Void
    let theme: Theme
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            // Skip button
            Button("Skip Setup") {
                onSkip()
            }
            .foregroundColor(theme.textSecondary)
            .font(.system(size: 14))
            
            Spacer()
            
            // Previous button
            if onboardingService.currentStep.rawValue > 0 {
                Button("Previous") {
                    onboardingService.previousStep()
                }
                .buttonStyle(SecondaryButtonStyle(theme: theme))
            }
            
            // Next/Complete button
            Button(nextButtonTitle) {
                if onboardingService.currentStep == .completion {
                    onboardingService.completeOnboarding()
                } else {
                    onboardingService.nextStep()
                }
            }
            .buttonStyle(PrimaryButtonStyle(theme: theme))
            .disabled(!canProceed)
        }
        .padding(.horizontal, AppTheme.Spacing.xlarge)
        .padding(.vertical, AppTheme.Spacing.large)
        .background(theme.backgroundSecondary.opacity(0.85))
        .background(.ultraThinMaterial)
    }
    
    private var nextButtonTitle: String {
        onboardingService.currentStep == .completion ? "Start Using Remi" : "Continue"
    }
    
    private var canProceed: Bool {
        switch onboardingService.currentStep {
        case .permissions:
            return onboardingService.allRequiredPermissionsGranted
        default:
            return true
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let theme: Theme
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(theme.accent)
                    .opacity(configuration.isPressed ? 0.85 : (isHovered ? 0.95 : 1.0))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let theme: Theme
    @State private var isHovered = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(theme.textPrimary)
            .padding(.horizontal, AppTheme.Spacing.large)
            .padding(.vertical, AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .stroke(theme.border, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .fill(isHovered ? theme.backgroundSecondary : Color.clear)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onHover { isHovered = $0 }
    }
}
