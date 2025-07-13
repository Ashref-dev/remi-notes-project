import Foundation

@MainActor
class RetryService {
    static let shared = RetryService()
    
    private init() {}
    
    /// Executes an async operation with exponential backoff retry logic
    /// - Parameters:
    ///   - maxRetries: Maximum number of retry attempts
    ///   - baseDelay: Base delay in seconds before first retry
    ///   - maxDelay: Maximum delay cap in seconds
    ///   - retryCondition: Closure to determine if the error should trigger a retry
    ///   - operation: The async operation to execute
    /// - Returns: The result of the operation
    func execute<T>(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 30.0,
        retryCondition: @escaping (Error) -> Bool = { _ in true },
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on the last attempt or if retry condition fails
                if attempt == maxRetries || !retryCondition(error) {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                let delay = min(baseDelay * pow(2.0, Double(attempt)), maxDelay)
                
                // Add some jitter to avoid thundering herd
                let jitter = Double.random(in: 0.8...1.2)
                let finalDelay = delay * jitter
                
                try await Task.sleep(nanoseconds: UInt64(finalDelay * 1_000_000_000))
            }
        }
        
        throw lastError ?? NSError(domain: "RetryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown retry error"])
    }
    
    /// Determines if a GroqError should be retried
    static func shouldRetryGroqError(_ error: Error) -> Bool {
        guard let groqError = error as? GroqError else {
            return false
        }
        
        return groqError.canRetry
    }
    
    /// Determines if any network-related error should be retried
    static func shouldRetryNetworkError(_ error: Error) -> Bool {
        if let groqError = error as? GroqError {
            return shouldRetryGroqError(groqError)
        }
        
        // Handle NSURLError cases
        if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorTimedOut,
                 NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorDNSLookupFailed:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}
