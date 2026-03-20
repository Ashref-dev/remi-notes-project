import Foundation
import SwiftUI
import Combine
import AppKit

@MainActor
final class TaskEditorViewModel: ObservableObject {
    @Published var nook: Nook
    @Published var taskContent: String = ""
    @Published var isProcessingAI: Bool = false
    @Published var showSaveConfirmation: Bool = false
    @Published var showAIDiff: Bool = false
    @Published var aiDiffOriginalText: String = ""
    @Published var aiDiffProposedText: String = ""
    @Published var showCopySuccess: Bool = false
    @Published var ambientSuggestion: AmbientSuggestion?
    @Published var revisions: [NoteRevision] = []

    private let nookManager = NookManager.shared
    private let llmClient: LLMClient
    private let noteTitleService: NoteTitleService
    private let historyService: NoteHistoryService
    private let suggestionService: SuggestionService
    private var cancellables = Set<AnyCancellable>()
    private var saveQueue = DispatchQueue(label: "save-queue", qos: .utility)
    private var suggestionTask: Task<Void, Never>?
    private var lastAutomaticRevisionDate: Date?
    private var lastAutomaticRevisionFingerprint = ""

    var textViewUndoManager: UndoManager?
    weak var textView: NSTextView?

    init(
        nook: Nook,
        llmClient: LLMClient = OpenRouterClient.shared,
        noteTitleService: NoteTitleService = .shared,
        historyService: NoteHistoryService = .shared,
        suggestionService: SuggestionService = .shared
    ) {
        self.nook = nook
        self.llmClient = llmClient
        self.noteTitleService = noteTitleService
        self.historyService = historyService
        self.suggestionService = suggestionService
        self.taskContent = nookManager.fetchTasks(for: nook)

        createContentBackup()
        revisions = historyService.fetchRevisions(for: nook.id)

        $taskContent
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .dropFirst()
            .sink { [weak self] content in
                self?.saveContent(content)
            }
            .store(in: &cancellables)

        $taskContent
            .debounce(for: .seconds(3.0), scheduler: RunLoop.main)
            .dropFirst()
            .sink { [weak self] content in
                Task { await self?.checkAndTriggerAutoTitle(for: content) }
            }
            .store(in: &cancellables)

        $taskContent
            .debounce(for: .seconds(0.9), scheduler: RunLoop.main)
            .dropFirst()
            .sink { [weak self] content in
                self?.scheduleSuggestionRefresh(for: content)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in
                self?.forceSave()
            }
            .store(in: &cancellables)

        showPendingAIProposalIfAvailable()
        scheduleSuggestionRefresh(for: taskContent)
    }

    enum CopyFormat {
        case markdown
        case plainText
    }

    func forceSave() {
        nookManager.saveTasks(for: nook, content: taskContent)
        revisions = historyService.fetchRevisions(for: nook.id)
    }

    func prepareForNookSwitch() {
        forceSave()
    }

    func processAIQuery(prompt: String) async {
        guard !isProcessingAI else { return }

        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }

        isProcessingAI = true
        let originalContent = taskContent
        createContentBackup()

        do {
            let improvedContent = try await llmClient.sendEdit(
                prompt: trimmedPrompt,
                context: originalContent,
                model: SettingsManager.shared.selectedModelId,
                params: SettingsManager.shared.modelParameters
            )

            guard improvedContent != originalContent else {
                isProcessingAI = false
                return
            }

            let proposal = PendingAIProposal(
                prompt: trimmedPrompt,
                proposedText: improvedContent,
                summary: String(trimmedPrompt.prefix(80)),
                createdAt: Date()
            )
            if let updatedNook = nookManager.setPendingAIProposal(proposal, for: nook) {
                nook = updatedNook
            }

            aiDiffOriginalText = originalContent
            aiDiffProposedText = improvedContent
            showAIDiff = true
            HapticsService.shared.perform(.aiApplied)
            NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        } catch {
            let llmError = error as? LLMError
            let errorMessage = llmError?.errorDescription ?? "AI request failed"

            ErrorHandlingService.shared.showError(
                message: errorMessage,
                severity: llmError?.severity ?? .error,
                canRetry: llmError?.canRetry ?? true,
                retryAction: { [weak self] in
                    Task { await self?.processAIQuery(prompt: trimmedPrompt) }
                }
            )

            replaceWholeDocumentUsingNativeUndo(to: originalContent, actionName: "AI Enhancement")
        }

