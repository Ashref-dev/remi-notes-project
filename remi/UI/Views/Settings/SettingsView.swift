import SwiftUI
import LaunchAtLogin
import HotKey

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKeyValidationState: APIKeyValidationState = .unknown
    @State private var validationTask: Task<Void, Never>?
    
    enum APIKeyValidationState {
        case unknown
        case validating
        case valid
        case invalid(String)
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .validating: return .blue
            case .valid: return .green
            case .invalid: return .red
            }
        }
        
        var icon: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .validating: return "clock.circle"
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "exclamationmark.circle.fill"
            }
        }
        
        var message: String? {
            switch self {
            case .unknown: return nil
            case .validating: return "Validating..."
            case .valid: return "API key is valid"
            case .invalid(let message): return message
            }
        }
    }

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                Header(theme: theme)
                
                Divider()
                
                Form {
                    Section(header: Text("System Status").font(.headline)) {
                        SystemStatusView()
                            .frame(height: 200)
                    }
                    
                    Section(header: Text("API Configuration").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                SecureField("Groq API Key", text: $settings.groqAPIKey)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: settings.groqAPIKey) { _ in
                                        validateAPIKey()
                                    }
                                
                                // Validation indicator
                                if !settings.groqAPIKey.isEmpty {
                                    Image(systemName: apiKeyValidationState.icon)
                                        .foregroundColor(apiKeyValidationState.color)
                                        .font(.system(size: 16))
                                }
                            }
                            
                            // Validation message
                            if let message = apiKeyValidationState.message {
                                HStack {
                                    Text(message)
                                        .font(.caption)
                                        .foregroundColor(apiKeyValidationState.color)
                                    
                                    if case .validating = apiKeyValidationState {
                                        ProgressView()
                                            .scaleEffect(0.6)
                                    }
                                }
                            }
                            
                            // Help text
                            Text("Get your API key from [groq.com](https://console.groq.com/keys)")
                                .font(.caption)
                                .foregroundColor(theme.textSecondary)
                        }
                    }
                    
                    Section(header: Text("General").font(.headline)) {
                        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                        
                        HStack {
                            Text("Global Hotkey")
                            Spacer()
                            HotkeyRecorderView(key: $settings.hotkeyKey, modifiers: $settings.hotkeyModifiers)
                        }
                    }
                    
                    Section(header: Text("AI Personalization").font(.headline)) {
                        Text("Provide context about yourself for more tailored AI responses.")
                            .font(.caption)
                            .foregroundColor(theme.textSecondary)
                        
                        TextEditor(text: $settings.aboutMeContext)
                            .frame(height: 120)
                            .font(.body)
                            .lineLimit(nil)
                            .padding(AppTheme.Spacing.small)
                            .background(theme.backgroundSecondary)
                            .cornerRadius(AppTheme.CornerRadius.small)
                    }
                }
                .padding(AppTheme.Spacing.large)
                .formStyle(.grouped)
                .background(theme.background)
            }
            .frame(width: 550, height: 550)
        }
        .onAppear {
            validateAPIKey()
        }
        .onDisappear {
            validationTask?.cancel()
        }
    }
    
    private func validateAPIKey() {
        validationTask?.cancel()
        
        let apiKey = settings.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !apiKey.isEmpty else {
            apiKeyValidationState = .unknown
            return
        }
        
        // Basic format validation
        guard apiKey.starts(with: "gsk_") && apiKey.count > 20 else {
            apiKeyValidationState = .invalid("Invalid API key format")
            return
        }
        
        // Set validating state
        apiKeyValidationState = .validating
        
        // Test the API key with a minimal request
        validationTask = Task {
            do {
                try await testAPIKey(apiKey)
                await MainActor.run {
                    if !Task.isCancelled {
                        apiKeyValidationState = .valid
                    }
                }
            } catch {
                await MainActor.run {
                    if !Task.isCancelled {
                        if let groqError = error as? GroqError {
                            switch groqError {
                            case .requestFailed(let statusCode, _):
                                if statusCode == 401 {
                                    apiKeyValidationState = .invalid("Invalid API key")
                                } else {
                                    apiKeyValidationState = .invalid("API key validation failed")
                                }
                            default:
                                apiKeyValidationState = .invalid("Unable to validate (network error)")
                            }
                        } else {
                            apiKeyValidationState = .invalid("Unable to validate")
                        }
                    }
                }
            }
        }
    }
    
    private func testAPIKey(_ apiKey: String) async throws {
        // Use the GroqService test method for consistency
        try await GroqService.shared.testAPIKey()
    }
    
    @ViewBuilder
    private func Header(theme: Theme) -> some View {
        HStack {
            Text("Settings")
                .font(.title2.weight(.bold))
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(theme.textSecondary)
                    .padding(AppTheme.Spacing.small)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(AppTheme.Spacing.large)
        .background(theme.backgroundSecondary)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
