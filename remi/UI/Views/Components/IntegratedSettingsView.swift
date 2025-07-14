import SwiftUI
import LaunchAtLogin
import HotKey

struct IntegratedSettingsView: View {
    @Binding var showingSettings: Bool
    @StateObject private var settings = SettingsManager.shared
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
            HStack(spacing: 0) {
                // Settings Sidebar
                settingsSidebar(theme: theme)
                    .frame(width: 280)
                    .background(theme.backgroundSecondary)
                
                Divider()
                
                // Settings Content
                settingsContent(theme: theme)
                    .background(theme.background)
            }
        }
        .transition(.asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .trailing).combined(with: .opacity)
        ))
        .onAppear {
            validateAPIKey()
        }
        .onDisappear {
            validationTask?.cancel()
        }
    }
    
    private func settingsSidebar(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Button(action: { 
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showingSettings = false
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(theme.accent)
                }
                .buttonStyle(.plain)
                
                Text("Settings")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
            }
            .padding(AppTheme.Spacing.large)
            
            Divider()
            
            // Settings Categories
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                SettingsCategory(
                    icon: "person.circle.fill",
                    title: "About Me",
                    isSelected: true,
                    theme: theme
                )
                
                SettingsCategory(
                    icon: "key.fill",
                    title: "API Configuration",
                    isSelected: false,
                    theme: theme
                )
                
                SettingsCategory(
                    icon: "gearshape.fill",
                    title: "General",
                    isSelected: false,
                    theme: theme
                )
                
                SettingsCategory(
                    icon: "antenna.radiowaves.left.and.right",
                    title: "System Status",
                    isSelected: false,
                    theme: theme
                )
            }
            .padding(AppTheme.Spacing.large)
            
            Spacer()
        }
    }
    
    private func settingsContent(theme: Theme) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
                // About Me Section
                settingsSection(
                    title: "About Me",
                    subtitle: "Provide context about yourself for more tailored AI responses",
                    theme: theme
                ) {
                    TextEditor(text: $settings.aboutMeContext)
                        .font(.system(size: 14))
                        .frame(minHeight: 120)
                        .padding(AppTheme.Spacing.medium)
                        .background(theme.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                .stroke(theme.border, lineWidth: 1)
                        )
                }
                
                // API Configuration Section
                settingsSection(
                    title: "API Configuration",
                    subtitle: "Configure your Groq API key for AI features",
                    theme: theme
                ) {
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                        HStack {
                            SecureField("Enter your Groq API key", text: $settings.groqAPIKey)
                                .textFieldStyle(.plain)
                                .font(.system(size: 14))
                                .padding(AppTheme.Spacing.medium)
                                .background(theme.backgroundSecondary)
                                .cornerRadius(AppTheme.CornerRadius.medium)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                                        .stroke(theme.border, lineWidth: 1)
                                )
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
                                    .font(.system(size: 12))
                                    .foregroundColor(apiKeyValidationState.color)
                                
                                if case .validating = apiKeyValidationState {
                                    ProgressView()
                                        .scaleEffect(0.6)
                                }
                            }
                        }
                        
                        // Help text
                        Text("Get your API key from [groq.com](https://console.groq.com/keys)")
                            .font(.system(size: 12))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                // General Settings Section
                settingsSection(
                    title: "General",
                    subtitle: "App behavior and shortcuts",
                    theme: theme
                ) {
                    VStack(spacing: AppTheme.Spacing.medium) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Launch at Login")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textPrimary)
                                Text("Automatically start Remi when you log in")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $settings.launchAtLogin)
                                .toggleStyle(SwitchToggleStyle())
                        }
                        
                        Divider()
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Global Hotkey")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(theme.textPrimary)
                                Text("Keyboard shortcut to show/hide Remi")
                                    .font(.system(size: 12))
                                    .foregroundColor(theme.textSecondary)
                            }
                            
                            Spacer()
                            
                            HotkeyRecorderView(key: $settings.hotkeyKey, modifiers: $settings.hotkeyModifiers)
                        }
                    }
                    .padding(AppTheme.Spacing.medium)
                    .background(theme.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                }
                
                // System Status Section
                settingsSection(
                    title: "System Status",
                    subtitle: "Connection and service information",
                    theme: theme
                ) {
                    SystemStatusView()
                        .frame(height: 200)
                        .background(theme.backgroundSecondary)
                        .cornerRadius(AppTheme.CornerRadius.medium)
                }
            }
            .padding(AppTheme.Spacing.large)
        }
    }
    
    private func settingsSection<Content: View>(
        title: String,
        subtitle: String,
        theme: Theme,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
            }
            
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
        try await GroqService.shared.testAPIKey()
    }
}

struct SettingsCategory: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let theme: Theme
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .semibold : .medium))
                .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(isSelected ? theme.accent.opacity(0.1) : Color.clear)
        .cornerRadius(AppTheme.CornerRadius.medium)
    }
}
