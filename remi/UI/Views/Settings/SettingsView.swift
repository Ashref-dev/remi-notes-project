import SwiftUI
import LaunchAtLogin
import HotKey

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                Header(theme: theme)
                
                Divider()
                
                Form {
                    Section(header: Text("API Configuration").font(.headline)) {
                        SecureField("Groq API Key", text: $settings.groqAPIKey)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    
                    Section(header: Text("General").font(.headline)) {
                        Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                        
                        HStack {
                            Text("Global Hotkey")
                            Spacer()
                            HotkeyRecorderView(hotkey: $settings.hotkey)
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
