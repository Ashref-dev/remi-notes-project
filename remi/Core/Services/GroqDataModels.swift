
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
    case apiKeyInvalid
    case invalidURL
    case requestFailed(statusCode: Int, description: String)
    case networkError(Error)
    case decodingError(Error)
    case rateLimitExceeded
    case serverError
    case timeoutError
    case noInternetConnection
    case apiQuotaExceeded
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .apiKeyMissing:
            return "Please set your Groq API key in Settings to use AI features."
        case .apiKeyInvalid:
            return "Your Groq API key appears to be invalid. Please check it in Settings."
        case .invalidURL:
            return "The API endpoint URL is invalid."
        case .requestFailed(let statusCode, _):
            switch statusCode {
            case 400:
                return "Bad request. Please check your input and try again."
            case 401:
                return "Authentication failed. Please verify your API key in Settings."
            case 403:
                return "Access forbidden. Your API key may not have the required permissions."
            case 404:
                return "The requested resource was not found."
            case 429:
                return "Rate limit exceeded. Please wait a moment before trying again."
            case 500...599:
                return "Server error. Please try again later."
            default:
                return "Request failed with status code \(statusCode). Please try again."
            }
        case .networkError(let error):
            if error.localizedDescription.contains("not connected to the internet") ||
               error.localizedDescription.contains("network connection") {
                return "No internet connection. Please check your network and try again."
            }
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to process the response from the AI service."
        case .rateLimitExceeded:
            return "Rate limit exceeded. Please wait a moment before trying again."
        case .serverError:
            return "The AI service is currently unavailable. Please try again later."
        case .timeoutError:
            return "Request timed out. Please check your connection and try again."
        case .noInternetConnection:
            return "No internet connection. Please check your network and try again."
        case .apiQuotaExceeded:
            return "API quota exceeded. Please check your Groq account limits."
        case .modelUnavailable:
            return "The AI model is currently unavailable. Please try again later."
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .apiKeyMissing, .apiKeyInvalid, .invalidURL, .apiQuotaExceeded:
            return false
        case .networkError, .timeoutError, .noInternetConnection, .serverError, .rateLimitExceeded, .modelUnavailable:
            return true
        case .requestFailed(let statusCode, _):
            return statusCode >= 500 || statusCode == 429
        case .decodingError:
            return true
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .apiKeyMissing, .apiKeyInvalid:
            return .warning
        case .rateLimitExceeded:
            return .info
        case .networkError, .timeoutError, .noInternetConnection:
            return .warning
        case .serverError, .modelUnavailable:
            return .error
        case .apiQuotaExceeded:
            return .critical
        default:
            return .error
        }
    }
}