        isProcessingAI = false
    }

    func applyPreset(_ preset: String) {
        Task { await processAIQuery(prompt: preset) }
    }

    func reviewPendingAIDraft() {
        showPendingAIProposalIfAvailable(force: true)
    }

    func dismissAmbientSuggestion() {
        suggestionService.dismiss(for: nook, content: taskContent)
        ambientSuggestion = nil
    }

    func applyAmbientSuggestion() {
        guard let ambientSuggestion else { return }
        if nook.hasPendingAIWork, showAIDiff == false {
            reviewPendingAIDraft()
            return
        }

        Task { await processAIQuery(prompt: ambientSuggestion.prompt) }
    }

    func loadRevisions() {
        revisions = historyService.fetchRevisions(for: nook.id)
    }

    func restore(_ revision: NoteRevision) {
        do {
            let currentContent = taskContent
            historyService.recordRevision(
                for: nook,
                content: currentContent,
                source: .restore,
                summary: "Before restore"
            )
            let restoredContent = try historyService.restoreRevision(revision)
            replaceWholeDocumentUsingNativeUndo(to: restoredContent, actionName: "Restore Revision")
            loadRevisions()
            HapticsService.shared.perform(.historyRestored)
        } catch {
            ErrorHandlingService.shared.showError(
                message: "Failed to restore that revision.",
                severity: .error
            )
        }
    }

    func replaceNookContent(with newContent: String, actionName: String = "Content Replacement") {
        guard newContent != taskContent else { return }
        historyService.recordRevision(for: nook, content: taskContent, source: .contentReplacement)
        createContentBackup()
        replaceWholeDocumentUsingNativeUndo(to: newContent, actionName: actionName)
        loadRevisions()
    }

    func enhanceContent(with enhancement: String, actionName: String = "Content Enhancement") {
        createContentBackup()
        let enhancedContent = taskContent + "\n\n" + enhancement
        replaceNookContent(with: enhancedContent, actionName: actionName)
    }

    func formatContent(with formatter: (String) -> String, actionName: String) {
        let formattedContent = formatter(taskContent)
        guard formattedContent != taskContent else { return }
        replaceNookContent(with: formattedContent, actionName: actionName)
    }

    func acceptAIDiff() {
        guard showAIDiff else { return }
        historyService.recordRevision(
            for: nook,
            content: aiDiffOriginalText,
            source: .aiProposal,
            summary: "Before AI apply"
        )
        replaceWholeDocumentUsingNativeUndo(to: aiDiffProposedText, actionName: "AI Enhancement")
        clearPendingAIDiffState()
        loadRevisions()
        scheduleSuggestionRefresh(for: taskContent)
    }

    func rejectAIDiff() {
        guard showAIDiff else { return }
        clearPendingAIDiffState()
        scheduleSuggestionRefresh(for: taskContent)
    }

    func copyAllContent(format: CopyFormat = .markdown) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        let contentToCopy: String
        switch format {
        case .markdown:
            contentToCopy = taskContent
        case .plainText:
            contentToCopy = stripMarkdownFormatting(from: taskContent)
        }

        pasteboard.setString(contentToCopy, forType: .string)

        withAnimation(.easeInOut(duration: 0.3)) {
            showCopySuccess = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showCopySuccess = false
            }
        }
    }

    func copySmartSelection(format: CopyFormat = .markdown) {
        copyAllContent(format: format)
    }

    private func saveContent(_ content: String) {
        let targetNook = nook
        let contentToSave = content
        recordAutomaticHistoryRevisionIfNeeded(for: contentToSave)

        saveQueue.async { [weak self, targetNook] in
            NookManager.shared.saveTasks(for: targetNook, content: contentToSave)

            DispatchQueue.main.async {
                guard let self else { return }
                self.showSaveConfirmation = true
                self.loadRevisions()

                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    self.showSaveConfirmation = false
                }
            }
        }
    }

    private func recordAutomaticHistoryRevisionIfNeeded(for content: String) {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 80 else { return }

        let fingerprint = String(trimmed.prefix(400))
        let now = Date()
        if let lastAutomaticRevisionDate,
           now.timeIntervalSince(lastAutomaticRevisionDate) < 300,
           fingerprint == lastAutomaticRevisionFingerprint {
            return
        }

        historyService.recordRevision(
            for: nook,
            content: trimmed,
            source: .automatic,
            summary: "Automatic snapshot"
        )
        lastAutomaticRevisionDate = now
        lastAutomaticRevisionFingerprint = fingerprint
    }

    private func checkAndTriggerAutoTitle(for content: String) async {
        guard !nook.hasBeenAutoTitled,
              content.trimmingCharacters(in: .whitespacesAndNewlines).count > 10 else {
            return
        }

        let suggestion = await noteTitleService.suggestTitle(for: content)
        var updatedNook = nook
        updatedNook.name = suggestion.title
        updatedNook.iconName = suggestion.iconName
        updatedNook.iconColor = suggestion.iconColor
        updatedNook.hasBeenAutoTitled = true

        if let saved = nookManager.updateNook(updatedNook) {
            nook = saved
            NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        }
    }

    private func scheduleSuggestionRefresh(for content: String) {
        suggestionTask?.cancel()
        suggestionTask = Task { [weak self] in
            guard let self else { return }
            let suggestion = await self.suggestionService.suggestion(for: self.nook, content: content)
            guard !Task.isCancelled else { return }
            self.ambientSuggestion = suggestion
        }
    }

    private func showPendingAIProposalIfAvailable(force: Bool = false) {
        guard let pendingProposal = nook.pendingAIProposal else { return }
        guard force || showAIDiff == false else { return }
        aiDiffOriginalText = taskContent
        aiDiffProposedText = pendingProposal.proposedText
        showAIDiff = force
    }

    private func clearPendingAIDiffState() {
        showAIDiff = false
        aiDiffOriginalText = ""
        aiDiffProposedText = ""
        if let updatedNook = nookManager.clearPendingAIProposal(for: nook) {
            nook = updatedNook
        }
        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
    }

    private func replaceWholeDocumentUsingNativeUndo(to newContent: String, actionName: String) {
        guard let textView else {
            taskContent = newContent
            return
        }

        let fullRange = NSRange(location: 0, length: (textView.string as NSString).length)
        if let undoManager = textView.undoManager {
            undoManager.beginUndoGrouping()
            undoManager.setActionName(actionName)
        }
        if textView.shouldChangeText(in: fullRange, replacementString: newContent) {
            textView.textStorage?.replaceCharacters(in: fullRange, with: newContent)
            textView.didChangeText()
        }
        textView.undoManager?.endUndoGrouping()
        taskContent = newContent
    }

    private func createContentBackup() {
        let backup = taskContent
        UserDefaults.standard.set(backup, forKey: "emergencyBackup_\(nook.id.uuidString)")
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "emergencyBackupTime_\(nook.id.uuidString)")
    }

    private func stripMarkdownFormatting(from text: String) -> String {
        var plainText = text
        plainText = plainText.replacingOccurrences(of: #"^#{1,6}\s+"#, with: "", options: [.regularExpression])
        plainText = plainText.replacingOccurrences(of: #"\*{1,2}([^*]+)\*{1,2}"#, with: "$1", options: .regularExpression)
        plainText = plainText.replacingOccurrences(of: #"`([^`]+)`"#, with: "$1", options: .regularExpression)
        plainText = plainText.replacingOccurrences(of: #"\[([^\]]+)\]\([^)]+\)"#, with: "$1", options: .regularExpression)
        plainText = plainText.replacingOccurrences(of: #"^[-*+]\s*\[[x\s]\]\s*"#, with: "", options: [.regularExpression])
        plainText = plainText.replacingOccurrences(of: #"^[-*+]\s+"#, with: "", options: [.regularExpression])
        return plainText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
