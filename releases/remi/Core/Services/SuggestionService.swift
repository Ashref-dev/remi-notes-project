import Foundation

struct AmbientSuggestion: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let systemImage: String
    let prompt: String
}

private struct SuggestionCandidate {
    let suggestion: AmbientSuggestion
    let confidence: Double
}

final class SuggestionService {
    static let shared = SuggestionService()

    private enum Keys {
        static let dismissedFingerprints = "ambientSuggestionDismissals"
    }

    private let llmClient: LLMClient

    init(llmClient: LLMClient = OpenRouterClient.shared) {
        self.llmClient = llmClient
    }

    func suggestion(for nook: Nook, content: String) async -> AmbientSuggestion? {
        guard SettingsManager.shared.ambientSuggestionsEnabled else { return nil }

        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let fingerprint = contentFingerprint(for: trimmed)
        if dismissedFingerprints()[nook.id.uuidString] == fingerprint {
            return nil
        }

        guard let candidate = localCandidate(for: nook, content: trimmed) else {
            return nil
        }

        guard SettingsManager.shared.isAPIKeyConfigured(), candidate.confidence >= 0.9 else {
            return candidate.suggestion
        }

        let refined = await refine(candidate: candidate, content: trimmed)
        return refined ?? candidate.suggestion
    }

    func dismiss(for nook: Nook, content: String) {
        var map = dismissedFingerprints()
        map[nook.id.uuidString] = contentFingerprint(for: content)
        UserDefaults.standard.set(map, forKey: Keys.dismissedFingerprints)
    }

    private func localCandidate(for nook: Nook, content: String) -> SuggestionCandidate? {
        let lowercased = content.lowercased()
        let lines = content.components(separatedBy: .newlines)
        let paragraphCount = lines.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        if nook.hasPendingAIWork {
            return SuggestionCandidate(
                suggestion: AmbientSuggestion(
                    id: "\(nook.id.uuidString)-pending-ai",
                    title: "Review AI draft",
                    subtitle: "There is an unapplied AI proposal for this note.",
                    systemImage: "sparkles",
                    prompt: nook.pendingAIProposal?.prompt ?? "Review the pending AI draft."
                ),
                confidence: 1.0
            )
        }

        if lowercased.contains("meeting") || lowercased.contains("agenda") || lowercased.contains("action item") {
            return SuggestionCandidate(
                suggestion: AmbientSuggestion(
                    id: "\(nook.id.uuidString)-meeting",
                    title: "Extract actions",
                    subtitle: "Turn this note into decisions and next steps.",
                    systemImage: "list.bullet.clipboard",
                    prompt: "Turn this into a clean set of decisions, owners, and next steps."
                ),
                confidence: 0.95
            )
        }

        if lowercased.contains("- [ ]") || lowercased.contains("todo") || lowercased.contains("to do") {
            return SuggestionCandidate(
                suggestion: AmbientSuggestion(
                    id: "\(nook.id.uuidString)-tasks",
                    title: "Tighten tasks",
                    subtitle: "Normalize this into a short, consistent task list.",
                    systemImage: "checklist",
                    prompt: "Rewrite this as a concise, consistent checklist with one action per line."
                ),
                confidence: 0.92
            )
        }

        if content.count > 900 {
            return SuggestionCandidate(
                suggestion: AmbientSuggestion(
                    id: "\(nook.id.uuidString)-summary",
                    title: "Summarize note",
                    subtitle: "This note is long enough to benefit from compression.",
                    systemImage: "text.alignleft",
                    prompt: "Summarize the main points clearly while preserving key details."
                ),
                confidence: 0.91
            )
        }

        let hasBullets = lowercased.contains("- ") || lowercased.contains("* ")
        if paragraphCount >= 4 && !hasBullets {
            return SuggestionCandidate(
                suggestion: AmbientSuggestion(
                    id: "\(nook.id.uuidString)-bullets",
                    title: "Add structure",
                    subtitle: "Break dense paragraphs into scan-friendly bullets.",
                    systemImage: "list.bullet",
                    prompt: "Reformat this into short bullet points with clear grouping."
                ),
                confidence: 0.88
            )
        }

        if content.count > 260 {
            return SuggestionCandidate(
                suggestion: AmbientSuggestion(
                    id: "\(nook.id.uuidString)-clarity",
                    title: "Improve clarity",
                    subtitle: "Tighten wording without changing intent.",
                    systemImage: "wand.and.stars",
                    prompt: "Improve clarity, tighten wording, and preserve the original meaning."
                ),
                confidence: 0.82
            )
        }

        return nil
    }

    private func refine(candidate: SuggestionCandidate, content: String) async -> AmbientSuggestion? {
        let prompt = """
        You are refining a single edit suggestion for a note.

        Current suggestion:
        title: \(candidate.suggestion.title)
        subtitle: \(candidate.suggestion.subtitle)
        prompt: \(candidate.suggestion.prompt)

        Return exactly:
        title | subtitle | prompt

        Keep the title under 3 words.
        Keep the subtitle under 12 words.
        Keep the prompt under 18 words.

        Note excerpt:
        \(String(content.prefix(500)))
        """

        do {
            let response = try await llmClient.sendEdit(
                prompt: prompt,
                context: "",
                model: SettingsManager.shared.selectedModelId,
                params: SettingsManager.shared.modelParameters
            )
            let parts = response
                .components(separatedBy: "|")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            guard parts.count >= 3 else { return nil }
            return AmbientSuggestion(
                id: candidate.suggestion.id,
                title: parts[0].isEmpty ? candidate.suggestion.title : parts[0],
                subtitle: parts[1].isEmpty ? candidate.suggestion.subtitle : parts[1],
                systemImage: candidate.suggestion.systemImage,
                prompt: parts[2].isEmpty ? candidate.suggestion.prompt : parts[2]
            )
        } catch {
            return nil
        }
    }

    private func dismissedFingerprints() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: Keys.dismissedFingerprints) as? [String: String] ?? [:]
    }

    private func contentFingerprint(for content: String) -> String {
        String(content.lowercased().prefix(600)).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
