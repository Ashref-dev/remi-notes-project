import Foundation
import Combine
import LaunchAtLogin

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

    private init() {
        self.groqAPIKey = UserDefaults.standard.string(forKey: "groqAPIKey") ?? ""
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.aboutMeContext = UserDefaults.standard.string(forKey: "aboutMeContext") ?? ""
    }
    
    func lastViewedNookURL() -> URL? {
        return UserDefaults.standard.url(forKey: "lastViewedNookURL")
    }
    
    func setLastViewedNook(_ nook: Nook) {
        UserDefaults.standard.set(nook.url, forKey: "lastViewedNookURL")
    }
}
