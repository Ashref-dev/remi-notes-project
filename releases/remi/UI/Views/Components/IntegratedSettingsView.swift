import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct IntegratedSettingsView: View {
    @Binding var showingSettings: Bool
    @StateObject private var settings = SettingsManager.shared
    @State private var validationState: ValidationState = .idle
    @State private var transferFeedback: TransferFeedback?
    @State private var isProcessingTransfer = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    enum ValidationState {
        case idle
        case validating
        case valid
        case invalid(String)

        var icon: String {
            switch self {
            case .idle: return "questionmark.circle"
            case .validating: return "clock.arrow.circlepath"
            case .valid: return "checkmark.circle.fill"
            case .invalid: return "xmark.circle.fill"
            }
        }

        var tint: Color {
            switch self {
            case .idle: return .secondary
            case .validating: return .blue
            case .valid: return .green
            case .invalid: return .red
            }
        }

        var message: String {
            switch self {
            case .idle: return "Not validated"
            case .validating: return "Validating..."
            case .valid: return "API key is valid"
            case .invalid(let text): return text
            }
        }

        var isValidating: Bool {
            if case .validating = self { return true }
            return false
        }
    }

    struct TransferFeedback {
        let icon: String
        let message: String
        let tint: Color
    }

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                topBar(theme: theme)

                ScrollView {
                    VStack(spacing: 14) {
                        aiProviderSection(theme: theme)
                        systemPromptSection(theme: theme)
                        aiTemplatesSection(theme: theme)
                        intelligenceSection(theme: theme)
                        modelSection(theme: theme)
                        captureSection(theme: theme)
                        historySection(theme: theme)
                        libraryTransferSection(theme: theme)
                        appBehaviorSection(theme: theme)
                        aboutSection(theme: theme)
                    }
                    .padding(16)
                }
                .background(theme.background)
            }
            .frame(width: 760, height: 620)
            .background(theme.background)
        }
    }

    @ViewBuilder
    private func topBar(theme: Theme) -> some View {
        HStack {
            Button {
                withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                    showingSettings = false
                }
            } label: {
                Label("Back", systemImage: "chevron.left")
                    .font(.system(size: 13, weight: .medium))
            }
            .liquidGlassButtonStyle()
            .foregroundStyle(theme.accent)

            Spacer()

            Text("Settings")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(theme.textPrimary)

            Spacer()

            Color.clear.frame(width: 56, height: 1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.06, interactive: true, fallbackMaterial: .thinMaterial)
        }
    }

    @ViewBuilder
    private func aiProviderSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "AI Provider", subtitle: "OpenRouter") {
            VStack(alignment: .leading, spacing: 10) {
                Text("API Key")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                HStack(spacing: 10) {
                    SecureField("Enter OpenRouter API key", text: $settings.llmAPIKey)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, design: .monospaced))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(theme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 10))

                    Button {
                        Task { await validateKey() }
                    } label: {
                        if validationState.isValidating {
                            ProgressView()
                                .controlSize(.small)
                                .frame(width: 70)
                        } else {
                            Text("Validate")
                                .font(.system(size: 12, weight: .semibold))
                                .frame(width: 70)
                        }
                    }
                    .liquidGlassButtonStyle()
                    .disabled(validationState.isValidating || !isAPIKeyEntered)
                    .accessibilityLabel("Validate API key")
                }

                HStack(spacing: 6) {
                    Image(systemName: validationState.icon)
                        .foregroundStyle(validationState.tint)
                    Text(validationState.message)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                }

                Text("Get your API key from [openrouter.ai](https://openrouter.ai/keys)")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func modelSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "Model", subtitle: "Search and select from OpenRouter catalog") {
            VStack(spacing: 12) {
                ModelSelectionView()
                modelParameterControls(theme: theme)
            }
        }
    }

    @ViewBuilder
    private func modelParameterControls(theme: Theme) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Temperature")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text(String(format: "%.2f", settings.modelParameters.temperature))
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            Slider(
                value: $settings.modelParameters.temperature,
                in: 0...1,
                step: 0.05
            )

            HStack {
                Text("Max Tokens")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
                Spacer()
                Text("\(settings.modelParameters.maxTokens)")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
            }
            Slider(
                value: Binding(
                    get: { Double(settings.modelParameters.maxTokens) },
                    set: { settings.modelParameters.maxTokens = Int($0) }
                ),
                in: 500...8000,
                step: 100
            )
        }
        .padding(10)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.05, fallbackMaterial: .thinMaterial)
        }
    }

    @ViewBuilder
    private func appBehaviorSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "App Behavior", subtitle: "Startup and keyboard controls") {
            VStack(spacing: 0) {
                settingRow(
                    theme: theme,
                    title: "Launch at Login",
                    subtitle: "Start Remi automatically when you log in"
                ) {
                    Toggle("", isOn: $settings.launchAtLogin)
                        .labelsHidden()
                }

                Divider().opacity(0.2)

                settingRow(
                    theme: theme,
                    title: "Global Hotkey",
                    subtitle: "Show or hide Remi quickly"
                ) {
                    HotkeyRecorderView(key: $settings.hotkeyKey, modifiers: $settings.hotkeyModifiers)
                }

                Divider().opacity(0.2)

                settingRow(
                    theme: theme,
                    title: "Nook Hotkeys",
                    subtitle: "Use number shortcuts for notes"
                ) {
                    Toggle("", isOn: $settings.enableNookHotkeys)
                        .labelsHidden()
                }

                if settings.enableNookHotkeys {
                    Divider().opacity(0.2)
                    settingRow(
                        theme: theme,
                        title: "Nook Modifiers",
                        subtitle: "Modifiers combined with number keys"
                        ) {
                            HotkeyRecorderView(key: .constant(.one), modifiers: $settings.nookHotkeyModifiers)
                        }
                }

                Divider().opacity(0.2)

                settingRow(
                    theme: theme,
                    title: "Quick Capture Hotkey",
                    subtitle: "Use Option-Command-N to open the capture panel globally"
                ) {
                    Toggle("", isOn: $settings.enableQuickCaptureHotkey)
                        .labelsHidden()
                }

                Divider().opacity(0.2)

                settingRow(
                    theme: theme,
                    title: "Today Hotkey",
                    subtitle: "Use Option-Command-T to open the Today overlay"
                ) {
                    Toggle("", isOn: $settings.enableTodayHotkey)
                        .labelsHidden()
                }
            }
        }
    }

    @ViewBuilder
    private func intelligenceSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "Ambient Intelligence", subtitle: "Keep AI subtle and editor-first") {
            settingRow(
                theme: theme,
                title: "Ambient Suggestions",
                subtitle: "Show one compact suggestion chip when a note looks like it could benefit from AI help"
            ) {
                Toggle("", isOn: $settings.ambientSuggestionsEnabled)
                    .labelsHidden()
            }
        }
    }

    @ViewBuilder
    private func captureSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "Capture", subtitle: "Control how quick capture routes text into Remi") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Default Capture Route")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                Picker("Default Capture Route", selection: $settings.captureDefaultRoute) {
                    ForEach(CaptureRoute.allCases) { route in
                        Text(route.title).tag(route)
                    }
                }
                .pickerStyle(.segmented)

                Text(settings.captureDefaultRoute.subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func historySection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "History", subtitle: "Automatic local revisions for recovery") {
            VStack(spacing: 10) {
                HStack {
                    Text("Retention")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Stepper("\(settings.historyRetentionDays) days", value: $settings.historyRetentionDays, in: 1...365)
                        .labelsHidden()
                    Text("\(settings.historyRetentionDays) days")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                }

                HStack {
                    Text("Max Revisions")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Stepper("\(settings.historyMaxRevisions)", value: $settings.historyMaxRevisions, in: 5...500, step: 5)
                        .labelsHidden()
                    Text("\(settings.historyMaxRevisions)")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundStyle(theme.textSecondary)
                }
            }
        }
    }

    @ViewBuilder
    private func libraryTransferSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "Library Transfer", subtitle: "Move notes and supported preferences between Macs") {
            VStack(alignment: .leading, spacing: 12) {
                Text("Export your notes, note organization, and supported Remi preferences as a single JSON file. API keys and machine-specific startup or hotkey settings are not included.")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)

                HStack(spacing: 10) {
                    Button {
                        exportLibrary()
                    } label: {
                        Label("Export JSON", systemImage: "square.and.arrow.up")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .liquidGlassButtonStyle()
                    .disabled(isProcessingTransfer)
                    .accessibilityLabel("Export Remi library as JSON")

                    Button {
                        importLibrary()
                    } label: {
                        Label("Import JSON", systemImage: "square.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .liquidGlassButtonStyle()
                    .disabled(isProcessingTransfer)
                    .accessibilityLabel("Import Remi library from JSON")

                    if isProcessingTransfer {
                        ProgressView()
                            .controlSize(.small)
                    }
                }

                if let transferFeedback {
                    HStack(spacing: 6) {
                        Image(systemName: transferFeedback.icon)
                            .foregroundStyle(transferFeedback.tint)
                        Text(transferFeedback.message)
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }
                    .accessibilityElement(children: .combine)
                }

                Text("Import replaces the notes currently stored on this Mac and applies the exported non-sensitive preferences.")
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func systemPromptSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "AI System Prompt", subtitle: "Customize how the AI assistant behaves") {
            VStack(alignment: .leading, spacing: 8) {
                TextEditor(text: $settings.aiSystemPrompt)
                    .font(.system(size: 12, design: .monospaced))
                    .scrollContentBackground(.hidden)
                    .padding(10)
                    .frame(height: 100)
                    .background(theme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Button("Reset to Default") {
                    let defaultPrompt = "You are a concise note-taking assistant. Always respond in plain text. Be brief and direct. Preserve intent while improving grammar and clarity. Return only the improved document."
                    settings.aiSystemPrompt = defaultPrompt
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(theme.textSecondary)
            }
        }
    }

    @ViewBuilder
    private func aiTemplatesSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "AI Prompt Templates", subtitle: "Quick actions shown in the AI assistant") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach($settings.aiQuickActions.indices, id: \.self) { index in
                    HStack {
                        TextField("Template prompt...", text: $settings.aiQuickActions[index])
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(theme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .font(.system(size: 12))

                        Button {
                            settings.aiQuickActions.remove(at: index)
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 11))
                                .foregroundStyle(.red.opacity(0.8))
                                .padding(6)
                                .background(Color.red.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                    }
                }

                Button {
                    settings.aiQuickActions.append("")
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Add Template")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(theme.accent)
                    .padding(.top, 4)
                }
                .buttonStyle(.plain)

                if settings.aiQuickActions.isEmpty {
                    Text("No templates added. The quick actions bar will be hidden.")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                        .padding(.top, 2)
                }
            }
        }
    }

    @ViewBuilder
    private func aboutSection(theme: Theme) -> some View {
        sectionCard(theme: theme, title: "About Remi", subtitle: "Version \(appVersion)") {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    if let icon = NSImage(named: "AppIcon") {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Remi")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(theme.textPrimary)
                        Text("A minimal macOS menu-bar notes app")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Divider().opacity(0.15)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Made by")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                        Link("ashref.tn", destination: URL(string: "https://ashref.tn")!)
                            .font(.system(size: 12, weight: .semibold))
                    }
                    HStack {
                        Text("Open source")
                            .font(.system(size: 12))
                            .foregroundStyle(theme.textSecondary)
                        Link("remi.ashref.tn", destination: URL(string: "https://remi.ashref.tn/")!)
                            .font(.system(size: 12, weight: .semibold))
                    }
                }

                Divider().opacity(0.15)

                Button("Reset Onboarding") {
                    settings.triggerOnboarding()
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundStyle(.red.opacity(0.7))
            }
        }
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    @ViewBuilder
    private func sectionCard<Content: View>(theme: Theme, title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
            content()
        }
        .padding(14)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.08, fallbackMaterial: .regularMaterial)
        }
    }

    @ViewBuilder
    private func settingRow<Content: View>(theme: Theme, title: String, subtitle: String, @ViewBuilder trailing: () -> Content) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(theme.textSecondary)
            }
            Spacer()
            trailing()
        }
        .padding(.vertical, 10)
    }

    private func validateKey() async {
        validationState = .validating
        do {
            try await OpenRouterClient.shared.validateAPIKey()
            validationState = .valid
            HapticsService.shared.perform(.apiKeyValidated)
        } catch {
            let message = (error as? LLMError)?.errorDescription ?? error.localizedDescription
            validationState = .invalid(message.isEmpty ? "Validation failed" : message)
        }
    }

    private var isAPIKeyEntered: Bool {
        !settings.llmAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    @MainActor
    private func exportLibrary() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.isExtensionHidden = false
        panel.nameFieldStringValue = "remi-library-\(Self.archiveDateFormatter.string(from: Date())).json"

        guard panel.runModal() == .OK, let destinationURL = panel.url else { return }

        isProcessingTransfer = true
        transferFeedback = nil

        do {
            let data = try NookManager.shared.exportLibraryArchive(settings: settings.exportTransferSettings())
            try data.write(to: destinationURL, options: .atomic)
            HapticsService.shared.perform(.dataExported)
            transferFeedback = TransferFeedback(
                icon: "checkmark.circle.fill",
                message: "Exported library to \(destinationURL.lastPathComponent).",
                tint: .green
            )
            ErrorHandlingService.shared.showInfo(message: "Remi library exported.")
        } catch {
            let message = error.localizedDescription.isEmpty ? "Failed to export your Remi library." : error.localizedDescription
            transferFeedback = TransferFeedback(icon: "xmark.circle.fill", message: message, tint: .red)
            ErrorHandlingService.shared.showError(message: message)
        }

        isProcessingTransfer = false
    }

    @MainActor
    private func importLibrary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let sourceURL = panel.url else { return }
        guard confirmImport() else { return }

        isProcessingTransfer = true
        transferFeedback = nil

        do {
            let data = try Data(contentsOf: sourceURL)
            let archive = try NookManager.shared.importLibraryArchive(data)
            settings.applyImportedTransferSettings(archive.settings)
            settings.clearLastViewedNook()
            HapticsService.shared.perform(.dataImported)
            transferFeedback = TransferFeedback(
                icon: "checkmark.circle.fill",
                message: "Imported \(archive.notes.count) note\(archive.notes.count == 1 ? "" : "s") from \(sourceURL.lastPathComponent).",
                tint: .green
            )
            ErrorHandlingService.shared.showInfo(message: "Remi library imported.")
        } catch {
            let message = error.localizedDescription.isEmpty ? "Failed to import that Remi JSON file." : error.localizedDescription
            transferFeedback = TransferFeedback(icon: "xmark.circle.fill", message: message, tint: .red)
            ErrorHandlingService.shared.showError(message: message)
        }

        isProcessingTransfer = false
    }

    @MainActor
    private func confirmImport() -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Replace the current Remi library?"
        alert.informativeText = "Importing replaces the notes stored on this Mac and applies the exported non-sensitive preferences. Your API key is not included in the transfer file."
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Cancel")
        return alert.runModal() == .alertFirstButtonReturn
    }

    private static let archiveDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}
