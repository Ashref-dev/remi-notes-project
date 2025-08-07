import SwiftUI
import LaunchAtLogin
import HotKey

struct IntegratedSettingsView: View {
    @Binding var showingSettings: Bool
    @StateObject private var settings = SettingsManager.shared
    @State private var apiKeyValidationState: APIKeyValidationState = .unknown
    @State private var validationTask: Task<Void, Never>?
    @State private var showingModelDetails = false
    
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
                // Header
                HStack {
                    Button(action: { 
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showingSettings = false
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 16, weight: .medium))
                            Text("Back")
                                .font(.body)
                        }
                        .foregroundColor(theme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    VStack(alignment: .center, spacing: 4) {
                        Text("Settings")
                            .font(.title.weight(.bold))
                            .foregroundColor(theme.textPrimary)
                        
                        Text("Customize your Remi experience")
                            .font(.subheadline)
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Invisible placeholder for balance
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 16, weight: .medium))
                        Text("Back")
                            .font(.body)
                    }
                    .foregroundColor(.clear)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 24)
                
                // Main Content
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 32) {
                        // System Status Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "System Status", icon: "chart.line.uptrend.xyaxis", theme: theme) {
                                Button(action: {
                                    Task {
                                        await HealthCheckService.shared.performHealthCheck()
                                    }
                                }) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(theme.accent)
                                }
                                .buttonStyle(.plain)
                                .help("Refresh Status")
                            }
                            
                            ModernCard(theme: theme) {
                                SystemStatusView()
                            }
                        }
                        
                        // API Configuration Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "API Configuration", icon: "key.fill", theme: theme)
                            
                            ModernCard(theme: theme) {
                                VStack(alignment: .leading, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("Groq API Key")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(theme.textPrimary)
                                        
                                        Text("Configure your Groq API key for AI features")
                                            .font(.subheadline)
                                            .foregroundColor(theme.textSecondary)
                                        
                                        HStack(spacing: 12) {
                                            SecureField("Enter your API key", text: $settings.groqAPIKey)
                                                .textFieldStyle(.plain)
                                                .font(.system(.body, design: .monospaced))
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 14)
                                                .background(theme.background)
                                                .cornerRadius(12)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                                                )
                                                .onChange(of: settings.groqAPIKey) { _ in
                                                    validateAPIKey()
                                                }
                                            
                                            // Validation indicator
                                            if !settings.groqAPIKey.isEmpty {
                                                Image(systemName: apiKeyValidationState.icon)
                                                    .foregroundColor(apiKeyValidationState.color)
                                                    .font(.system(size: 20, weight: .medium))
                                                    .frame(width: 32, height: 32)
                                            }
                                        }
                                        
                                        // Validation message
                                        if let message = apiKeyValidationState.message {
                                            HStack(spacing: 8) {
                                                Text(message)
                                                    .font(.subheadline)
                                                    .foregroundColor(apiKeyValidationState.color)
                                                
                                                if case .validating = apiKeyValidationState {
                                                    ProgressView()
                                                        .scaleEffect(0.8)
                                                }
                                            }
                                            .padding(.top, 4)
                                        }
                                        
                                        // Help text
                                        Text("Get your API key from [groq.com](https://console.groq.com/keys)")
                                            .font(.caption)
                                            .foregroundColor(theme.textSecondary)
                                            .padding(.top, 8)
                                    }
                                }
                            }
                        }
                        
                        // AI Personalization Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "AI Personalization", icon: "brain.head.profile", theme: theme)
                            
                            ModernCard(theme: theme) {
                                VStack(alignment: .leading, spacing: 20) {
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("About You")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(theme.textPrimary)
                                        
                                        Text("Provide context about yourself for more tailored AI responses.")
                                            .font(.subheadline)
                                            .foregroundColor(theme.textSecondary)
                                    }
                                    
                                    ZStack(alignment: .topLeading) {
                                        if settings.aboutMeContext.isEmpty {
                                            VStack(alignment: .leading) {
                                                Text("e.g., I'm a software developer working on iOS apps, interested in SwiftUI and productivity tools...")
                                                    .font(.body)
                                                    .foregroundColor(theme.textSecondary.opacity(0.6))
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 14)
                                                Spacer()
                                            }
                                            .allowsHitTesting(false)
                                        }
                                        
                                        TextEditor(text: $settings.aboutMeContext)
                                            .font(.body)
                                            .scrollContentBackground(.hidden)
                                            .background(Color.clear)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 10)
                                    }
                                    .frame(minHeight: 120)
                                    .background(theme.background)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(theme.textSecondary.opacity(0.2), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        
                        // Model Selection Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "AI Model Configuration", icon: "cpu.fill", theme: theme)
                            
                            ModernCard(theme: theme) {
                                ModelSelectionView()
                            }
                        }
                        
                        // General Settings Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "General", icon: "gearshape.fill", theme: theme)
                            
                            ModernCard(theme: theme) {
                                VStack(spacing: 0) {
                                    ModernSettingsRow(
                                        title: "Launch at Login",
                                        subtitle: "Start Remi automatically when you log in",
                                        theme: theme
                                    ) {
                                        Toggle("", isOn: $settings.launchAtLogin)
                                            .toggleStyle(.switch)
                                    }
                                    
                                    Divider()
                                        .background(theme.textSecondary.opacity(0.1))
                                        .padding(.horizontal, 20)
                                    
                                    ModernSettingsRow(
                                        title: "Global Hotkey",
                                        subtitle: "Keyboard shortcut to show/hide Remi",
                                        theme: theme
                                    ) {
                                        HotkeyRecorderView(key: $settings.hotkeyKey, modifiers: $settings.hotkeyModifiers)
                                    }
                                    
                                    Divider()
                                        .background(theme.textSecondary.opacity(0.1))
                                        .padding(.horizontal, 20)
                                    
                                    ModernSettingsRow(
                                        title: "Nook Hotkeys",
                                        subtitle: "Quick access to nooks using number keys",
                                        theme: theme
                                    ) {
                                        Toggle("", isOn: $settings.enableNookHotkeys)
                                            .toggleStyle(.switch)
                                    }
                                    
                                    if settings.enableNookHotkeys {
                                        Divider()
                                            .background(theme.textSecondary.opacity(0.1))
                                            .padding(.horizontal, 20)
                                        
                                        ModernSettingsRow(
                                            title: "Nook Hotkey Modifiers",
                                            subtitle: "Modifiers + 1-9 to select nooks",
                                            theme: theme
                                        ) {
                                            HotkeyRecorderView(key: .constant(.one), modifiers: $settings.nookHotkeyModifiers)
                                                .help("Example: ⌘⇧1 to select first nook")
                                        }
                                    }
                                }
                            }
                        }
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 20) {
                            SectionHeader(title: "About Remi", icon: "heart.fill", theme: theme)
                            
                            ModernCard(theme: theme) {
                                VStack(alignment: .leading, spacing: 24) {
                                    // App Information
                                    VStack(alignment: .leading, spacing: 16) {
                                        Text("App Information")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(theme.textPrimary)
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Text("Version")
                                                    .font(.body)
                                                    .foregroundColor(theme.textSecondary)
                                                Spacer()
                                                Text("1.0.1")
                                                    .font(.body)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(theme.textPrimary)
                                            }
                                            
                                            Text("A simple, elegant note-taking app designed for organizing your thoughts and ideas with the power of AI.")
                                                .font(.body)
                                                .foregroundColor(theme.textSecondary)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                    }
                                    
                                    Divider()
                                        .background(theme.textSecondary.opacity(0.1))
                                    
                                    // Developer Credit
                                    VStack(alignment: .leading, spacing: 16) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack(spacing: 16) {
                                                Image(systemName: "heart.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.red)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text("Created by ashref.tn")
                                                        .font(.body)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(theme.textPrimary)
                                                    
                                                    Text("With love from Tunisia 🇹🇳")
                                                        .font(.subheadline)
                                                        .foregroundColor(theme.textSecondary)
                                                }
                                            }
                                            
                                            // Website Link
                                            Button(action: {
                                                if let url = URL(string: "https://ashref.tn") {
                                                    NSWorkspace.shared.open(url)
                                                }
                                            }) {
                                                HStack(spacing: 10) {
                                                    Image(systemName: "globe")
                                                        .font(.system(size: 16))
                                                    Text("Visit ashref.tn")
                                                        .font(.body)
                                                        .underline()
                                                }
                                                .foregroundColor(theme.accent)
                                                .padding(.top, 8)
                                            }
                                            .buttonStyle(.plain)
                                            .help("Open developer website")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.vertical, 32)
                    .padding(.bottom, 40) // Extra bottom padding to ensure all content is scrollable
                }
                .background(theme.background)
            }
            .frame(width: 800, height: 720)
            .background(theme.background)
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
    
    // MARK: - Modern Helper Views
    
    @ViewBuilder
    private func SectionHeader(title: String, icon: String, theme: Theme, @ViewBuilder action: () -> some View = { EmptyView() }) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(theme.accent)
                .frame(width: 28, height: 28)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(theme.textPrimary)
            
            Spacer()
            
            action()
        }
    }
    
    @ViewBuilder
    private func ModernCard<Content: View>(theme: Theme, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(24)
            .background(theme.backgroundSecondary)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.02), radius: 16, x: 0, y: 4)
    }
    
    @ViewBuilder
    private func ModernSettingsRow<Content: View>(title: String, subtitle: String, theme: Theme, @ViewBuilder content: () -> Content) -> some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(theme.textPrimary)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            content()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}
