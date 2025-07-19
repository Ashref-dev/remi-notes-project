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
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Header(theme: theme)
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            // System Status Card
                            SettingsCard(theme: theme, title: "System Status", icon: "chart.line.uptrend.xyaxis") {
                                SystemStatusView()
                                    .frame(height: 200)
                            }
                            
                            // API Configuration Card
                            SettingsCard(theme: theme, title: "API Configuration", icon: "key.fill") {
                                VStack(alignment: .leading, spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Groq API Key")
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                            .foregroundColor(theme.textPrimary)
                                        
                                        HStack {
                                            SecureField("Enter your API key", text: $settings.groqAPIKey)
                                                .textFieldStyle(.plain)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .background(theme.backgroundSecondary)
                                                .cornerRadius(8)
                                                .onChange(of: settings.groqAPIKey) { _ in
                                                    validateAPIKey()
                                                }
                                            
                                            // Validation indicator
                                            if !settings.groqAPIKey.isEmpty {
                                                Image(systemName: apiKeyValidationState.icon)
                                                    .foregroundColor(apiKeyValidationState.color)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .frame(width: 24, height: 24)
                                            }
                                        }
                                        
                                        // Validation message
                                        if let message = apiKeyValidationState.message {
                                            HStack(spacing: 6) {
                                                Text(message)
                                                    .font(.caption)
                                                    .foregroundColor(apiKeyValidationState.color)
                                                
                                                if case .validating = apiKeyValidationState {
                                                    ProgressView()
                                                        .scaleEffect(0.7)
                                                }
                                            }
                                        }
                                        
                                        // Help text
                                        Text("Get your API key from [groq.com](https://console.groq.com/keys)")
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                }
                            }
                            
                            // General Settings Card
                            SettingsCard(theme: theme, title: "General", icon: "gearshape.fill") {
                                VStack(spacing: 20) {
                                    SettingsRow(theme: theme, title: "Launch at Login", subtitle: "Start Remi automatically when you log in") {
                                        Toggle("", isOn: $settings.launchAtLogin)
                                            .toggleStyle(SwitchToggleStyle())
                                    }
                                    
                                    Divider()
                                        .background(theme.textSecondary.opacity(0.2))
                                    
                                    SettingsRow(theme: theme, title: "Global Hotkey", subtitle: "Keyboard shortcut to show/hide Remi") {
                                        HotkeyRecorderView(key: $settings.hotkeyKey, modifiers: $settings.hotkeyModifiers)
                                    }
                                }
                            }
                            
                            // AI Personalization Card
                            SettingsCard(theme: theme, title: "AI Personalization", icon: "brain.head.profile") {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("About You")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(theme.textPrimary)
                                    
                                    Text("Provide context about yourself for more tailored AI responses.")
                                        .font(.caption)
                                        .foregroundColor(theme.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                    
                                    ZStack(alignment: .topLeading) {
                                        if settings.aboutMeContext.isEmpty {
                                            Text("e.g., I'm a software developer working on iOS apps, interested in SwiftUI and productivity tools...")
                                                .font(.body)
                                                .foregroundColor(theme.textSecondary.opacity(0.6))
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 10)
                                                .allowsHitTesting(false)
                                        }
                                        
                                        TextEditor(text: $settings.aboutMeContext)
                                            .font(.body)
                                            .lineLimit(nil)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(theme.backgroundSecondary)
                                            .cornerRadius(8)
                                            .frame(minHeight: 100, maxHeight: 150)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 20)
                    }
                    .background(theme.background)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(width: 650, height: 750)
        }
        .onAppear {
            validateAPIKey()
        }
        .onDisappear {
            validationTask?.cancel()
        }
    }
    
    // MARK: - Helper Views
    
    @ViewBuilder
    private func SettingsCard<Content: View>(theme: Theme, title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(theme.accent)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
            }
            
            content()
        }
        .padding(20)
        .background(theme.backgroundSecondary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    @ViewBuilder
    private func SettingsRow<Content: View>(theme: Theme, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(theme.textPrimary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            content()
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
            VStack(alignment: .leading, spacing: 4) {
                Text("Settings")
                    .font(.title.weight(.bold))
                    .foregroundColor(theme.textPrimary)
                
                Text("Customize your Remi experience")
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .padding(8)
                    .background(theme.background)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .buttonStyle(.plain)
            .help("Close Settings")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .background(theme.backgroundSecondary)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(theme.textSecondary.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
