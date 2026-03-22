import Foundation

struct NoteTitleSuggestion: Hashable {
    let title: String
    let iconName: String
    let iconColor: NookIconColor
}

final class NoteTitleService {
    static let shared = NoteTitleService()

    private let llmClient: LLMClient

    init(llmClient: LLMClient = OpenRouterClient.shared) {
        self.llmClient = llmClient
    }

    func suggestTitle(for content: String) async -> NoteTitleSuggestion {
        let localSuggestion = localSuggestion(for: content)
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)

        guard SettingsManager.shared.isAPIKeyConfigured(), trimmed.count > 24 else {
            return localSuggestion
        }

        let prompt = """
        You create a very short title and choose an SF Symbol and color for a macOS notes app.

        Rules:
        1. Title must be 1 to 3 words.
        2. Symbol must be one of: doc.text.fill, paintbrush.fill, briefcase.fill, brain.head.profile, leaf.fill, heart.fill, star.fill, lightbulb.fill, message.fill, calendar
        3. Color must be one of: blue, purple, pink, red, orange, yellow, green, teal, indigo, gray
        4. Respond exactly as: symbol | color | title

        Note:
        \(String(trimmed.prefix(700)))
        """

        do {
            let response = try await llmClient.sendEdit(
                prompt: prompt,
                context: "",
                model: SettingsManager.shared.selectedModelId,
                params: SettingsManager.shared.modelParameters
            )
            if let parsed = parseSuggestion(from: response) {
                return parsed
            }
        } catch {
            return localSuggestion
        }

        return localSuggestion
    }

    private func parseSuggestion(from response: String) -> NoteTitleSuggestion? {
        let parts = response
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count >= 3 else { return nil }

        let iconName = parts[0]
        let colorName = parts[1].lowercased()
        let title = parts[2]

        guard !title.isEmpty,
              NookIcons.allIcons.contains(iconName),
              let iconColor = NookIconColor(rawValue: colorName) else {
            return nil
        }

        return NoteTitleSuggestion(title: title, iconName: iconName, iconColor: iconColor)
    }

    private func localSuggestion(for content: String) -> NoteTitleSuggestion {
        let normalized = content
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty } ?? "New Note"

        let stripped = normalized
            .replacingOccurrences(of: #"^#+\s*"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"^[\-\*\d\.\)\s]+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let words = stripped
            .split(whereSeparator: { $0.isWhitespace || $0.isNewline })
            .prefix(3)
            .map(String.init)
        let title = words.isEmpty ? "New Note" : words.joined(separator: " ")

        let lowercased = content.lowercased()
        if lowercased.contains("meeting") || lowercased.contains("agenda") {
            return NoteTitleSuggestion(title: title, iconName: "calendar", iconColor: .orange)
        }
        if lowercased.contains("idea") || lowercased.contains("brainstorm") {
            return NoteTitleSuggestion(title: title, iconName: "lightbulb.fill", iconColor: .yellow)
        }
        if lowercased.contains("project") || lowercased.contains("launch") || lowercased.contains("roadmap") {
            return NoteTitleSuggestion(title: title, iconName: "briefcase.fill", iconColor: .indigo)
        }
        if lowercased.contains("journal") || lowercased.contains("gratitude") || lowercased.contains("personal") {
            return NoteTitleSuggestion(title: title, iconName: "heart.fill", iconColor: .pink)
        }
        if lowercased.contains("research") || lowercased.contains("study") || lowercased.contains("learn") {
            return NoteTitleSuggestion(title: title, iconName: "brain.head.profile", iconColor: .blue)
        }

        return NoteTitleSuggestion(title: title, iconName: "doc.text.fill", iconColor: .blue)
    }
}
