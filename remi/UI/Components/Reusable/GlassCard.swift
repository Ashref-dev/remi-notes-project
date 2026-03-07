import SwiftUI

/// A reusable glass card component that provides a modern liquid glass effect
/// with proper fallbacks for older macOS versions and accessibility considerations.
struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    let strokeOpacity: Double
    @ViewBuilder let content: Content
    
    init(
        cornerRadius: CGFloat = 12,
        padding: CGFloat = 16,
        strokeOpacity: Double = 0.1,
        @ViewBuilder content: () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.strokeOpacity = strokeOpacity
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .liquidGlassSurface(
                cornerRadius: cornerRadius,
                strokeOpacity: strokeOpacity,
                interactive: false,
                fallbackMaterial: .ultraThinMaterial
            )
    }
}

/// A glass card specifically designed for compact content like buttons or small panels
struct CompactGlassCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GlassCard(
            cornerRadius: 8,
            padding: 12,
            strokeOpacity: 0.08
        ) {
            content
        }
    }
}

/// A glass card designed for larger content areas like editors or main panels
struct PanelGlassCard<Content: View>: View {
    @ViewBuilder let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        GlassCard(
            cornerRadius: 16,
            padding: 20,
            strokeOpacity: 0.12
        ) {
            content
        }
    }
}

/// Extension to provide glass background modifier for any view
extension View {
    /// Applies native Liquid Glass on macOS 26+ with a material fallback on older systems.
    func liquidGlassSurface(
        cornerRadius: CGFloat = 12,
        strokeOpacity: Double = 0.1,
        interactive: Bool = false,
        fallbackMaterial: Material = .regularMaterial
    ) -> some View {
        modifier(
            LiquidGlassSurfaceModifier(
                cornerRadius: cornerRadius,
                strokeOpacity: strokeOpacity,
                interactive: interactive,
                fallbackMaterial: fallbackMaterial
            )
        )
    }

    /// Enables matched-geometry glass morphing between related surfaces.
    @ViewBuilder
    func liquidGlassMorph<ID: Hashable & Sendable>(_ id: ID?, in namespace: Namespace.ID) -> some View {
        if #available(macOS 26.0, *) {
            self
                .glassEffectID(id, in: namespace)
                .glassEffectTransition(.matchedGeometry)
        } else {
            self
        }
    }

    /// Unions adjacent glass shapes into a single adaptive surface.
    @ViewBuilder
    func liquidGlassUnion<ID: Hashable & Sendable>(_ id: ID?, in namespace: Namespace.ID) -> some View {
        if #available(macOS 26.0, *) {
            self.glassEffectUnion(id: id, namespace: namespace)
        } else {
            self
        }
    }

    /// Uses a custom glass button style matching exactly the height and corner radius of other elements.
    @ViewBuilder
    func liquidGlassButtonStyle(prominent: Bool = false) -> some View {
        self.buttonStyle(LiquidGlassButtonStyle(prominent: prominent))
    }

    /// Applies a glass background to the view with customizable parameters
    func glassBackground(
        cornerRadius: CGFloat = 12,
        strokeOpacity: Double = 0.1
    ) -> some View {
        liquidGlassSurface(
            cornerRadius: cornerRadius,
            strokeOpacity: strokeOpacity,
            interactive: false,
            fallbackMaterial: .ultraThinMaterial
        )
    }
}

struct LiquidGlassButtonStyle: ButtonStyle {
    var prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 14)
            .frame(height: 38)
            .background {
                Color.clear
                    .liquidGlassSurface(
                        cornerRadius: 12,
                        strokeOpacity: prominent ? 0.25 : 0.08,
                        interactive: true,
                        fallbackMaterial: .thinMaterial
                    )
            }
            .overlay {
                if prominent {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.accentColor.opacity(configuration.isPressed ? 0.25 : 0.15))
                } else if configuration.isPressed {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.1))
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

private struct LiquidGlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let strokeOpacity: Double
    let interactive: Bool
    let fallbackMaterial: Material
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(NSColor.windowBackgroundColor))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color(NSColor.separatorColor).opacity(0.9), lineWidth: 1)
                }
        } else if #available(macOS 26.0, *) {
            let glass = interactive ? Glass.regular.interactive() : Glass.regular
            content
                .glassEffect(glass, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 0.8)
                        .blendMode(.plusLighter)
                }
        } else {
            content
                .background {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(fallbackMaterial)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Color.white.opacity(strokeOpacity), lineWidth: 1)
                }
        }
    }
}

/// Wraps related controls to let Liquid Glass union and morph naturally on macOS 26+.
struct LiquidGlassContainer<Content: View>: View {
    let spacing: CGFloat?
    @ViewBuilder let content: Content

    init(spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        if #available(macOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) {
                content
            }
        } else {
            content
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Regular glass card
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Regular Glass Card")
                    .font(.headline)
                Text("This demonstrates the standard glass card with proper vibrancy and accessibility.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        
        // Compact glass card
        CompactGlassCard {
            HStack {
                Image(systemName: "star.fill")
                Text("Compact Card")
                    .font(.subheadline)
            }
        }
        
        // Panel glass card
        PanelGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text("Panel Glass Card")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("This is a larger panel designed for main content areas with more padding and prominence.")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        
        // Glass background modifier example
        Text("Glass Background Modifier")
            .font(.caption)
            .padding()
            .glassBackground(cornerRadius: 20, strokeOpacity: 0.15)
    }
    .padding()
    .frame(maxWidth: 400)
    .background(
        LinearGradient(
            colors: [.blue, .purple, .pink],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
