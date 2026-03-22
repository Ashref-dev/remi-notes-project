import Foundation
import Combine
import LaunchAtLogin
import HotKey
import AppKit
import SwiftUI

extension Notification.Name {
    static let selectNookByIndex = Notification.Name("selectNookByIndex")
}

enum ColorThemeOption: String, CaseIterable, Identifiable {
    case system = "System"
    case customLight = "Light"
    case customDark = "Dark"
    
    var id: String { rawValue }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .customLight: return .light
        case .customDark: return .dark
        }
    }
}

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var colorSchemeOption: ColorThemeOption {
        didSet { UserDefaults.standard.set(colorSchemeOption.rawValue, forKey: Keys.colorSchemeOption) }
    }

    @Published var llmAPIKey: String {
        didSet {
            UserDefaults.standard.set(llmAPIKey, forKey: Keys.llmAPIKey)
        }
    }

    @Published var selectedModelId: String {
        didSet {
            UserDefaults.standard.set(selectedModelId, forKey: Keys.selectedModelId)
        }
    }

    @Published var modelParameters: ModelParameters {
        didSet {
            saveModelParameters()
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            LaunchAtLogin.isEnabled = launchAtLogin
        }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet {
            UserDefaults.standard.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding)
        }
    }

    @Published var aboutMeContext: String {
        didSet { UserDefaults.standard.set(aboutMeContext, forKey: Keys.aboutMeContext) }
    }

    @Published var aiSystemPrompt: String {
        didSet { UserDefaults.standard.set(aiSystemPrompt, forKey: Keys.aiSystemPrompt) }
    }

    @Published var aiQuickActions: [String] {
        didSet { UserDefaults.standard.set(aiQuickActions, forKey: Keys.aiQuickActions) }
    }

    @Published var ambientSuggestionsEnabled: Bool {
        didSet { UserDefaults.standard.set(ambientSuggestionsEnabled, forKey: Keys.ambientSuggestionsEnabled) }
    }

    @Published var captureDefaultRoute: CaptureRoute {
        didSet { UserDefaults.standard.set(captureDefaultRoute.rawValue, forKey: Keys.captureDefaultRoute) }
    }

    @Published var historyRetentionDays: Int {
        didSet {
            let clamped = max(1, min(historyRetentionDays, 365))
            if historyRetentionDays != clamped {
                historyRetentionDays = clamped
                return
            }
            UserDefaults.standard.set(historyRetentionDays, forKey: Keys.historyRetentionDays)
        }
    }

    @Published var historyMaxRevisions: Int {
        didSet {
            let clamped = max(5, min(historyMaxRevisions, 500))
            if historyMaxRevisions != clamped {
                historyMaxRevisions = clamped
                return
            }
            UserDefaults.standard.set(historyMaxRevisions, forKey: Keys.historyMaxRevisions)
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

    @Published var nookHotkeyModifiers: NSEvent.ModifierFlags {
        didSet {
            UserDefaults.standard.set(nookHotkeyModifiers.rawValue, forKey: Keys.nookHotkeyModifiers)
            saveNookHotkeys()
        }
    }

    @Published var enableNookHotkeys: Bool {
        didSet {
            UserDefaults.standard.set(enableNookHotkeys, forKey: Keys.enableNookHotkeys)
            if enableNookHotkeys {
                saveNookHotkeys()
            } else {
                HotkeyManager.shared.unregisterNookHotkeys()
            }
        }
    }

    @Published var enableQuickCaptureHotkey: Bool {
        didSet {
            UserDefaults.standard.set(enableQuickCaptureHotkey, forKey: Keys.enableQuickCaptureHotkey)
            saveAuxiliaryHotkeys()
        }
    }

    @Published var enableTodayHotkey: Bool {
        didSet {
            UserDefaults.standard.set(enableTodayHotkey, forKey: Keys.enableTodayHotkey)
            saveAuxiliaryHotkeys()
        }
    }

    private enum Keys {
        static let llmAPIKey = "llmAPIKey"
        static let selectedModelId = "selectedModelId"
        static let modelParameters = "modelParameters"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let aboutMeContext = "aboutMeContext"
        static let aiSystemPrompt = "aiSystemPrompt"
        static let aiQuickActions = "aiQuickActions"
        static let ambientSuggestionsEnabled = "ambientSuggestionsEnabled"
        static let captureDefaultRoute = "captureDefaultRoute"
        static let historyRetentionDays = "historyRetentionDays"
        static let historyMaxRevisions = "historyMaxRevisions"
        static let globalHotkeyKey = "globalHotkeyKey"
        static let globalHotkeyModifiers = "globalHotkeyModifiers"
        static let nookHotkeyModifiers = "nookHotkeyModifiers"
        static let enableNookHotkeys = "enableNookHotkeys"
        static let enableQuickCaptureHotkey = "enableQuickCaptureHotkey"
        static let enableTodayHotkey = "enableTodayHotkey"
        static let lastViewedNookURL = "lastViewedNookURL"
        static let didMigrateAISettingsV2 = "didMigrateAISettingsV2"
        static let colorSchemeOption = "colorSchemeOption"
    }

    private enum LegacyKeys {
        static let groqAPIKey = "groqAPIKey"
        static let selectedGroqModel = "selectedGroqModel"
    }

    private init() {
        Self.migrateLegacyAISettingsIfNeeded()

        self.llmAPIKey = UserDefaults.standard.string(forKey: Keys.llmAPIKey) ?? ""
        self.selectedModelId = UserDefaults.standard.string(forKey: Keys.selectedModelId) ?? RemoteModel.defaultModelId
        self.modelParameters = Self.loadModelParameters()
        self.launchAtLogin = LaunchAtLogin.isEnabled
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: Keys.hasCompletedOnboarding)
        self.aboutMeContext = UserDefaults.standard.string(forKey: Keys.aboutMeContext) ?? ""
        let defaultPrompt = "You are a concise note-taking assistant. Always respond in plain text. Be brief and direct. Preserve intent while improving grammar and clarity. Return only the improved document."
        self.aiSystemPrompt = UserDefaults.standard.string(forKey: Keys.aiSystemPrompt) ?? defaultPrompt

        let defaultQuickActions = [
            "Fix grammar & spelling",
            "Make this more concise",
            "Add more detail",
            "Rewrite as bullet points",
            "Summarize this",
            "Improve clarity"
        ]
        self.aiQuickActions = UserDefaults.standard.stringArray(forKey: Keys.aiQuickActions) ?? defaultQuickActions
        self.ambientSuggestionsEnabled = UserDefaults.standard.object(forKey: Keys.ambientSuggestionsEnabled) as? Bool ?? true
        self.captureDefaultRoute = CaptureRoute(
            rawValue: UserDefaults.standard.string(forKey: Keys.captureDefaultRoute) ?? CaptureRoute.createInboxNote.rawValue
        ) ?? .createInboxNote
        let storedRetentionDays = UserDefaults.standard.integer(forKey: Keys.historyRetentionDays)
        self.historyRetentionDays = storedRetentionDays == 0 ? 30 : storedRetentionDays
        let storedMaxRevisions = UserDefaults.standard.integer(forKey: Keys.historyMaxRevisions)
        self.historyMaxRevisions = storedMaxRevisions == 0 ? 50 : storedMaxRevisions

        let (key, modifiers) = Self.loadHotkey()
        self.hotkeyKey = key
        self.hotkeyModifiers = modifiers

        let nookModifiersRawValue = UserDefaults.standard.integer(forKey: Keys.nookHotkeyModifiers)
        self.nookHotkeyModifiers = nookModifiersRawValue == 0 ? [.command, .shift] : NSEvent.ModifierFlags(rawValue: UInt(nookModifiersRawValue))
        self.enableNookHotkeys = UserDefaults.standard.bool(forKey: Keys.enableNookHotkeys)
        self.enableQuickCaptureHotkey = UserDefaults.standard.object(forKey: Keys.enableQuickCaptureHotkey) as? Bool ?? true
        self.enableTodayHotkey = UserDefaults.standard.object(forKey: Keys.enableTodayHotkey) as? Bool ?? false
        
        let storedThemeRaw = UserDefaults.standard.string(forKey: Keys.colorSchemeOption) ?? ColorThemeOption.system.rawValue
        self.colorSchemeOption = ColorThemeOption(rawValue: storedThemeRaw) ?? .system

        saveAuxiliaryHotkeys()
    }

    func migrateLegacyAISettingsIfNeeded() {
        Self.migrateLegacyAISettingsIfNeeded()
        llmAPIKey = UserDefaults.standard.string(forKey: Keys.llmAPIKey) ?? ""
        selectedModelId = UserDefaults.standard.string(forKey: Keys.selectedModelId) ?? RemoteModel.defaultModelId
    }

    private static func migrateLegacyAISettingsIfNeeded() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Keys.didMigrateAISettingsV2) else { return }

        if defaults.string(forKey: Keys.llmAPIKey)?.isEmpty ?? true,
           let legacyKey = defaults.string(forKey: LegacyKeys.groqAPIKey),
           !legacyKey.isEmpty {
            defaults.set(legacyKey, forKey: Keys.llmAPIKey)
        }

        if defaults.string(forKey: Keys.selectedModelId)?.isEmpty ?? true,
           let legacyModel = defaults.string(forKey: LegacyKeys.selectedGroqModel),
           !legacyModel.isEmpty {
            defaults.set(legacyModel, forKey: Keys.selectedModelId)
        }

        if defaults.string(forKey: Keys.selectedModelId)?.isEmpty ?? true {
            defaults.set(RemoteModel.defaultModelId, forKey: Keys.selectedModelId)
        }

        defaults.set(true, forKey: Keys.didMigrateAISettingsV2)
    }

    func triggerOnboarding() {
        hasCompletedOnboarding = false
        OnboardingService.shared.reset()
    }

    func isAPIKeyConfigured() -> Bool {
        !llmAPIKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func resetToDefaultModel() {
        selectedModelId = RemoteModel.defaultModelId
        modelParameters = ModelParameters.default
    }

    private static func loadHotkey() -> (Key, NSEvent.ModifierFlags) {
        let keyString = UserDefaults.standard.string(forKey: Keys.globalHotkeyKey) ?? "R"
        let modifiersRawValue = UserDefaults.standard.integer(forKey: Keys.globalHotkeyModifiers)

        let key = Key(string: keyString) ?? .r
        if modifiersRawValue == 0 {
            return (key, [.command, .option])
        }

        return (key, NSEvent.ModifierFlags(rawValue: UInt(modifiersRawValue)))
    }

    private static func loadModelParameters() -> ModelParameters {
        guard let data = UserDefaults.standard.data(forKey: Keys.modelParameters),
              let parameters = try? JSONDecoder().decode(ModelParameters.self, from: data) else {
            return ModelParameters.default
        }
        return parameters
    }

    private func saveModelParameters() {
        guard let data = try? JSONEncoder().encode(modelParameters) else { return }
        UserDefaults.standard.set(data, forKey: Keys.modelParameters)
    }

    private func saveHotkey() {
        UserDefaults.standard.set(hotkeyKey.description, forKey: Keys.globalHotkeyKey)
        UserDefaults.standard.set(hotkeyModifiers.rawValue, forKey: Keys.globalHotkeyModifiers)

        let newHotkey = HotKey(key: hotkeyKey, modifiers: hotkeyModifiers)
        HotkeyManager.shared.update(hotkey: newHotkey)
    }

    private func saveNookHotkeys() {
        guard enableNookHotkeys else { return }
        HotkeyManager.shared.registerCustomNookHotkeys(modifiers: nookHotkeyModifiers) { nookIndex in
            NotificationCenter.default.post(name: .selectNookByIndex, object: nookIndex)
        }
    }

    private func saveAuxiliaryHotkeys() {
        if enableQuickCaptureHotkey {
            HotkeyManager.shared.registerQuickCaptureHotkey {
                NotificationCenter.default.post(name: .showQuickCapturePanel, object: nil)
            }
        } else {
            HotkeyManager.shared.unregisterQuickCaptureHotkey()
        }

        if enableTodayHotkey {
            HotkeyManager.shared.registerTodayHotkey {
                NotificationCenter.default.post(name: .showTodayOverlay, object: nil)
            }
        } else {
            HotkeyManager.shared.unregisterTodayHotkey()
        }
    }

    func lastViewedNookURL() -> URL? {
        UserDefaults.standard.url(forKey: Keys.lastViewedNookURL)
    }

    func setLastViewedNook(_ nook: Nook) {
        UserDefaults.standard.set(nook.url, forKey: Keys.lastViewedNookURL)
    }

    func clearLastViewedNook() {
        UserDefaults.standard.removeObject(forKey: Keys.lastViewedNookURL)
    }

    func exportTransferSettings() -> LibraryTransferSettings {
        LibraryTransferSettings(
            colorSchemeOptionRawValue: colorSchemeOption.rawValue,
            aboutMeContext: aboutMeContext,
            selectedModelId: selectedModelId,
            modelParameters: modelParameters,
            aiSystemPrompt: aiSystemPrompt,
            aiQuickActions: aiQuickActions,
            ambientSuggestionsEnabled: ambientSuggestionsEnabled,
            captureDefaultRoute: captureDefaultRoute,
            historyRetentionDays: historyRetentionDays,
            historyMaxRevisions: historyMaxRevisions
        )
    }

    func applyImportedTransferSettings(_ imported: LibraryTransferSettings) {
        colorSchemeOption = ColorThemeOption(rawValue: imported.colorSchemeOptionRawValue) ?? .system
        aboutMeContext = imported.aboutMeContext
        selectedModelId = imported.selectedModelId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? RemoteModel.defaultModelId
            : imported.selectedModelId
        modelParameters = imported.modelParameters
        aiSystemPrompt = imported.aiSystemPrompt
        aiQuickActions = imported.aiQuickActions
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        ambientSuggestionsEnabled = imported.ambientSuggestionsEnabled
        captureDefaultRoute = imported.captureDefaultRoute
        historyRetentionDays = imported.historyRetentionDays
        historyMaxRevisions = imported.historyMaxRevisions
    }
}
