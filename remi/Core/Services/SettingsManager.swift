import Foundation
import Combine
import LaunchAtLogin
import HotKey
import AppKit

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
    
    @Published var hotkeyKey: Key {
        didSet {
            saveHotkey()
        }
    }
    
    @Published var hotkeyModifiers: NSEvent.ModifierFlags {
        didSet {
            saveHotkey()
        }
    }

    private init() {
        self.groqAPIKey = UserDefaults.standard.string(forKey: "groqAPIKey") ?? ""
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.aboutMeContext = UserDefaults.standard.string(forKey: "aboutMeContext") ?? ""
        
        let (key, modifiers) = Self.loadHotkey()
        self.hotkeyKey = key
        self.hotkeyModifiers = modifiers
    }
    
    private static func loadHotkey() -> (Key, NSEvent.ModifierFlags) {
        let keyString = UserDefaults.standard.string(forKey: "globalHotkeyKey") ?? "R"
        let modifiersRawValue = UserDefaults.standard.integer(forKey: "globalHotkeyModifiers")
        
        let key = Key(string: keyString) ?? .r
        
        if modifiersRawValue == 0 {
            return (key, [.command, .option])
        }
        
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(modifiersRawValue))
        
        return (key, modifiers)
    }
    
    private func saveHotkey() {
        UserDefaults.standard.set(hotkeyKey.description, forKey: "globalHotkeyKey")
        UserDefaults.standard.set(hotkeyModifiers.rawValue, forKey: "globalHotkeyModifiers")
        
        let newHotkey = HotKey(key: hotkeyKey, modifiers: hotkeyModifiers)
        HotkeyManager.shared.update(hotkey: newHotkey)
    }
    
    func lastViewedNookURL() -> URL? {
        return UserDefaults.standard.url(forKey: "lastViewedNookURL")
    }
    
    func setLastViewedNook(_ nook: Nook) {
        UserDefaults.standard.set(nook.url, forKey: "lastViewedNookURL")
    }
}
