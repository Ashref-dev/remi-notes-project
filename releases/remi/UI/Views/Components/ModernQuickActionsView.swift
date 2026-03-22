import SwiftUI

struct ModernQuickActionsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var connectionStatus = ConnectionStatusService.shared
    let onActionTap: (String) -> Void
    
    private var isAPIKeyConfigured: Bool {
        settingsManager.isAPIKeyConfigured()
    }
    
    private var quickActions: [QuickActionCategory] {
        if !connectionStatus.isConnected {
            return [
                QuickActionCategory(
                    title: "Connection",
                    actions: [
                        QuickAction(
                            title: "Check Connection",
                            description: "Verify network status",
                            icon: "wifi.slash",
                            color: .red,
                            action: "Troubleshoot network connection"
                        )
                    ]
                )
            ]
        } else if !isAPIKeyConfigured {
            return [
                QuickActionCategory(
                    title: "Setup",
                    actions: [
                        QuickAction(
                            title: "API Key Required",
                            description: "Configure OpenRouter API key",
                            icon: "key.fill",
                            color: .orange,
                            action: "Open Settings to configure API key"
                        )
                    ]
                )
            ]
        } else {
            return [
                QuickActionCategory(
                    title: "Writing & Style",
                    actions: [
                        QuickAction(
                            title: "Fix Grammar",
                            description: "Correct errors & improve clarity",
                            icon: "textformat.abc",
                            color: .blue,
                            action: "Fix grammar, spelling, and improve clarity of this text"
                        ),
                        QuickAction(
                            title: "Professional Tone",
                            description: "Make it more formal",
                            icon: "person.crop.circle.badge.checkmark",
                            color: .indigo,
                            action: "Rewrite this text in a professional, formal tone"
                        ),
                        QuickAction(
                            title: "Casual Tone",
                            description: "Make it more conversational",
                            icon: "bubble.left.and.bubble.right",
                            color: .cyan,
                            action: "Rewrite this text in a casual, conversational tone"
                        ),
                        QuickAction(
                            title: "Simplify",
                            description: "Use simpler language",
                            icon: "textformat.size.smaller",
                            color: .green,
                            action: "Simplify this text using clearer, more accessible language"
                        )
                    ]
                ),
                QuickActionCategory(
                    title: "Structure & Organization",
                    actions: [
                        QuickAction(
                            title: "Summarize",
                            description: "Create concise summary",
                            icon: "list.bullet.rectangle",
                            color: .teal,
                            action: "Create a concise summary highlighting the main points"
                        ),
                        QuickAction(
                            title: "Bullet Points",
                            description: "Convert to list format",
                            icon: "list.bullet",
                            color: .purple,
                            action: "Convert this text into clear bullet points"
                        ),
                        QuickAction(
                            title: "Add Headlines",
                            description: "Structure with headers",
                            icon: "textformat.size.larger",
                            color: .orange,
                            action: "Add clear headlines and structure to organize this content"
                        ),
                        QuickAction(
                            title: "Reorganize",
                            description: "Improve logical flow",
                            icon: "arrow.up.arrow.down.square",
                            color: .pink,
                            action: "Reorganize this content for better logical flow and readability"
                        )
                    ]
                ),
                QuickActionCategory(
                    title: "Content Enhancement",
                    actions: [
                        QuickAction(
                            title: "Expand Ideas",
                            description: "Add detail & examples",
                            icon: "plus.circle",
                            color: .mint,
                            action: "Expand on these ideas with more detail, examples, and context"
                        ),
                        QuickAction(
                            title: "Add Examples",
                            description: "Include concrete examples",
                            icon: "lightbulb",
                            color: .yellow,
                            action: "Add relevant examples and concrete illustrations to support these points"
                        ),
                        QuickAction(
                            title: "Call to Action",
                            description: "Add compelling CTA",
                            icon: "hand.raised.fill",
                            color: .red,
                            action: "Add a compelling call-to-action to motivate the reader"
                        ),
                        QuickAction(
                            title: "Keywords",
                            description: "Optimize for search",
                            icon: "magnifyingglass.circle",
                            color: .gray,
                            action: "Optimize this content with relevant keywords for better searchability"
                        )
                    ]
                )
            ]
        }
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(quickActions, id: \.title) { category in
                            // Category section
                            VStack(alignment: .leading, spacing: 10) {
                                // Category header
                                HStack {
                                    Text(category.title)
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(theme.textPrimary)
                                        .textCase(.uppercase)
                                        .tracking(0.5)
                                    
                                    Spacer()
                                    
                                    Text("\(category.actions.count)")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(theme.textSecondary.opacity(0.6))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(
                                            Capsule()
                                                .fill(theme.backgroundSecondary)
                                        )
                                }
                                .padding(.horizontal, 16)
                                
                                // Actions grid - completely static
                                VStack(spacing: 8) {
                                    ForEach(0..<Int(ceil(Double(category.actions.count)/2.0)), id: \.self) { rowIndex in
                                        HStack(spacing: 8) {
                                            let leftIndex = rowIndex * 2
                                            let rightIndex = leftIndex + 1
                                            
                                            if leftIndex < category.actions.count {
                                                ModernActionCard(
                                                    action: category.actions[leftIndex],
                                                    theme: theme
                                                ) {
                                                    onActionTap(category.actions[leftIndex].action)
                                                }
                                            }
                                            
                                            if rightIndex < category.actions.count {
                                                ModernActionCard(
                                                    action: category.actions[rightIndex],
                                                    theme: theme
                                                ) {
                                                    onActionTap(category.actions[rightIndex].action)
                                                }
                                            } else {
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal, 12)
                            }
                            
                            // Divider between categories
                            if category != quickActions.last {
                                Divider()
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    // Ensure no implicit animation within content
                    .animation(nil, value: quickActions.count)
                    .padding(.vertical, 16)
                }
                .frame(maxHeight: 250)
                // Disable all implicit animations for inner content so cards don't animate
                .transaction { txn in
                    txn.disablesAnimations = true
                    txn.animation = nil
                }
            }
            .glassBackground(cornerRadius: 8, strokeOpacity: 0.08)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct ModernActionCard: View {
    let action: QuickAction
    let theme: Theme
    let onTap: () -> Void
    
    @State private var isHovered = false
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Icon with modern styling
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        action.color.opacity(0.12),
                                        action.color.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: action.icon)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(action.color)
                            .symbolRenderingMode(.hierarchical)
                    }
                    
                    Spacer()
                    
                    // Subtle action indicator
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary.opacity(isHovered ? 0.7 : 0.3))
                        .scaleEffect(isHovered ? 1.1 : 1.0)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 3) {
                    Text(action.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                        .multilineTextAlignment(.leading)
                    
                    Text(action.description)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(12)
            .frame(minHeight: 72)
            .background {
                Color.clear
                    .liquidGlassSurface(
                        cornerRadius: 10,
                        strokeOpacity: isHovered ? 0.16 : 0.08,
                        interactive: true,
                        fallbackMaterial: .regularMaterial
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(
                                isHovered ? action.color.opacity(0.3) : Color.white.opacity(0.08),
                                lineWidth: isHovered ? 1.5 : 1
                            )
                    )
            }
            .shadow(
                color: isPressed ? .clear : (isHovered ? action.color.opacity(0.1) : Color.black.opacity(0.03)),
                radius: isPressed ? 0 : (isHovered ? 4 : 2),
                x: 0,
                y: isPressed ? 0 : (isHovered ? 2 : 1)
            )
        }
    .buttonStyle(.plain)
    .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.01 : 1.0))
    // Ensure this view never animates in/out when panel appears
    .transition(.identity)
        .onHover { hovering in
            isHovered = hovering
        }
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Data structures
struct QuickActionCategory: Equatable {
    let title: String
    let actions: [QuickAction]
    
    static func == (lhs: QuickActionCategory, rhs: QuickActionCategory) -> Bool {
        return lhs.title == rhs.title
    }
}

struct QuickAction: Identifiable, Equatable {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: String
    var id: String { title }
}
