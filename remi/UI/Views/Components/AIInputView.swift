import SwiftUI

struct AIInputView: View {
    @Binding var isVisible: Bool
    @Binding var shouldFocus: Bool // New focus trigger from parent
    var onSend: (String) -> Void
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool
    @State private var focusProtectionTimer: Timer? // Protect focus from being stolen
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 12) {
                // Header with close button for center modal
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AI Assistant")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Describe how you'd like to improve your content")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                            .background(Color.clear)
                    }
                    .buttonStyle(.plain)
                    .help("Close AI Assistant")
                }
                
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
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(theme.background)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 8)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.border.opacity(0.1), lineWidth: 1)
            )
            .onAppear { 
                // Focus immediately on appear if API key is configured
                if isAPIKeyConfigured {
                    isFocused = true
                    startFocusProtection()
                }
            }
            .onChange(of: shouldFocus) { _, newValue in
                if newValue && isAPIKeyConfigured {
                    // Parent triggered focus - apply immediately and reset trigger
                    isFocused = true
                    shouldFocus = false
                    startFocusProtection()
                }
            }
            .onChange(of: isVisible) { _, newValue in
                if newValue {
                    // When becoming visible, ensure focus
                    if isAPIKeyConfigured {
                        isFocused = true
                        startFocusProtection()
                    }
                } else {
                    // When hiding, clean up state
                    inputText = ""
                    isProcessing = false
                    isFocused = false
                    stopFocusProtection()
                }
            }
            .onDisappear {
                stopFocusProtection()
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
        stopFocusProtection() // Stop protection while processing
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
    
    // Focus protection methods to prevent focus stealing from rerenders
    private func startFocusProtection() {
        stopFocusProtection() // Clear any existing timer
        focusProtectionTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if isVisible && isAPIKeyConfigured && !isProcessing && !isFocused {
                isFocused = true
            }
        }
    }
    
    private func stopFocusProtection() {
        focusProtectionTimer?.invalidate()
        focusProtectionTimer = nil
    }
}

// Notification for opening settings
extension Notification.Name {
    static let openSettings = Notification.Name("openSettings")
}

