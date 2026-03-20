import Foundation

enum NoteEditorFocusArea: String, Hashable {
    case general
    case icon
    case color
    case tags
}

enum RemiCommandAction: Hashable {
    case createNote(String?)
    case renameCurrentNote
    case deleteCurrentNote
    case togglePinCurrentNote
    case changeCurrentNoteIcon
    case changeCurrentNoteColor
    case editCurrentNoteTags
    case openToday
    case openQuickCapture
    case openFocusWindow
    case pinCurrentNoteToDesktop
    case openSettings
    case setTheme(ColorThemeOption)
    case applyAIPreset(String)
}

enum RemiCommandTarget: Hashable {
    case action(RemiCommandAction)
    case note(UUID)
}

struct RemiCommand: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String?
    let icon: String
    let keywords: [String]
    let shortcutHint: String?
    let target: RemiCommandTarget

    func matches(_ query: String) -> Bool {
        guard !query.isEmpty else { return true }
        let haystack = ([title, subtitle ?? ""] + keywords).joined(separator: " ").lowercased()
        return haystack.contains(query.lowercased())
    }
}

struct CommandContext {
    let currentNook: Nook?
    let nooks: [Nook]
    let quickActions: [String]
    let openNote: (Nook) -> Void
    let createNote: (String) -> Void
    let deleteNote: (Nook) -> Void
    let togglePinned: (Nook) -> Void
    let editNote: (Nook, NoteEditorFocusArea) -> Void
    let openToday: () -> Void
    let openQuickCapture: () -> Void
    let openFocusWindow: () -> Void
    let pinCurrentNoteToDesktop: (Nook) -> Void
    let openSettings: () -> Void
    let setTheme: (ColorThemeOption) -> Void
    let applyAIPreset: (String) -> Void
}

@MainActor
final class CommandRouter {
    static let shared = CommandRouter()

    private init() {}

    func commands(matching searchText: String, context: CommandContext) -> [RemiCommand] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        var commands = baseCommands(context: context)

        if !trimmed.isEmpty,
           !context.nooks.contains(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            commands.insert(
                RemiCommand(
                    id: "create-note-\(trimmed.lowercased())",
                    title: "Create \"\(trimmed)\"",
                    subtitle: "Create a new note from the current query",
                    icon: "plus.circle.fill",
                    keywords: ["new", "create", "note", trimmed],
                    shortcutHint: nil,
                    target: .action(.createNote(trimmed))
                ),
                at: 0
            )
        }

        commands.append(contentsOf: context.nooks.map { nook in
            RemiCommand(
                id: "open-note-\(nook.id.uuidString)",
                title: nook.name,
                subtitle: nook.isPinned ? "Pinned note" : nook.tags.joined(separator: ", "),
                icon: nook.iconName,
                keywords: ["note", "open", nook.name] + nook.tags,
                shortcutHint: nil,
                target: .note(nook.id)
            )
        })

