import SwiftUI

struct WelcomeStepView: View {
    let theme: Theme
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Hero Section - Centered and compact
            VStack(spacing: 12) {
                // Logo with subtle background
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                }
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                
                VStack(spacing: 8) {
                    Text("Welcome to Remi")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(theme.textPrimary)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
                    
                    Text("AI-powered notes that think with you")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(animateElements ? 1.0 : 0.0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
                }
            }
            
            // Feature Cards - Clean grid layout
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    FeatureCard(
                        icon: "brain.head.profile",
                        title: "Smart AI",
                        description: "Intelligent assistance",
                        color: .purple,
                        theme: theme,
                        delay: 0.8
                    )
                    
                    FeatureCard(
                        icon: "keyboard.fill",
                        title: "Global Hotkey",
                        description: "Quick access anywhere",
                        color: .blue,
                        theme: theme,
                        delay: 1.0
                    )
                }
                
                HStack(spacing: 16) {
                    FeatureCard(
                        icon: "rectangle.stack.fill",
                        title: "Organized",
                        description: "Keep everything tidy",
                        color: .green,
                        theme: theme,
                        delay: 1.2
                    )
                    
                    FeatureCard(
                        icon: "bolt.fill",
                        title: "Lightning Fast",
                        description: "Instant performance",
                        color: .orange,
                        theme: theme,
                        delay: 1.4
                    )
                }
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 30)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: animateElements)
            
            Spacer()
            
            // Bottom CTA with refined styling
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                    Text("30 seconds setup")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(theme.accent.opacity(0.1))
                )
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(1.6), value: animateElements)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .onAppear {
            animateElements = true
        }
        .onDisappear {
            animateElements = false
        }
    }
}
            

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let theme: Theme
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon with background
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }
            .scaleEffect(animate ? 1.0 : 0.5)
            .opacity(animate ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animate)
            
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .opacity(animate ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.4).delay(delay + 0.2), value: animate)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.08, fallbackMaterial: .thickMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        }
        .onAppear {
            animate = true
        }
    }
}

struct WelcomeStepView_Previews: PreviewProvider {
    static var previews: some View {
        Themed { theme in
            WelcomeStepView(theme: theme)
        }
    }
}
