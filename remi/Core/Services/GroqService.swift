import Foundation
import Alamofire

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

    private init() {
        // API key is now managed by SettingsManager
    }
    
    private func validateAPIKey() throws {
        guard !apiKey.isEmpty else {
            throw GroqError.apiKeyMissing
        }
        
        guard isAPIKeyValid else {
            throw GroqError.apiKeyInvalid
        }
    }

    private func filterThinking(from text: String) -> String {
        let pattern = "<thinking>.*?</thinking>"
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .dotMatchesLineSeparators)
            let range = NSRange(text.startIndex..., in: text)
            return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
        } catch {
            return text
        }
    }

    func streamQuery(prompt: String, context: String) -> AsyncThrowingStream<String, Error> {
        return AsyncThrowingStream { continuation in
            // Validate API key first
            do {
                try validateAPIKey()
            } catch {
                continuation.finish(throwing: error)
                return
            }
            
            guard let _ = URL(string: endpoint) else {
                continuation.finish(throwing: GroqError.invalidURL)
                return
            }

            let headers: HTTPHeaders = [
                "Authorization": "Bearer \(apiKey)",
                "Content-Type": "application/json"
            ]

            let userPrompt = """
            ## CURRENT DOCUMENT:
            ---
            \(context)
            ---

            ## USER REQUEST:
            ---
            \(prompt)
            ---
            """
            
            let systemMessage = """
            You are a silent, efficient document editor. Your purpose is to take a document and a user request, and then return the complete, updated document as plain text.

            RULES:
            1.  **Analyze the Request:** Understand the user's request in the context of the current document.
            2.  **Think Step-by-Step:** Before writing the response, use `<thinking>` tags to outline your plan. This is for your internal process and will be filtered out by the application. For example: `<thinking>The user wants to add a new task. I will append it to the end of the list.</thinking>`.
            3.  **Return the ENTIRE Document:** Your final output must be ONLY the complete, updated plain text of the document. Do NOT use Markdown. Do NOT include any commentary, explanations, or apologies.
            """

            let messages = [
                ChatMessage(role: "system", content: systemMessage),
                ChatMessage(role: "user", content: userPrompt)
            ]

            let parameters = ChatRequest(
                model: "meta-llama/llama-4-scout-17b-16e-instruct",
                messages: messages,
                temperature: 0.5,
                top_p: 0.95,
                stream: true
            )

            let request = AF.streamRequest(endpoint, method: .post, parameters: parameters, encoder: .json, headers: headers)
                .validate() // Validates that status codes are in 200..<300 range
                .responseStreamString { stream in
                    switch stream.event {
                    case .stream(let result):
                        switch result {
                        case .success(let string):
                            let chunks = string.components(separatedBy: "data: ").filter { !$0.isEmpty }
                            for chunk in chunks {
                                if chunk.contains("[DONE]") {
                                    continuation.finish()
                                    return
                                }
                                if let data = chunk.data(using: .utf8) {
                                    do {
                                        let decoded = try JSONDecoder().decode(ChatCompletionChunk.self, from: data)
                                        if var content = decoded.choices.first?.delta.content {
                                            content = self.filterThinking(from: content)
                                            if !content.isEmpty {
                                                continuation.yield(content)
                                            }
                                        }
                                    } catch {
                                        // Ignore decoding errors for partial data, but log them in debug builds
                                        #if DEBUG
                                        print("Decoding error for chunk: \(chunk), error: \(error)")
                                        #endif
                                    }
                                }
                            }
                        case .failure(let error):
                            continuation.finish(throwing: self.mapAFError(error))
                        }
                    case .complete(let completion):
                        if let error = completion.error {
                            continuation.finish(throwing: self.mapAFError(error))
                        } else {
                            continuation.finish()
                        }
                    }
                }

            continuation.onTermination = { @Sendable _ in
                request.cancel()
            }
        }
    }
    
    private func mapAFError(_ error: Error) -> GroqError {
        if let afError = error.asAFError {
            switch afError {
            case .responseValidationFailed(reason: .unacceptableStatusCode(code: let statusCode)):
                return .requestFailed(statusCode: statusCode, description: "Request failed with status \(statusCode)")
            case .sessionTaskFailed(error: let underlyingError):
                if underlyingError.localizedDescription.contains("Internet connection appears to be offline") ||
                   underlyingError.localizedDescription.contains("network connection") {
                    return .noInternetConnection
                }
                if underlyingError.localizedDescription.contains("timeout") {
                    return .timeoutError
                }
                return .networkError(underlyingError)
            default:
                if let statusCode = afError.responseCode {
                    switch statusCode {
                    case 429:
                        return .rateLimitExceeded
                    case 500...599:
                        return .serverError
                    default:
                        return .requestFailed(statusCode: statusCode, description: afError.errorDescription ?? "Unknown error")
                    }
                }
                return .networkError(afError)
            }
        }
        return .networkError(error)
    }
    
    // Test API key validity with a simple models endpoint call
    func testAPIKey() async throws {
        try validateAPIKey()
        
        guard let url = URL(string: "https://api.groq.com/openai/v1/models") else {
            throw GroqError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10 // 10 second timeout
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GroqError.networkError(NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"]))
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                // Success - API key is valid
                return
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
        } catch {
            if error is GroqError {
                throw error
            }
            
            // Handle URLSession errors
            let nsError = error as NSError
            if nsError.domain == NSURLErrorDomain {
                switch nsError.code {
                case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost:
                    throw GroqError.noInternetConnection
                case NSURLErrorTimedOut:
                    throw GroqError.timeoutError
                default:
                    throw GroqError.networkError(error)
                }
            }
            
            throw GroqError.networkError(error)
        }
    }
}
