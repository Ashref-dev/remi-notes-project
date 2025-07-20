import Foundation

class GroqService {
    static let shared = GroqService()
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    
    private var apiKey: String {
        return SettingsManager.shared.groqAPIKey
    }
    
    private var isAPIKeyValid: Bool {
        let key = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }

    private init() {}
    
    private func validateAPIKey() throws {
        guard !apiKey.isEmpty else {
            throw GroqError.apiKeyMissing
        }
        
        guard isAPIKeyValid else {
            throw GroqError.apiKeyInvalid
        }
    }

    // Simple, direct thinking tag removal
    private func removeThinkingTags(from text: String) -> String {
        var cleaned = text
        
        // Remove thinking tags - simple and reliable
        while let startRange = cleaned.range(of: "<thinking>", options: .caseInsensitive),
              let endRange = cleaned.range(of: "</thinking>", options: .caseInsensitive, range: startRange.upperBound..<cleaned.endIndex) {
            let fullRange = startRange.lowerBound..<endRange.upperBound
            cleaned.removeSubrange(fullRange)
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    
    // Simple, focused AI query - gets response and applies it directly
    func processQuery(prompt: String, context: String) async throws -> String {
        try validateAPIKey()
        
        guard let url = URL(string: endpoint) else {
            throw GroqError.invalidURL
        }
        
        let systemPrompt = """
        You are a helpful note-taking assistant. Improve the user's notes by:
        1. Fixing typos and grammar
        2. Improving clarity and organization
        3. Adding proper Markdown formatting
        4. Making content more actionable
        
        Return ONLY the complete, improved document. Do not add explanations or comments.
        Use <thinking></thinking> tags to plan your approach, but these will be removed from the final output.
        """
        
        let userMessage = """
        Current document:
        
        \(context)
        
        User request: \(prompt)
        
        Please return the complete, improved document.
        """
        
        let payload: [String: Any] = [
            "model": "meta-llama/llama-4-scout-17b-16e-instruct",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": 0.3,
            "max_tokens": 4000,
            "stream": false
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 30
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            throw GroqError.networkError(error)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.networkError(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        // Handle HTTP errors
        switch httpResponse.statusCode {
        case 200...299:
            break // Success
        case 401:
            throw GroqError.requestFailed(statusCode: 401, description: "Invalid API key")
        case 429:
            throw GroqError.rateLimitExceeded
        case 500...599:
            throw GroqError.serverError
        default:
            throw GroqError.requestFailed(statusCode: httpResponse.statusCode, description: "Request failed")
        }
        
        // Parse response
        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let choices = json["choices"] as? [[String: Any]],
                  let firstChoice = choices.first,
                  let message = firstChoice["message"] as? [String: Any],
                  let content = message["content"] as? String else {
                throw GroqError.networkError(NSError(domain: "ParseError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unable to parse response"]))
            }
            
            // Remove thinking tags and return clean content
            return removeThinkingTags(from: content)
            
        } catch {
            throw GroqError.networkError(error)
        }
    }
    
    // Test API key validity
    func testAPIKey() async throws {
        try validateAPIKey()
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else {
            throw GroqError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GroqError.networkError(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return // Success
        case 401:
            throw GroqError.requestFailed(statusCode: 401, description: "Invalid API key")
        case 403:
            throw GroqError.requestFailed(statusCode: 403, description: "API key lacks permissions")
        case 429:
            throw GroqError.rateLimitExceeded
        case 500...599:
            throw GroqError.serverError
        default:
            throw GroqError.requestFailed(statusCode: httpResponse.statusCode, description: "Request failed")
        }
    }
}
