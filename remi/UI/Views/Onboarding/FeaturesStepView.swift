import SwiftUI

struct FeaturesStepView: View {
    let theme: Theme
    @State private var selectedFeature: Feature = .ai
    @State private var animateElements = false
    
    enum Feature: CaseIterable {
        case ai, nooks, hotkeys, reordering
        
        var title: String {
            switch self {
            case .ai: return "AI Assistant"
            case .nooks: return "Smart Nooks"
            case .hotkeys: return "Global Access"
            case .reordering: return "Drag & Drop"
            }
        }
        
        var icon: String {
            switch self {
            case .ai: return "brain.head.profile"
            case .nooks: return "folder.fill"
            case .hotkeys: return "keyboard.fill"
            case .reordering: return "arrow.up.and.down"
            }
        }
        
        var description: String {
            switch self {
            case .ai: return "Smart suggestions and content improvements powered by AI"
            case .nooks: return "Organize thoughts into focused, searchable spaces"
            case .hotkeys: return "Access Remi instantly from anywhere with custom shortcuts"
            case .reordering: return "Arrange and prioritize nooks with intuitive drag & drop"
            }
        }
        
        var color: Color {
            switch self {
            case .ai: return .purple
            case .nooks: return .blue
            case .hotkeys: return .green
            case .reordering: return .orange
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Text("Powerful Features")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.2), value: animateElements)
                
                Text("Tap to explore what makes Remi special")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
            }
            
            Spacer(minLength: 16)
            
            // Clean Feature Grid - 2x2 layout with proper spacing
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    CleanFeatureCard(
                        feature: .ai,
                        isSelected: selectedFeature == .ai,
                        onSelect: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFeature = .ai
                            }
                        },
                        theme: theme,
                        delay: 0.6
                    )
                    
                    CleanFeatureCard(
                        feature: .nooks,
                        isSelected: selectedFeature == .nooks,
                        onSelect: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFeature = .nooks
                            }
                        },
                        theme: theme,
                        delay: 0.8
                    )
                }
                
                HStack(spacing: 16) {
                    CleanFeatureCard(
                        feature: .hotkeys,
                        isSelected: selectedFeature == .hotkeys,
                        onSelect: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFeature = .hotkeys
                            }
                        },
                        theme: theme,
                        delay: 1.0
                    )
                    
                    CleanFeatureCard(
                        feature: .reordering,
                        isSelected: selectedFeature == .reordering,
                        onSelect: { 
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedFeature = .reordering
                            }
                        },
                        theme: theme,
                        delay: 1.2
                    )
                }
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 30)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
            
            Spacer(minLength: 16)
            
            // Selected Feature Detail
            SelectedFeatureDetailView(feature: selectedFeature, theme: theme)
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.4), value: animateElements)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

struct CleanFeatureCard: View {
    let feature: FeaturesStepView.Feature
    let isSelected: Bool
    let onSelect: () -> Void
    let theme: Theme
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: 8) {
                Image(systemName: feature.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(feature.color)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(feature.color.opacity(isSelected ? 0.2 : 0.1))
                    )
                
                Text(feature.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background {
                Color.clear
                    .liquidGlassSurface(
                        cornerRadius: 16,
                        strokeOpacity: isSelected ? 0 : 0.06,
                        fallbackMaterial: .thickMaterial
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? feature.color : Color.clear, lineWidth: 2)
                    )
                    .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(animate ? 1.0 : 0.0)
        .offset(y: animate ? 0 : 20)
        .animation(.easeOut(duration: 0.6).delay(delay), value: animate)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
        .onAppear {
            animate = true
        }
    }
}

struct SelectedFeatureDetailView: View {
    let feature: FeaturesStepView.Feature
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: feature.icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(feature.color)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(feature.color.opacity(0.15))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(feature.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(feature.description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.08, fallbackMaterial: .thickMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(feature.color.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .transition(.asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        ))
        .id(feature)
    }
}

struct FeaturesStepView_Previews: PreviewProvider {
    static var previews: some View {
        Themed { theme in
            FeaturesStepView(theme: theme)
        }
        .frame(width: 700, height: 500)
    }
}
