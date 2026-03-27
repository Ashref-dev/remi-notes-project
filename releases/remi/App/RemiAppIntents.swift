import AppIntents

struct CreateNoteIntent: AppIntent {
    static var title: LocalizedStringResource = "Create Note"
    static var description = IntentDescription("Create a new note in Remi.")
    static var openAppWhenRun = false

    @Parameter(title: "Title")
    var titleText: String?

    @Parameter(title: "Content")
    var content: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let title = titleText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false ? titleText! : "New Nook"
        let created = NookManager.shared.createNook(
            named: title,
            initialContent: content?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            captureSource: .appIntent
        )
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        return .result(dialog: IntentDialog("Created \(created?.name ?? "a note") in Remi."))
    }
}

struct OpenFocusWindowIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Focus Window"
    static var description = IntentDescription("Open Remi's detached focus window.")
    static var openAppWhenRun = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            NotificationCenter.default.post(name: .openFocusWindow, object: nil)
        }
        return .result(dialog: IntentDialog("Opened the Remi focus window."))
    }
}

struct ApplyAIPresetIntent: AppIntent {
    static var title: LocalizedStringResource = "Apply AI Preset"
    static var description = IntentDescription("Generate an AI edit proposal for the current Remi note.")
    static var openAppWhenRun = false

    @Parameter(title: "Preset")
    var preset: String

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let note = try await NoteAutomationService.shared.applyPresetToCurrentNote(preset)
        return .result(dialog: IntentDialog("Prepared an AI proposal for \(note.name)."))
    }
}

struct RemiAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CreateNoteIntent(),
            phrases: [
                "Create a note in \(.applicationName)",
                "New note in \(.applicationName)"
            ],
            shortTitle: "Create Note",
            systemImageName: "note.text.badge.plus"
        )
        AppShortcut(
            intent: OpenFocusWindowIntent(),
            phrases: [
                "Open focus window in \(.applicationName)"
            ],
            shortTitle: "Focus Window",
            systemImageName: "macwindow"
        )
        AppShortcut(
            intent: ApplyAIPresetIntent(),
            phrases: [
                "Apply AI preset in \(.applicationName)"
            ],
            shortTitle: "AI Preset",
            systemImageName: "sparkles"
        )
    }
}
