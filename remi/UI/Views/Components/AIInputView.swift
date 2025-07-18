import SwiftUI

struct AIInputView: View {
    @Binding var isVisible: Bool
    var onSend: (String) -> Void
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Compact AI Input Container - sized to content
                VStack(spacing: 8) {
                    // API Key Status Indicator (if needed) - more compact
                    if !isAPIKeyConfigured {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 10))
                            
                            Text("Configure API key in Settings")
                                .font(.system(size: 10))
                                .foregroundColor(theme.textSecondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.orange.opacity(0.1))
                                .stroke(Color.orange.opacity(0.3), lineWidth: 0.5)
                        )
                    }
                    
                    // Compact Input Field - perfectly sized
                    HStack(spacing: 8) {
                        TextField(
                            isAPIKeyConfigured ? "Ask AI to edit or generate..." : "Configure API key first...",
                            text: $inputText
                        )
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .focused($isFocused)
                        .onSubmit { send() }
                        .disabled(!isAPIKeyConfigured)
                        
                        Button(action: { send() }) {
                            if isProcessing {
                                // Subtle loading animation
                                Image(systemName: "arrow.circlepath")
                                    .font(.system(size: 16))
                                    .foregroundColor(theme.accent)
                                    .rotationEffect(.degrees(isProcessing ? 360 : 0))
                                    .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: isProcessing)
                            } else {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(isAPIKeyConfigured && !inputText.isEmpty ? theme.accent : theme.accent.opacity(0.3))
                            }
                        }
                        .buttonStyle(.plain)
                        .disabled(!isAPIKeyConfigured || inputText.isEmpty || isProcessing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(theme.backgroundSecondary)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isFocused ? theme.accent.opacity(0.5) : theme.border, lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
                }
                .padding(12) // Tight padding around the input
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(theme.background)
                        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 6)
                )
            }
            .onAppear { 
                if isAPIKeyConfigured {
                    isFocused = true 
                }
            }
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
    
    private func send() {
        if !inputText.isEmpty && isAPIKeyConfigured && !isProcessing {
            isProcessing = true
            onSend(inputText)
            inputText = ""
            
            // Reset processing state after a delay (will be managed by the parent view in practice)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    isProcessing = false
                    isVisible = false
                }
            }
        }
    }
}

// Notification for opening settings
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

