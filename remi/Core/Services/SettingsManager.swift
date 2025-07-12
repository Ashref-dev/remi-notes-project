import Foundation
import Combine
import LaunchAtLogin
import HotKey

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var groqAPIKey: String {
        didSet {
            UserDefaults.standard.set(groqAPIKey, forKey: "groqAPIKey")
        }
    }
    
    @Published var launchAtLogin: Bool {
        didSet {
            LaunchAtLogin.isEnabled = launchAtLogin
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding")
        }
    }

    @Published var aboutMeContext: String {
        didSet {
            UserDefaults.standard.set(aboutMeContext, forKey: "aboutMeContext")
        }
    }
    
    @Published var hotkey: HotKey {
        didSet {
            saveHotkey()
        }
    }

    private init() {
        self.groqAPIKey = UserDefaults.standard.string(forKey: "groqAPIKey") ?? ""
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.aboutMeContext = UserDefaults.standard.string(forKey: "aboutMeContext") ?? ""
        self.hotkey = Self.loadHotkey()
    }
    
    private static func loadHotkey() -> HotKey {
        let keyString = UserDefaults.standard.string(forKey: "globalHotkeyKey") ?? "R"
        let modifiersRawValue = UserDefaults.standard.integer(forKey: "globalHotkeyModifiers")
        
        let key = Key(string: keyString) ?? .r
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiersRawValue)).intersection(.deviceIndependentFlagsMask)
        
        // Default to Cmd+Option+R if nothing is saved
        if modifiersRawValue == 0 {
            return HotKey(key: .r, modifiers: [.command, .option])
        }
        
        return HotKey(key: key, modifiers: modifiers)
    }
    
    private func saveHotkey() {
        UserDefaults.standard.set(hotkey.key.description, forKey: "globalHotkeyKey")
        UserDefaults.standard.set(hotkey.modifiers.rawValue, forKey: "globalHotkeyModifiers")
        
        // Re-register the hotkey
        HotkeyManager.shared.update(hotkey: hotkey)
    }
    
    func lastViewedNookURL() -> URL? {
        return UserDefaults.standard.url(forKey: "lastViewedNookURL")
    }
    
    func setLastViewedNook(_ nook: Nook) {
        UserDefaults.standard.set(nook.url, forKey: "lastViewedNookURL")
    }
}