        return commands.filter { $0.matches(trimmed) }
    }

    func perform(_ command: RemiCommand, context: CommandContext) {
        switch command.target {
        case .note(let noteID):
            guard let nook = context.nooks.first(where: { $0.id == noteID }) else { return }
            context.openNote(nook)

        case .action(let action):
            switch action {
            case .createNote(let suggestedName):
                context.createNote(suggestedName?.isEmpty == false ? suggestedName! : "New Nook")

            case .renameCurrentNote:
                guard let current = context.currentNook else { return }
                context.editNote(current, .general)

            case .deleteCurrentNote:
                guard let current = context.currentNook else { return }
                context.deleteNote(current)

            case .togglePinCurrentNote:
                guard let current = context.currentNook else { return }
                context.togglePinned(current)

            case .changeCurrentNoteIcon:
                guard let current = context.currentNook else { return }
                context.editNote(current, .icon)

            case .changeCurrentNoteColor:
                guard let current = context.currentNook else { return }
                context.editNote(current, .color)

            case .editCurrentNoteTags:
                guard let current = context.currentNook else { return }
                context.editNote(current, .tags)

            case .openToday:
                context.openToday()

            case .openQuickCapture:
                context.openQuickCapture()

            case .openFocusWindow:
                context.openFocusWindow()

            case .pinCurrentNoteToDesktop:
                guard let current = context.currentNook else { return }
                context.pinCurrentNoteToDesktop(current)

            case .openSettings:
                context.openSettings()

            case .setTheme(let option):
                context.setTheme(option)

            case .applyAIPreset(let preset):
                context.applyAIPreset(preset)
            }
        }
    }

    private func baseCommands(context: CommandContext) -> [RemiCommand] {
        var commands: [RemiCommand] = [
            RemiCommand(
                id: "open-today",
                title: "Open Today",
                subtitle: "See pinned, recent, inbox, and pending AI notes",
                icon: "sun.max.fill",
                keywords: ["today", "recent", "pinned", "inbox"],
                shortcutHint: nil,
                target: .action(.openToday)
            ),
            RemiCommand(
                id: "quick-capture",
                title: "Quick Capture",
                subtitle: "Capture text into Remi without changing the current view",
                icon: "square.and.pencil",
                keywords: ["capture", "quick", "inbox", "panel"],
                shortcutHint: nil,
                target: .action(.openQuickCapture)
            ),
            RemiCommand(
                id: "create-note",
                title: "Create New Note",
                subtitle: "Add a fresh note to the strip",
                icon: "plus.circle.fill",
                keywords: ["create", "new", "note"],
                shortcutHint: nil,
                target: .action(.createNote(nil))
            ),
            RemiCommand(
                id: "open-focus-window",
                title: "Open Focus Window",
                subtitle: "Detach the current workspace into a wider window",
                icon: "macwindow",
                keywords: ["focus", "window", "detach"],
                shortcutHint: "Cmd-Shift-R",
                target: .action(.openFocusWindow)
            ),
            RemiCommand(
                id: "open-settings",
                title: "Open Settings",
                subtitle: "Configure models, prompts, and behavior",
                icon: "gearshape.fill",
                keywords: ["settings", "preferences"],
                shortcutHint: nil,
                target: .action(.openSettings)
            ),
            RemiCommand(
                id: "theme-dark",
                title: "Switch to Dark Theme",
                subtitle: "Use the dark appearance override",
                icon: "moon.fill",
                keywords: ["theme", "dark"],
                shortcutHint: nil,
                target: .action(.setTheme(.customDark))
            ),
            RemiCommand(
                id: "theme-light",
                title: "Switch to Light Theme",
                subtitle: "Use the light appearance override",
                icon: "sun.max.fill",
                keywords: ["theme", "light"],
                shortcutHint: nil,
                target: .action(.setTheme(.customLight))
            ),
            RemiCommand(
                id: "theme-system",
                title: "Use System Theme",
                subtitle: "Follow the macOS appearance",
                icon: "circle.lefthalf.filled",
                keywords: ["theme", "system"],
                shortcutHint: nil,
                target: .action(.setTheme(.system))
            )
        ]

        if context.currentNook != nil {
            commands.append(contentsOf: [
                RemiCommand(
                    id: "rename-current-note",
                    title: "Rename Current Note",
                    subtitle: "Edit the note name and details",
                    icon: "pencil",
                    keywords: ["rename", "title", "edit"],
                    shortcutHint: nil,
                    target: .action(.renameCurrentNote)
                ),
                RemiCommand(
                    id: "toggle-pin-current-note",
                    title: context.currentNook?.isPinned == true ? "Unpin Current Note" : "Pin Current Note",
                    subtitle: "Control whether the note stays in the Today pinned section",
                    icon: context.currentNook?.isPinned == true ? "pin.slash.fill" : "pin.fill",
                    keywords: ["pin", "unpin", "today"],
                    shortcutHint: nil,
                    target: .action(.togglePinCurrentNote)
                ),
                RemiCommand(
                    id: "change-current-note-icon",
                    title: "Change Current Note Icon",
                    subtitle: "Open note details focused on the icon picker",
                    icon: "sparkles.square.filled.on.square",
                    keywords: ["icon", "symbol"],
                    shortcutHint: nil,
                    target: .action(.changeCurrentNoteIcon)
                ),
                RemiCommand(
                    id: "change-current-note-color",
                    title: "Change Current Note Color",
                    subtitle: "Open note details focused on the color picker",
                    icon: "paintpalette.fill",
                    keywords: ["color", "accent"],
                    shortcutHint: nil,
                    target: .action(.changeCurrentNoteColor)
                ),
                RemiCommand(
                    id: "edit-current-note-tags",
                    title: "Edit Current Note Tags",
                    subtitle: "Open note details focused on tags",
                    icon: "tag.fill",
                    keywords: ["tag", "inbox", "metadata"],
                    shortcutHint: nil,
                    target: .action(.editCurrentNoteTags)
                ),
                RemiCommand(
                    id: "delete-current-note",
                    title: "Delete Current Note",
                    subtitle: "Remove the note and select the next available one",
                    icon: "trash.fill",
                    keywords: ["delete", "remove", "trash"],
                    shortcutHint: nil,
                    target: .action(.deleteCurrentNote)
                ),
                RemiCommand(
                    id: "pin-current-note-to-desktop",
                    title: "Pin Current Note to Desktop",
                    subtitle: "Toggle the current note as a sticky desktop surface",
                    icon: "pin.circle.fill",
                    keywords: ["desktop", "sticky", "pin"],
                    shortcutHint: nil,
                    target: .action(.pinCurrentNoteToDesktop)
                )
            ])
        }

        commands.append(contentsOf: context.quickActions.map { preset in
            RemiCommand(
                id: "ai-preset-\(preset.lowercased())",
                title: preset,
                subtitle: "Apply this AI rewrite preset to the current note",
                icon: "sparkles",
                keywords: ["ai", "rewrite", "preset", preset],
                shortcutHint: nil,
                target: .action(.applyAIPreset(preset))
            )
        })

        return commands
    }
}
