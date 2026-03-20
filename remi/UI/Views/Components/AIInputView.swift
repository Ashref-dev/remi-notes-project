import SwiftUI

struct AIInputView: View {
    @Binding var isVisible: Bool
    @Binding var shouldFocus: Bool
    var onSend: (String) -> Void
    
    @State private var inputText: String = ""
    @State private var isProcessing: Bool = false
    @FocusState private var isFocused: Bool
    @ObservedObject private var settingsManager = SettingsManager.shared
    @Namespace private var glassNamespace
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var isAPIKeyConfigured: Bool {
        settingsManager.isAPIKeyConfigured()
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
                        withOptionalAnimation(.easeInOut(duration: 0.2)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(theme.textSecondary.opacity(0.6))
                            .background(Color.clear)
                    }
                    .liquidGlassButtonStyle()
                    .liquidGlassUnion("editor.aiInput.controls", in: glassNamespace)
                    .help("Close AI Assistant")
                }
                
                VStack(spacing: 8) {
                // API Key warning (if needed) - minimal
                if !isAPIKeyConfigured {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.system(size: 10))
                        
                        Text("Configure OpenRouter key in Settings")
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
                    .accessibilityLabel("Send AI request")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    Color.clear
                        .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.05, interactive: true, fallbackMaterial: .thinMaterial)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? theme.accent.opacity(0.5) : theme.border, lineWidth: 1)
                )

                    // Quick action chips
                    if isAPIKeyConfigured && inputText.isEmpty && !SettingsManager.shared.aiQuickActions.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(SettingsManager.shared.aiQuickActions, id: \.self) { action in
                                Button {
                                    inputText = action
                                    isFocused = true
                                } label: {
                                    Text(action)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(theme.textSecondary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background {
                                            Capsule()
                                                .fill(theme.textSecondary.opacity(0.08))
                                        }
                                        .overlay {
                                            Capsule()
                                                .stroke(theme.textSecondary.opacity(0.12), lineWidth: 0.5)
                                        }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            } // inner VStack
            } // outer VStack
            .padding(16)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.08, interactive: true, fallbackMaterial: .regularMaterial)
                    .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 8)
            }
            .onAppear { 
                requestFocusIfNeeded()
            }
            .onChange(of: shouldFocus) { _, newValue in
                if newValue {
                    shouldFocus = false
                    requestFocusIfNeeded()
                }
            }
            .onChange(of: isVisible) { _, newValue in
                if newValue {
                    requestFocusIfNeeded()
                } else {
                    inputText = ""
                    isProcessing = false
                    isFocused = false
                }
            }
            .transition(reduceMotion ? .opacity : .scale(scale: 0.95).combined(with: .opacity))
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
            withOptionalAnimation(.easeOut(duration: 0.3)) {
                isProcessing = false
                isVisible = false
            }
        }
    }

    private func requestFocusIfNeeded() {
        guard isVisible, isAPIKeyConfigured, !isProcessing else { return }
        isFocused = true

        // Re-assert once after layout without a polling timer.
        DispatchQueue.main.async {
            if isVisible && isAPIKeyConfigured && !isProcessing {
                isFocused = true
            }
        }
    }

    private func withOptionalAnimation(
        _ animation: Animation,
        _ updates: @escaping () -> Void
    ) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }
}
