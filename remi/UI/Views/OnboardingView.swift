import SwiftUI

struct OnboardingView: View {
    @StateObject private var onboardingService = OnboardingService.shared
    @StateObject private var permissionsService = PermissionsService.shared
    @State private var showingSkipConfirmation = false
    @State private var navBarHeight: CGFloat = 0

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                OnboardingProgressBar(
                    currentStep: onboardingService.currentStep,
                    totalSteps: OnboardingService.OnboardingStep.allCases.count,
                    theme: theme
                )
                
                ZStack(alignment: .bottom) {
                    // Custom content switcher without tab indicators
                    Group {
                        switch onboardingService.currentStep {
                        case .welcome:
                            WelcomeStepView(theme: theme)
                        case .permissions:
                            PermissionsStepView(
                                permissionsService: permissionsService,
                                theme: theme
                            )
                        case .features:
                            FeaturesStepView(theme: theme)
                        case .completion:
                            CompletionStepView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: onboardingService.currentStep)
                    .padding(.bottom, navBarHeight)
                    
                    OnboardingNavigationBar(
                        onboardingService: onboardingService,
                        onSkip: { showingSkipConfirmation = true },
                        theme: theme
                    )
                    .background(
                        GeometryReader { geo in
                            Color.clear
                                .onAppear { navBarHeight = geo.size.height }
                                .onChange(of: geo.size.height) { navBarHeight = $0 }
                        }
                    )
                }
            }
        }
        .alert("Skip Onboarding?", isPresented: $showingSkipConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Skip", role: .destructive) {
                onboardingService.completeOnboarding()
            }
        } message: {
            Text("You can always access these features in Settings later.")
        }
        .onAppear {
            onboardingService.currentStep = .welcome
        }
    }
}

struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingView()
            .frame(width: 900, height: 720)
    }
}
