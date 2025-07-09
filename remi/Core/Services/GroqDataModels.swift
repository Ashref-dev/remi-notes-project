
import Foundation

// MARK: - Helper Structs for JSON Encoding
struct ChatMessage: Encodable {
    let role: String
    let content: String
}

struct ChatRequest: Encodable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let top_p: Double
    let stream: Bool
}

// MARK: - Helper Structs for JSON Decoding
struct ChatCompletionChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }
        let delta: Delta
    }
    let choices: [Choice]
}

// MARK: - Custom Errors
enum GroqError: Error, LocalizedError {
    case apiKeyMissing
    case invalidURL
    case requestFailed(statusCode: Int, description: String)
    case networkError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "The Groq API key is missing."
        case .invalidURL:
            return "The API endpoint URL is invalid."
        case .requestFailed(let statusCode, let description):
            if statusCode == 401 {
                return "Authentication failed. Please check your API key."
            }
            return "The request failed with status code \(statusCode): \(description)"
        case .networkError(let error):
            return "A network error occurred: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode the response: \(error.localizedDescription)"
        }
    }
}
