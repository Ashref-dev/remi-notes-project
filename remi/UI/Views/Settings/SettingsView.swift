import SwiftUI
import LaunchAtLogin
import HotKey

struct SettingsView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var hotkeyKey: Key = .r
    @State private var hotkeyModifiers: NSEvent.ModifierFlags = [.command, .option]

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
                    HotkeyRecorderView(key: $hotkeyKey, modifiers: $hotkeyModifiers)
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
        .onAppear(perform: loadHotkey)
        .onDisappear(perform: saveHotkey)
    }
    
    private func loadHotkey() {
        if let savedKey = UserDefaults.standard.string(forKey: "globalHotkeyKey"),
           let key = Key(string: savedKey) {
            self.hotkeyKey = key
        }
        
        let savedModifiers = UserDefaults.standard.integer(forKey: "globalHotkeyModifiers")
        if savedModifiers > 0 {
            self.hotkeyModifiers = NSEvent.ModifierFlags(rawValue: UInt(savedModifiers))
        }
    }
    
    private func saveHotkey() {
        let newHotkey = HotKey(key: hotkeyKey, modifiers: hotkeyModifiers)
        UserDefaults.standard.set(hotkeyKey.description, forKey: "globalHotkeyKey")
        UserDefaults.standard.set(hotkeyModifiers.rawValue, forKey: "globalHotkeyModifiers")
        
        // Re-register hotkey
        HotkeyManager.shared.unregisterAllHotKeys()
        HotkeyManager.shared.register(hotkey: newHotkey) { }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
