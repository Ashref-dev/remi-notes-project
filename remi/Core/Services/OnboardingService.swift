import Foundation
import SwiftUI
import Combine

class OnboardingService: ObservableObject {
    static let shared = OnboardingService()
    
    @Published var currentStep: OnboardingStep = .welcome
    @Published var isOnboardingComplete: Bool = false
    @Published var permissionsGranted: [Permission: Bool] = [:]
    
    private let settingsManager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    enum OnboardingStep: Int, CaseIterable {
        case welcome = 0
        case permissions = 1
        case features = 2
        case completion = 3
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .permissions: return "Permissions"
            case .features: return "Features"
            case .completion: return "Complete"
            }
        }
    }
    
    enum Permission: CaseIterable {
        case backgroundExecution
        case launchAtLogin
        case menuBarAccess
        
        var title: String {
            switch self {
            case .backgroundExecution: return "Background Execution"
            case .launchAtLogin: return "Launch at Login"
            case .menuBarAccess: return "Menu Bar Access"
            }
        }
    }
    
    private init() {
        setupObservers()
        loadOnboardingState()
    }
    
    private func setupObservers() {
        settingsManager.$hasCompletedOnboarding
            .sink { [weak self] completed in
                self?.isOnboardingComplete = completed
            }
            .store(in: &cancellables)
    }
    
    private func loadOnboardingState() {
        if let stepRawValue = UserDefaults.standard.object(forKey: "onboardingCurrentStep") as? Int,
           let step = OnboardingStep(rawValue: stepRawValue) {
            currentStep = step
        }
        
        // Load permissions state
        for permission in Permission.allCases {
            let key = "onboarding_permission_\(permission)"
            permissionsGranted[permission] = UserDefaults.standard.bool(forKey: key)
        }
    }
    
    private func saveOnboardingState() {
        UserDefaults.standard.set(currentStep.rawValue, forKey: "onboardingCurrentStep")
        
        // Save permissions state
        for (permission, granted) in permissionsGranted {
            let key = "onboarding_permission_\(permission)"
            UserDefaults.standard.set(granted, forKey: key)
        }
    }
    
    // MARK: - Navigation Methods
    
    func nextStep() {
        guard currentStep.rawValue < OnboardingStep.allCases.count - 1 else { return }
        
        currentStep = OnboardingStep(rawValue: currentStep.rawValue + 1) ?? currentStep
        saveOnboardingState()
    }
    
    func previousStep() {
        guard currentStep.rawValue > 0 else { return }
        
        currentStep = OnboardingStep(rawValue: currentStep.rawValue - 1) ?? currentStep
        saveOnboardingState()
    }
    
    func goToStep(_ step: OnboardingStep) {
        currentStep = step
        saveOnboardingState()
    }
    
    func completeOnboarding() {
        settingsManager.hasCompletedOnboarding = true
        isOnboardingComplete = true
        clearOnboardingState()
    }
    
    func reset() {
        currentStep = .welcome
        permissionsGranted.removeAll()
        settingsManager.hasCompletedOnboarding = false
        isOnboardingComplete = false
        saveOnboardingState()
    }
    
    private func clearOnboardingState() {
        UserDefaults.standard.removeObject(forKey: "onboardingCurrentStep")
        
        for permission in Permission.allCases {
            let key = "onboarding_permission_\(permission)"
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
    
    // MARK: - Permission Management
    
    func setPermission(_ permission: Permission, granted: Bool) {
        permissionsGranted[permission] = granted
        saveOnboardingState()
    }
    
    func isPermissionGranted(_ permission: Permission) -> Bool {
        return permissionsGranted[permission] ?? false
    }
    
    var allRequiredPermissionsGranted: Bool {
        return Permission.allCases.allSatisfy { isPermissionGranted($0) }
    }
    
    var canProceedFromCurrentStep: Bool {
        switch currentStep {
        case .welcome, .features, .completion:
            return true
        case .permissions:
            return allRequiredPermissionsGranted
        }
    }
}

// MARK: - Error Handling

enum OnboardingError: LocalizedError {
    case permissionTimeout
    case serviceUnavailable
    case dataCorruption
    case networkError
    case invalidStepTransition
    
    var errorDescription: String? {
        switch self {
        case .permissionTimeout:
            return "Permission request timed out. You can set this up manually in System Preferences."
        case .serviceUnavailable:
            return "Onboarding service is temporarily unavailable. Basic setup will be used."
        case .dataCorruption:
            return "Onboarding data was corrupted. Restarting the setup process."
        case .networkError:
            return "Network connection issue. Some features may be limited."
        case .invalidStepTransition:
            return "Invalid step transition attempted."
        }
    }
}

extension OnboardingService {
    func handleError(_ error: OnboardingError) {
        switch error {
        case .permissionTimeout:
            // Show manual instruction option
            break
        case .serviceUnavailable:
            // Fallback to basic setup
            break
        case .dataCorruption:
            // Reset onboarding state
            reset()
            break
        case .networkError:
            // Continue with limited functionality
            break
        case .invalidStepTransition:
            // Log error and stay on current step
            print("Invalid step transition attempted")
            break
        }
    }
}
