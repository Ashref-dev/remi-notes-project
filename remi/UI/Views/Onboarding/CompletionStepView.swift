import SwiftUI

struct CompletionStepView: View {
    @State private var animateElements = false
    @State private var showConfetti = false
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 16) {
                // Success Animation
                VStack(spacing: 12) {
                    ZStack {
                        // Background pulse
                        Circle()
                            .fill(theme.accent.opacity(0.2))
                            .frame(width: 70, height: 70)
                            .scaleEffect(animateElements ? 1.2 : 1.0)
                            .opacity(animateElements ? 0.3 : 0.8)
                            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animateElements)
                        
                        // Success icon
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(theme.accent)
                            .scaleEffect(animateElements ? 1.0 : 0.3)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                    }
                    
                    VStack(spacing: 6) {
                        Text("You're Ready!")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(theme.textPrimary)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
                        
                        Text("Remi is now configured and ready to supercharge your productivity")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(animateElements ? 1.0 : 0.0)
                            .offset(y: animateElements ? 0 : 30)
                            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: animateElements)
                    }
                }
                
                // Quick Tips
                VStack(spacing: 8) {
                    CompletionTip(
                        icon: "command",
                        title: "⌘⇧R",
                        subtitle: "Global hotkey",
                        theme: theme,
                        delay: 1.0
                    )
                    
                    CompletionTip(
                        icon: "plus.circle.fill",
                        title: "Create Nooks",
                        subtitle: "Organize thoughts",
                        theme: theme,
                        delay: 1.2
                    )
                    
                    CompletionTip(
                        icon: "brain.head.profile",
                        title: "AI Assistant",
                        subtitle: "Smart suggestions",
                        theme: theme,
                        delay: 1.4
                    )
                }
                .opacity(animateElements ? 1.0 : 0.0)
                .offset(y: animateElements ? 0 : 40)
                .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(1.0), value: animateElements)
                
                // Start Button
                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                        showConfetti = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        OnboardingService.shared.completeOnboarding()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Start Using Remi")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .frame(height: 40)
                    .frame(maxWidth: 200)
                    .background(
                        LinearGradient(
                            colors: [theme.accent, theme.accent.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(color: theme.accent.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                .buttonStyle(PlainButtonStyle())
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.6), value: animateElements)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .onAppear {
                animateElements = true
            }
            .onDisappear {
                animateElements = false
            }
        }
    }
}

struct CompletionTip: View {
    let icon: String
    let title: String
    let subtitle: String
    let theme: Theme
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(theme.accent)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(theme.accent.opacity(0.1))
                )
                .scaleEffect(animate ? 1.0 : 0.3)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animate)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(theme.cardBackground.opacity(0.6))
        )
        .opacity(animate ? 1.0 : 0.0)
        .offset(x: animate ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
}

struct CompletionStepView_Previews: PreviewProvider {
    static var previews: some View {
        CompletionStepView()
    }
}
