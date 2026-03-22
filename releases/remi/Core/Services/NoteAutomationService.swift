import Foundation

enum NoteAutomationError: LocalizedError {
    case missingCurrentNote
    case emptyPreset
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .missingCurrentNote:
            return "There is no active note to edit."
        case .emptyPreset:
            return "The preset cannot be empty."
        case .saveFailed:
            return "Remi could not save the AI proposal."
        }
    }
}

final class NoteAutomationService {
    static let shared = NoteAutomationService()

    private let nookManager = NookManager.shared
    private let llmClient: LLMClient

    init(llmClient: LLMClient = OpenRouterClient.shared) {
        self.llmClient = llmClient
    }

    func applyPresetToCurrentNote(_ preset: String) async throws -> Nook {
        let trimmedPreset = preset.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPreset.isEmpty else {
            throw NoteAutomationError.emptyPreset
        }

        guard let currentURL = SettingsManager.shared.lastViewedNookURL(),
              let currentNook = nookManager.fetchNook(for: currentURL) else {
            throw NoteAutomationError.missingCurrentNote
        }

        let content = nookManager.fetchTasks(for: currentNook)
        let improvedContent = try await llmClient.sendEdit(
            prompt: trimmedPreset,
            context: content,
            model: SettingsManager.shared.selectedModelId,
            params: SettingsManager.shared.modelParameters
        )

        let proposal = PendingAIProposal(
            prompt: trimmedPreset,
            proposedText: improvedContent,
            summary: String(trimmedPreset.prefix(80)),
            createdAt: Date()
        )

        guard let saved = nookManager.setPendingAIProposal(proposal, for: currentNook) else {
            throw NoteAutomationError.saveFailed
        }

        NotificationCenter.default.post(name: .nooksDidChange, object: nil)
        return saved
    }
}
