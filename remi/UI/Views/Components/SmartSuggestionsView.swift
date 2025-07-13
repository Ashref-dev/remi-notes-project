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
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(suggestions) { suggestion in
                        SuggestionCard(suggestion: suggestion, theme: theme) {
                            onSuggestionTap(suggestion.action)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }
}

struct SuggestionCard: View {
    let suggestion: SmartSuggestion
    let theme: Theme
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: suggestion.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(suggestion.color)
                    
                    Spacer()
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.primaryText)
                        .lineLimit(1)
                    
                    Text(suggestion.description)
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
            }
            .padding(12)
            .frame(width: 140, height: 80)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.backgroundSecondary)
                    .stroke(suggestion.color.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: suggestion.id)
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
