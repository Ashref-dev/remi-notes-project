import XCTest
@testable import remi

final class RemiCoreTests: XCTestCase {
    func testLibraryTransferServiceRoundTripsArchive() throws {
        let now = Date()
        let settings = LibraryTransferSettings(
            colorSchemeOptionRawValue: ColorThemeOption.customDark.rawValue,
            aboutMeContext: "Writes concise product notes.",
            selectedModelId: "openrouter/auto",
            modelParameters: ModelParameters(temperature: 0.35, maxTokens: 2048, topP: 0.9, frequencyPenalty: 0.0, presencePenalty: 0.0),
            aiSystemPrompt: "Be concise.",
            aiQuickActions: ["Summarize", "Clarify"],
            ambientSuggestionsEnabled: true,
            captureDefaultRoute: .createInboxNote,
            historyRetentionDays: 30,
            historyMaxRevisions: 50
        )
        let note = ArchivedNote(
            id: UUID(),
            name: "Imported",
            content: "Body",
            iconName: "heart.fill",
            iconColorRawValue: NookIconColor.pink.rawValue,
            order: 2,
            hasBeenAutoTitled: true,
            createdAt: now,
            updatedAt: now,
            lastOpenedAt: now,
            isPinned: true,
            tags: [Nook.inboxTag, "Ideas"],
            captureSource: .quickCapture,
            pendingAIProposal: PendingAIProposal(
                prompt: "Rewrite",
                proposedText: "Updated body",
                summary: "Improve clarity",
                createdAt: now
            )
        )

        let data = try LibraryTransferService.shared.exportData(notes: [note], settings: settings)
        let archive = try LibraryTransferService.shared.importArchive(from: data)

        XCTAssertEqual(archive.version, RemiLibraryArchive.currentVersion)
        XCTAssertEqual(archive.settings, settings)
        let importedNote = try XCTUnwrap(archive.notes.first)
        XCTAssertEqual(importedNote.id, note.id)
        XCTAssertEqual(importedNote.name, note.name)
        XCTAssertEqual(importedNote.content, note.content)
        XCTAssertEqual(importedNote.iconName, note.iconName)
        XCTAssertEqual(importedNote.iconColorRawValue, note.iconColorRawValue)
        XCTAssertEqual(importedNote.order, note.order)
        XCTAssertEqual(importedNote.hasBeenAutoTitled, note.hasBeenAutoTitled)
        XCTAssertEqual(importedNote.isPinned, note.isPinned)
        XCTAssertEqual(importedNote.tags, note.tags)
        XCTAssertEqual(importedNote.captureSource, note.captureSource)
        XCTAssertEqual(importedNote.pendingAIProposal?.prompt, note.pendingAIProposal?.prompt)
        XCTAssertEqual(importedNote.pendingAIProposal?.proposedText, note.pendingAIProposal?.proposedText)
        XCTAssertEqual(importedNote.pendingAIProposal?.summary, note.pendingAIProposal?.summary)
        XCTAssertEqual(importedNote.createdAt.timeIntervalSince1970, note.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(importedNote.updatedAt.timeIntervalSince1970, note.updatedAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertEqual(
            try XCTUnwrap(importedNote.lastOpenedAt).timeIntervalSince1970,
            try XCTUnwrap(note.lastOpenedAt).timeIntervalSince1970,
            accuracy: 0.001
        )
        XCTAssertEqual(
            try XCTUnwrap(importedNote.pendingAIProposal).createdAt.timeIntervalSince1970,
            try XCTUnwrap(note.pendingAIProposal).createdAt.timeIntervalSince1970,
            accuracy: 0.001
        )
    }

    func testTodayWorkspaceSectionsIncludePinnedInboxAndPendingAI() {
        let now = Date()
        let noteA = makeNook(
            name: "Pinned",
            isPinned: true,
            tags: [Nook.inboxTag],
            updatedAt: now,
            lastOpenedAt: now
        )
        let noteB = makeNook(
            name: "Pending",
            updatedAt: now,
            pendingAIProposal: PendingAIProposal(
                prompt: "Summarize",
                proposedText: "Draft",
                summary: "Summarize",
                createdAt: now
            )
        )

        let sections = TodayWorkspaceService.shared.sections(from: [noteA, noteB], now: now)
        XCTAssertTrue(sections.contains(where: { $0.kind == TodaySectionKind.pinned && $0.nooks.contains(noteA) }))
        XCTAssertTrue(sections.contains(where: { $0.kind == TodaySectionKind.inbox && $0.nooks.contains(noteA) }))
        XCTAssertTrue(sections.contains(where: { $0.kind == TodaySectionKind.pendingAI && $0.nooks.contains(noteB) }))
    }

    @MainActor
    func testCommandRouterIncludesCoreActionsAndPreset() {
        let current = makeNook(name: "Current")
        let context = CommandContext(
            currentNook: current,
            nooks: [current],
            quickActions: ["Summarize this"],
            openNote: { _ in },
            createNote: { _ in },
            deleteNote: { _ in },
            togglePinned: { _ in },
            editNote: { _, _ in },
            openToday: {},
            openQuickCapture: {},
            openFocusWindow: {},
            pinCurrentNoteToDesktop: { _ in },
            openSettings: {},
            setTheme: { _ in },
            applyAIPreset: { _ in }
        )

        let commands = CommandRouter.shared.commands(matching: "", context: context)
        XCTAssertTrue(commands.contains(where: { $0.id == "open-today" }))
        XCTAssertTrue(commands.contains(where: { $0.id == "quick-capture" }))
        XCTAssertTrue(commands.contains(where: { $0.title == "Summarize this" }))
    }

    func testSuggestionDismissalSuppressesUntilFingerprintChanges() async {
        let service = SuggestionService()
        let note = makeNook(name: "Meeting Notes")
        let content = "Meeting agenda\n- [ ] Ship version two\n- [ ] Review roadmap"

        let first = await service.suggestion(for: note, content: content)
        XCTAssertNotNil(first)

        service.dismiss(for: note, content: content)
        let second = await service.suggestion(for: note, content: content)
        XCTAssertNil(second)

        let third = await service.suggestion(for: note, content: content + "\nAdditional change")
        XCTAssertNotNil(third)
    }

    func testHistoryServiceRecordsAndRestoresRevision() throws {
        let service = NoteHistoryService.shared
        let note = makeNook(name: "History Note")
        let content = "Version one"

        let revision = try XCTUnwrap(service.recordRevision(for: note, content: content, source: .automatic))
        let restored = try service.restoreRevision(revision)

        XCTAssertEqual(restored, content)
        XCTAssertTrue(service.fetchRevisions(for: note.id).contains(revision))
    }

    func testNookManagerImportsExportedLibraryArchivePreservingMetadataAndContent() throws {
        let destinationDirectory = makeTemporaryPath()
        defer {
            try? FileManager.default.removeItem(at: destinationDirectory)
        }

        let now = Date()
        let importedProposal = PendingAIProposal(
            prompt: "Turn into checklist",
            proposedText: "- [ ] One\n- [ ] Two",
            summary: "Checklist",
            createdAt: now
        )
        let archivedNotes = [
            ArchivedNote(
                id: UUID(),
                name: "Project Inbox",
                content: "Capture this first.",
                iconName: "tray.full.fill",
                iconColorRawValue: NookIconColor.orange.rawValue,
                order: 0,
                hasBeenAutoTitled: true,
                createdAt: now,
                updatedAt: now,
                lastOpenedAt: now,
                isPinned: true,
                tags: [Nook.inboxTag, "Work"],
                captureSource: .quickCapture,
                pendingAIProposal: importedProposal
            ),
            ArchivedNote(
                id: UUID(),
                name: "Reference",
                content: "Second body\n\nUpdated",
                iconName: "books.vertical.fill",
                iconColorRawValue: NookIconColor.teal.rawValue,
                order: 1,
                hasBeenAutoTitled: true,
                createdAt: now,
                updatedAt: now,
                lastOpenedAt: nil,
                isPinned: false,
                tags: ["Docs"],
                captureSource: .manual,
                pendingAIProposal: nil
            )
        ]
        let firstNote = archivedNotes[0]

        let settings = LibraryTransferSettings(
            colorSchemeOptionRawValue: ColorThemeOption.customLight.rawValue,
            aboutMeContext: "Portable context",
            selectedModelId: "openrouter/auto",
            modelParameters: ModelParameters(temperature: 0.2, maxTokens: 4096, topP: 0.9, frequencyPenalty: 0.0, presencePenalty: 0.0),
            aiSystemPrompt: "Keep notes tidy.",
            aiQuickActions: ["Summarize"],
            ambientSuggestionsEnabled: false,
            captureDefaultRoute: .appendToCurrentNote,
            historyRetentionDays: 14,
            historyMaxRevisions: 25
        )
        let archiveData = try LibraryTransferService.shared.exportData(notes: archivedNotes, settings: settings)

        let destinationManager = NookManager(nooksDirectory: destinationDirectory, seedWelcomeNoteIfNeeded: false)
        let archive = try destinationManager.importLibraryArchive(archiveData)
        let importedNooks = destinationManager.fetchNooks()

        XCTAssertEqual(archive.settings, settings)
        XCTAssertEqual(importedNooks.count, 2)
        XCTAssertEqual(importedNooks.map(\.name), ["Project Inbox", "Reference"])

        let importedFirst = try XCTUnwrap(importedNooks.first(where: { $0.name == "Project Inbox" }))
        XCTAssertTrue(importedFirst.isPinned)
        XCTAssertEqual(importedFirst.tags, [Nook.inboxTag, "Work"])
        XCTAssertEqual(importedFirst.captureSource, .quickCapture)
        let importedFirstProposal = try XCTUnwrap(importedFirst.pendingAIProposal)
        XCTAssertEqual(importedFirstProposal.prompt, importedProposal.prompt)
        XCTAssertEqual(importedFirstProposal.proposedText, importedProposal.proposedText)
        XCTAssertEqual(importedFirstProposal.summary, importedProposal.summary)
        XCTAssertEqual(importedFirstProposal.createdAt.timeIntervalSince1970, importedProposal.createdAt.timeIntervalSince1970, accuracy: 0.001)
        XCTAssertNotNil(importedFirst.lastOpenedAt)
        XCTAssertEqual(destinationManager.fetchTasks(for: importedFirst), "Capture this first.")

        let importedSecond = try XCTUnwrap(importedNooks.first(where: { $0.name == "Reference" }))
        XCTAssertEqual(importedSecond.iconName, "books.vertical.fill")
        XCTAssertEqual(importedSecond.iconColor, .teal)
        XCTAssertEqual(destinationManager.fetchTasks(for: importedSecond), "Second body\n\nUpdated")
        XCTAssertEqual(importedFirst.id, firstNote.id)

        let reexportedData = try destinationManager.exportLibraryArchive(settings: settings)
        let reexportedArchive = try LibraryTransferService.shared.importArchive(from: reexportedData)
        XCTAssertEqual(reexportedArchive.notes.count, 2)
    }

    private func makeNook(
        name: String,
        isPinned: Bool = false,
        tags: [String] = [],
        updatedAt: Date = Date(),
        lastOpenedAt: Date? = nil,
        pendingAIProposal: PendingAIProposal? = nil
    ) -> Nook {
        Nook(
            name: name,
            url: URL(fileURLWithPath: "/tmp/\(UUID().uuidString)"),
            iconName: "doc.text.fill",
            iconColor: .blue,
            order: 0,
            hasBeenAutoTitled: true,
            createdAt: updatedAt,
            updatedAt: updatedAt,
            lastOpenedAt: lastOpenedAt,
            isPinned: isPinned,
            tags: tags,
            captureSource: .manual,
            pendingAIProposal: pendingAIProposal
        )
    }

    private func makeTemporaryPath() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
