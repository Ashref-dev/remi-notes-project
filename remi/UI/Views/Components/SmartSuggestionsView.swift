import SwiftUI

struct SmartSuggestionsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var connectionStatus = ConnectionStatusService.shared
    @ObservedObject private var errorService = ErrorHandlingService.shared
    
    let onSuggestionTap: (String) -> Void
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    private var suggestions: [SmartSuggestion] {
        var suggestions: [SmartSuggestion] = []
        
        // Context-aware suggestions based on current state
        if !connectionStatus.isConnected {
            suggestions.append(SmartSuggestion(
                title: "Check Connection",
                description: "Verify your internet connection to use AI features",
                icon: "wifi.slash",
                color: .red,
                action: "Troubleshoot network connection"
            ))
        } else if !isAPIKeyConfigured {
            suggestions.append(SmartSuggestion(
                title: "Setup Required",
                description: "Add your Groq API key to enable AI features",
                icon: "key",
                color: .orange,
                action: "Open Settings to configure API key"
            ))
        } else {
            // Helpful AI prompts when everything is working
            suggestions.append(contentsOf: [
                SmartSuggestion(
                    title: "Quick Edit",
                    description: "Fix grammar and improve clarity",
                    icon: "pencil.circle",
                    color: .blue,
                    action: "Fix grammar and improve the clarity of this text"
                ),
                SmartSuggestion(
                    title: "Summarize",
                    description: "Create a concise summary",
                    icon: "list.bullet.circle",
                    color: .green,
                    action: "Create a brief summary of the main points"
                ),
                SmartSuggestion(
                    title: "Expand Ideas",
                    description: "Add more detail and examples",
                    icon: "plus.circle",
                    color: .purple,
                    action: "Expand on these ideas with more detail and examples"
                ),
                SmartSuggestion(
                    title: "Organize",
                    description: "Structure content logically",
                    icon: "arrow.up.arrow.down.circle",
                    color: .indigo,
                    action: "Reorganize this content in a logical structure"
                )
            ])
        }
        
        return suggestions
    }
    
    var body: some View {
        Themed { theme in
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(suggestions) { suggestion in
                    SuggestionCard(suggestion: suggestion, theme: theme) {
                        onSuggestionTap(suggestion.action)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

struct SuggestionCard: View {
    let suggestion: SmartSuggestion
    let theme: Theme
    let onTap: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                // Icon with gradient background
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    suggestion.color.opacity(0.1),
                                    suggestion.color.opacity(0.05)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(suggestion.color)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.title)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text(suggestion.description)
                        .font(.system(size: 10))
                        .foregroundColor(theme.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Subtle arrow indicator
                Image(systemName: "arrow.right")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(theme.textSecondary.opacity(0.5))
                    .scaleEffect(isHovered ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundSecondary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                isHovered ? suggestion.color.opacity(0.3) : theme.border.opacity(0.1),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: isHovered ? suggestion.color.opacity(0.1) : .clear,
                        radius: isHovered ? 4 : 0,
                        x: 0,
                        y: 2
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct SmartSuggestion: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: String
}

struct SmartSuggestionsView_Previews: PreviewProvider {
    static var previews: some View {
        SmartSuggestionsView { suggestion in
            print("Tapped: \(suggestion)")
        }
        .background(Color.gray.opacity(0.1))
    }
}
