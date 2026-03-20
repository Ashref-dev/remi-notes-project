import Foundation

final class OpenRouterClient: LLMClient {
    static let shared = OpenRouterClient()

    private let chatEndpoint = "https://openrouter.ai/api/v1/chat/completions"
    private let modelsEndpoint = "https://openrouter.ai/api/v1/models"
    
    private let localChatEndpoint = "http://localhost:1234/v1/chat/completions"
    private let localModelsEndpoint = "http://localhost:1234/v1/models"

    private init() {}

    private var apiKey: String {
        SettingsManager.shared.llmAPIKey
    }

    private func validateAPIKeyFormat() throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw LLMError.apiKeyMissing
        }
    }

    private func removeThinkingTags(from text: String) -> String {
        var cleaned = text
        while let startRange = cleaned.range(of: "<thinking>", options: .caseInsensitive),
              let endRange = cleaned.range(of: "</thinking>", options: .caseInsensitive, range: startRange.upperBound..<cleaned.endIndex) {
            cleaned.removeSubrange(startRange.lowerBound..<endRange.upperBound)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func sendEdit(prompt: String, context: String, model: String, params: ModelParameters) async throws -> String {
        let isLocal = model == "local"
        let targetEndpoint = isLocal ? localChatEndpoint : chatEndpoint
        let url = try createURL(from: targetEndpoint)

        if !isLocal { try validateAPIKeyFormat() }

        let systemPrompt = SettingsManager.shared.aiSystemPrompt

        let userMessage = """
        Current document:

        \(context)

        User request: \(prompt)

        Return the complete improved document.
        """

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": params.temperature,
            "max_tokens": params.maxTokens,
            "top_p": params.topP,
            "frequency_penalty": params.frequencyPenalty,
            "presence_penalty": params.presencePenalty,
            "stream": false
        ]

        var request = createURLRequest(url: url, isLocal: isLocal, timeout: isLocal ? 120 : 40)
        request.httpMethod = "POST"

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw LLMError.networkError(error)
        }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        switch httpResponse.statusCode {
        case 200...299:
            break
        case 401:
            throw LLMError.requestFailed(statusCode: 401, description: "Invalid API key")
        case 429:
            throw LLMError.rateLimitExceeded
        case 500...599:
            throw LLMError.serverError
        default:
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode, description: "Request failed")
        }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any] else {
                throw LLMError.decodingError(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to parse response"]))
            }

            if let content = message["content"] as? String {
                return removeThinkingTags(from: content)
            }

            if let contentParts = message["content"] as? [[String: Any]] {
                let text = contentParts.compactMap { $0["text"] as? String }.joined(separator: "\n")
                if !text.isEmpty {
                    return removeThinkingTags(from: text)
                }
            }

            throw LLMError.decodingError(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "No response content"]))
        } catch let error as LLMError {
            throw error
        } catch {
            throw LLMError.decodingError(error)
        }
    }

    func validateAPIKey() async throws {
        try validateAPIKeyFormat()
        let url = try createURL(from: modelsEndpoint)

        var request = createURLRequest(url: url, isLocal: false, timeout: 15)
        request.httpMethod = "GET"

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMError.networkError(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }

        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401, 403:
            throw LLMError.apiKeyInvalid
        case 429:
            throw LLMError.rateLimitExceeded
        case 500...599:
            throw LLMError.serverError
        default:
            throw LLMError.requestFailed(statusCode: httpResponse.statusCode, description: "Validation failed")
        }
    }

    // MARK: - Helpers

    private func createURL(from endpoint: String) throws -> URL {
        guard let url = URL(string: endpoint) else {
            throw LLMError.invalidURL
        }
        return url
    }

    private func createURLRequest(url: URL, isLocal: Bool, timeout: TimeInterval) -> URLRequest {
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = timeout
        
        if !isLocal {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.setValue("https://github.com/ashref/remi", forHTTPHeaderField: "HTTP-Referer")
            request.setValue("Remi", forHTTPHeaderField: "X-Title")
        }
        return request
    }
}
