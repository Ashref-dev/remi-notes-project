import Foundation

class GroqService {
    static let shared = GroqService()
    private let endpoint = "https://api.groq.com/openai/v1/chat/completions"
    
    private var apiKey: String {
        return SettingsManager.shared.groqAPIKey
    }
    
    private var currentModel: GroqModel {
        return SettingsManager.shared.getCurrentModel()
    }
    
    private var modelParameters: ModelParameters {
        return SettingsManager.shared.modelParameters
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
        You are a concise note-taking assistant. Always respond in plain text format unless specifically requested otherwise.

        Guidelines:
        - Be brief and direct in your responses
        - Use bullet points instead of tables when listing information
        - Organize content with clear headings and subheadings
        - Avoid unnecessary formatting like tables, code blocks, or markdown
        - Focus on actionable, well-structured plain text
        - Fix grammar and improve clarity while maintaining the original intent
        - Keep responses concise and to the point

        Return ONLY the improved content without explanations or meta-commentary.
        """
        
        let userMessage = """
        Current document:
        
        \(context)
        
        User request: \(prompt)
        
        Please return the complete, improved document.
        """
        
        let payload: [String: Any] = [
            "model": currentModel.id,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ],
            "temperature": modelParameters.temperature,
            "max_tokens": min(modelParameters.maxTokens, currentModel.contextLength / 2),
            "top_p": modelParameters.topP,
            "frequency_penalty": modelParameters.frequencyPenalty,
            "presence_penalty": modelParameters.presencePenalty,
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
    
    // Test model performance and response quality
    func testModel(_ model: GroqModel, parameters: ModelParameters) async throws -> ModelTestResult {
        try validateAPIKey()
        
        let startTime = Date()
        let testPrompt = "Fix any grammar issues in this text: 'The quick brown fox jumps over the lazy dog. This is a test sentence for AI model evaluation.'"
        let testContext = "The quick brown fox jumps over the lazy dog. This is a test sentence for AI model evaluation."
        
        // Temporarily override settings for test
        let originalModel = SettingsManager.shared.selectedGroqModel
        let originalParameters = SettingsManager.shared.modelParameters
        
        SettingsManager.shared.selectedGroqModel = model.id
        SettingsManager.shared.modelParameters = parameters
        
        defer {
            // Restore original settings
            SettingsManager.shared.selectedGroqModel = originalModel
            SettingsManager.shared.modelParameters = originalParameters
        }
        
        do {
            let response = try await processQuery(prompt: testPrompt, context: testContext)
            let responseTime = Date().timeIntervalSince(startTime)
            
            return ModelTestResult(
                model: model,
                parameters: parameters,
                responseTime: responseTime,
                responseLength: response.count,
                success: true,
                error: nil
            )
        } catch {
            let responseTime = Date().timeIntervalSince(startTime)
            return ModelTestResult(
                model: model,
                parameters: parameters,
                responseTime: responseTime,
                responseLength: 0,
                success: false,
                error: error.localizedDescription
            )
        }
    }
}

// MARK: - Model Test Result
struct ModelTestResult {
    let model: GroqModel
    let parameters: ModelParameters
    let responseTime: TimeInterval
    let responseLength: Int
    let success: Bool
    let error: String?
    
    var performanceScore: Double {
        guard success else { return 0.0 }
        
        // Score based on response time and quality indicators
        let speedScore = max(0, 10 - responseTime) / 10 // Faster = better
        let lengthScore = Double(min(responseLength / 100, 5)) / 5 // Reasonable length
        
        return (speedScore + lengthScore) / 2
    }
    
    var performanceGrade: String {
        let score = performanceScore
        if score >= 0.8 { return "Excellent" }
        else if score >= 0.6 { return "Good" }
        else if score >= 0.4 { return "Fair" }
        else { return "Poor" }
    }
}
