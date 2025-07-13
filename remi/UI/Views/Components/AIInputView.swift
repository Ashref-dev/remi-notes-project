import SwiftUI

struct AIInputView: View {
    @Binding var isVisible: Bool
    var onSend: (String) -> Void
    
    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    var body: some View {
        Themed { theme in
            VStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // API Key Status Indicator
                    if !isAPIKeyConfigured {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 14))
                            
                            Text("Set your Groq API key in Settings to use AI features")
                                .font(.caption)
                                .foregroundColor(theme.secondaryText)
                            
                            Spacer()
                            
                            Button("Settings") {
                                // Open settings - you'll need to implement this based on your navigation
                                NotificationCenter.default.post(name: .openSettings, object: nil)
                            }
                            .font(.caption)
                            .foregroundColor(theme.accent)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.orange.opacity(0.1))
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                    }
                    
                    // Input Field
                    HStack {
                        TextField(
                            isAPIKeyConfigured ? "Ask AI to edit or generate..." : "Configure API key first...",
                            text: $inputText
                        )
                        .textFieldStyle(.plain)
                        .focused($isFocused)
                        .onSubmit { send() }
                        .disabled(!isAPIKeyConfigured)
                        
                        Button(action: { send() }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundColor(isAPIKeyConfigured && !inputText.isEmpty ? theme.accent : theme.accent.opacity(0.3))
                        }
                        .buttonStyle(.plain)
                        .disabled(!isAPIKeyConfigured || inputText.isEmpty)
                    }
                    .padding()
                    .background(theme.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                            .stroke(isAPIKeyConfigured ? Color.clear : Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                .shadow(radius: 10)
                .padding()
            }
            .onAppear { 
                if isAPIKeyConfigured {
                    isFocused = true 
                }
            }
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    private func send() {
        if !inputText.isEmpty && isAPIKeyConfigured {
            onSend(inputText)
            inputText = ""
            withAnimation { isVisible = false }
        }
    }
}

// Notification for opening settings
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

