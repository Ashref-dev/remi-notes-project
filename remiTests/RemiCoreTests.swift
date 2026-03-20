import XCTest
@testable import remi

final class RemiCoreTests: XCTestCase {
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
            pendingAIProposal: PendingAIProposal(
                prompt: "Summarize",
                proposedText: "Draft",
                summary: "Summarize",
                createdAt: now
            ),
            updatedAt: now
        )

        let sections = TodayWorkspaceService.shared.sections(from: [noteA, noteB], now: now)
        XCTAssertTrue(sections.contains(where: { $0.kind == .pinned && $0.nooks.contains(noteA) }))
        XCTAssertTrue(sections.contains(where: { $0.kind == .inbox && $0.nooks.contains(noteA) }))
        XCTAssertTrue(sections.contains(where: { $0.kind == .pendingAI && $0.nooks.contains(noteB) }))
    }

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
}
