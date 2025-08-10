import Foundation
import SwiftUI
import Combine
import LaunchAtLogin
import AppKit

class PermissionsService: ObservableObject {
    static let shared = PermissionsService()
    
    @Published var backgroundPermissionStatus: PermissionStatus = .unknown
    @Published var launchAtLoginStatus: PermissionStatus = .unknown
    @Published var menuBarAccessStatus: PermissionStatus = .granted // Menu bar access is automatic
    
    private let onboardingService = OnboardingService.shared
    private let settingsManager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum PermissionStatus {
        case unknown
        case granted
        case denied
        case requesting
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .granted: return .green
            case .denied: return .red
            case .requesting: return .orange
            }
        }
        
        var iconName: String {
            switch self {
            case .unknown: return "questionmark.circle"
            case .granted: return "checkmark.circle.fill"
            case .denied: return "xmark.circle.fill"
            case .requesting: return "clock.circle"
            }
        }
    }
    
    private init() {
        setupObservers()
        Task {
            await checkAllPermissions()
        }
    }
    
    private func setupObservers() {
        // Monitor launch at login changes
        NotificationCenter.default.publisher(for: NSNotification.Name("LaunchAtLoginStateChanged"))
            .sink { [weak self] _ in
                Task {
                    await self?.checkLaunchAtLoginPermission()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Permission Checking
    
    @MainActor
    func checkAllPermissions() async {
        await checkBackgroundPermission()
        await checkLaunchAtLoginPermission()
        await checkMenuBarAccessPermission()
    }
    
    @MainActor
    private func checkBackgroundPermission() async {
        // For menu bar apps, background execution is typically granted automatically
        // We check if the app is set to run as LSUIElement
        let backgroundAllowed = Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool ?? false
        backgroundPermissionStatus = backgroundAllowed ? .granted : .denied
        
        onboardingService.setPermission(.backgroundExecution, granted: backgroundPermissionStatus == .granted)
    }
    
    @MainActor
    private func checkLaunchAtLoginPermission() async {
        launchAtLoginStatus = LaunchAtLogin.isEnabled ? .granted : .denied
        onboardingService.setPermission(.launchAtLogin, granted: launchAtLoginStatus == .granted)
    }
    
    @MainActor
    private func checkMenuBarAccessPermission() async {
        // Menu bar access is automatic for menu bar apps
        menuBarAccessStatus = .granted
        onboardingService.setPermission(.menuBarAccess, granted: true)
    }
    
    // MARK: - Permission Requests
    
    @MainActor
    func requestBackgroundPermission() async -> Bool {
        backgroundPermissionStatus = .requesting
        
        // For background execution, we mainly need to ensure the app is configured correctly
        // and explain to the user what this means
        
        // Simulate a brief delay for UX
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Check if app is properly configured as background app
        let isConfigured = Bundle.main.object(forInfoDictionaryKey: "LSUIElement") as? Bool ?? false
        
        if isConfigured {
            backgroundPermissionStatus = .granted
            onboardingService.setPermission(.backgroundExecution, granted: true)
            return true
        } else {
            backgroundPermissionStatus = .denied
            onboardingService.setPermission(.backgroundExecution, granted: false)
            return false
        }
    }
    
    @MainActor
    func requestLaunchAtLoginPermission() async -> Bool {
        launchAtLoginStatus = .requesting
        
        // Simulate a brief delay for UX
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Enable launch at login
        LaunchAtLogin.isEnabled = true
        settingsManager.launchAtLogin = true
        
        // Verify it was set
        let isEnabled = LaunchAtLogin.isEnabled
        launchAtLoginStatus = isEnabled ? .granted : .denied
        onboardingService.setPermission(.launchAtLogin, granted: isEnabled)
        
        return isEnabled
    }
    
    @MainActor
    func requestMenuBarAccessPermission() async -> Bool {
        // Menu bar access is automatic, no user action needed
        menuBarAccessStatus = .granted
        onboardingService.setPermission(.menuBarAccess, granted: true)
        return true
    }
    
    @MainActor
    func requestAllPermissions() async -> Bool {
        let backgroundResult = await requestBackgroundPermission()
        let launchAtLoginResult = await requestLaunchAtLoginPermission()
        let menuBarResult = await requestMenuBarAccessPermission()
        
        return backgroundResult && launchAtLoginResult && menuBarResult
    }
    
    // MARK: - Manual Setup
    
    func openSystemPreferences() {
        // Open System Preferences to Security & Privacy
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy")!
        NSWorkspace.shared.open(url)
    }
    
    func openLoginItemsPreferences() {
        // Open System Preferences to Login Items
        if #available(macOS 13.0, *) {
            let url = URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
            NSWorkspace.shared.open(url)
        } else {
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.users?loginItems")!
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Utility Methods
    
    var allPermissionsGranted: Bool {
        return backgroundPermissionStatus == .granted &&
               launchAtLoginStatus == .granted &&
               menuBarAccessStatus == .granted
    }
    
    var anyPermissionRequesting: Bool {
        return backgroundPermissionStatus == .requesting ||
               launchAtLoginStatus == .requesting ||
               menuBarAccessStatus == .requesting
    }
    
    func getPermissionStatus(for permission: OnboardingService.Permission) -> PermissionStatus {
        switch permission {
        case .backgroundExecution:
            return backgroundPermissionStatus
        case .launchAtLogin:
            return launchAtLoginStatus
        case .menuBarAccess:
            return menuBarAccessStatus
        }
    }
    
    func getPermissionDescription(for permission: OnboardingService.Permission) -> String {
        switch permission {
        case .backgroundExecution:
            return "Allows Remi to run quietly in the background and appear in your menu bar"
        case .launchAtLogin:
            return "Automatically starts Remi when you log into your Mac"
        case .menuBarAccess:
            return "Shows Remi's icon in your menu bar for quick access"
        }
    }
    
    func getPermissionIcon(for permission: OnboardingService.Permission) -> String {
        switch permission {
        case .backgroundExecution:
            return "app.badge"
        case .launchAtLogin:
            return "arrow.clockwise"
        case .menuBarAccess:
            return "menubar.rectangle"
        }
    }
    
    // MARK: - Error Recovery
    
    func retryPermissionRequest(for permission: OnboardingService.Permission) async -> Bool {
        switch permission {
        case .backgroundExecution:
            return await requestBackgroundPermission()
        case .launchAtLogin:
            return await requestLaunchAtLoginPermission()
        case .menuBarAccess:
            return await requestMenuBarAccessPermission()
        }
    }
    
    func resetPermissionStatus(for permission: OnboardingService.Permission) {
        switch permission {
        case .backgroundExecution:
            backgroundPermissionStatus = .unknown
        case .launchAtLogin:
            launchAtLoginStatus = .unknown
        case .menuBarAccess:
            menuBarAccessStatus = .unknown
        }
        
        onboardingService.setPermission(permission, granted: false)
    }
    
    func resetAllPermissions() {
        backgroundPermissionStatus = .unknown
        launchAtLoginStatus = .unknown
        menuBarAccessStatus = .unknown
        
        for permission in OnboardingService.Permission.allCases {
            onboardingService.setPermission(permission, granted: false)
        }
    }
}
