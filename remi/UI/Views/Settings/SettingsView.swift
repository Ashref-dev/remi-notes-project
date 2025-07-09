import SwiftUI
import LaunchAtLogin
import HotKey

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var globalHotkey: HotKey = HotKey(key: .r, modifiers: [.command, .option]) // Default hotkey

    var body: some View {
        Form {
            Section(header: Text("API")) {
                SecureField("Groq API Key", text: $settings.groqAPIKey)
            }
            
            Section(header: Text("General")) {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
                
                HStack {
                    Text("Global Hotkey")
                    Spacer()
                    HotkeyRecorderView(hotkey: $globalHotkey)
                }
            }
            
            Section(header: Text("About Me Context")) {
                TextEditor(text: $settings.aboutMeContext)
                    .frame(minHeight: 100)
                    .font(.body)
                    .lineLimit(nil)
                Text("This context will be included in every AI call to personalize responses. E.g., 'I am a software engineer working on macOS apps.'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(width: 500, height: 450)
        .onAppear {
            // Load saved hotkey or use default
            if let savedKey = UserDefaults.standard.string(forKey: "globalHotkeyKey"),
               let savedModifiers = UserDefaults.standard.object(forKey: "globalHotkeyModifiers") as? UInt,
               let key = Key(string: savedKey) {
                globalHotkey = HotKey(key: key, modifiers: NSEvent.ModifierFlags(rawValue: savedModifiers))
            }
        }
        .onDisappear {
            // Save new hotkey
            UserDefaults.standard.set(globalHotkey.key.description, forKey: "globalHotkeyKey")
            UserDefaults.standard.set(globalHotkey.modifiers.rawValue, forKey: "globalHotkeyModifiers")
            // Re-register hotkey
            HotkeyManager.shared.unregisterAllHotKeys()
            HotkeyManager.shared.register(hotkey: globalHotkey) { }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
