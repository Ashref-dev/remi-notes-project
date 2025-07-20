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
            VStack(spacing: 8) {
                // API Key warning (if needed) - minimal
                if !isAPIKeyConfigured {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                        
                        Text("Configure API key in Settings")
                            .font(.system(size: 10))
                            .foregroundColor(theme.textSecondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                            .stroke(Color.orange.opacity(0.3), lineWidth: 0.5)
                    )
                }
                
                // Compact input field with proper text handling
                HStack(spacing: 8) {
                    TextField(
                        isAPIKeyConfigured ? "Ask AI to improve..." : "Configure API key first",
                        text: $inputText,
                        axis: .vertical
                    )
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isFocused)
                    .lineLimit(1...3) // Allow up to 3 lines, then scroll
                    .onSubmit { send() }
                    .disabled(!isAPIKeyConfigured)
                    
                    Button(action: send) {
                        if isProcessing {
                            ProgressView()
                                .scaleEffect(0.6)
                                .tint(theme.accent)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(canSend ? theme.accent : theme.accent.opacity(0.3))
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSend || isProcessing)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(theme.backgroundSecondary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? theme.accent.opacity(0.5) : theme.border, lineWidth: 1)
                )
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.background)
                    .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
            )
            .onAppear { 
                if isAPIKeyConfigured {
                    isFocused = true 
                }
            }
            .onChange(of: isVisible) { _, newValue in
                if !newValue {
                    inputText = ""
                    isProcessing = false
                }
            }
            .transition(.scale(scale: 0.95).combined(with: .opacity))
        }
    }
    
    private var canSend: Bool {
        isAPIKeyConfigured && !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func send() {
        guard canSend, !isProcessing else { return }
        
        let prompt = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        isProcessing = true
        onSend(prompt)
        inputText = ""
        
        // Hide after sending
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.3)) {
                isProcessing = false
                isVisible = false
            }
        }
    }
}

// Notification for opening settings
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

