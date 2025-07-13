import Foundation
import Combine

@MainActor
class HealthCheckService: ObservableObject {
    static let shared = HealthCheckService()
    
    @Published var apiHealth: HealthStatus = .unknown
    @Published var networkHealth: HealthStatus = .unknown
    @Published var lastHealthCheck: Date?
    
    private var healthCheckTimer: Timer?
    private let groqService = GroqService.shared
    private let connectionService = ConnectionStatusService.shared
    
    enum HealthStatus {
        case unknown
        case healthy
        case degraded
        case unhealthy
        
        var color: Color {
            switch self {
            case .unknown: return .gray
            case .healthy: return .green
            case .degraded: return .orange
            case .unhealthy: return .red
            }
        }
        
        var description: String {
            switch self {
            case .unknown: return "Unknown"
            case .healthy: return "Healthy"
            case .degraded: return "Degraded"
            case .unhealthy: return "Unhealthy"
            }
        }
    }
    
    private init() {
        startPeriodicHealthChecks()
    }
    
    deinit {
        stopPeriodicHealthChecks()
    }
    
    private func startPeriodicHealthChecks() {
        // Check health every 5 minutes
        healthCheckTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
            Task {
                await self.performHealthCheck()
            }
        }
        
        // Initial health check
        Task {
            await performHealthCheck()
        }
    }
    
    private func stopPeriodicHealthChecks() {
        healthCheckTimer?.invalidate()
        healthCheckTimer = nil
    }
    
    func performHealthCheck() async {
        lastHealthCheck = Date()
        
        // Check network connectivity
        networkHealth = connectionService.isConnected ? .healthy : .unhealthy
        
        // Check API health if network is available
        if networkHealth == .healthy {
            await checkAPIHealth()
        } else {
            apiHealth = .unhealthy
        }
    }
    
    private func checkAPIHealth() async {
        do {
            try await groqService.testAPIKey()
            apiHealth = .healthy
        } catch {
            if let groqError = error as? GroqError {
                switch groqError {
                case .apiKeyMissing, .apiKeyInvalid:
                    apiHealth = .degraded
                case .rateLimitExceeded:
                    apiHealth = .degraded
                case .serverError, .modelUnavailable:
                    apiHealth = .degraded
                default:
                    apiHealth = .unhealthy
                }
            } else {
                apiHealth = .unhealthy
            }
        }
    }
    
    var overallHealth: HealthStatus {
        switch (networkHealth, apiHealth) {
        case (.healthy, .healthy): return .healthy
        case (.healthy, .degraded), (.degraded, _): return .degraded
        default: return .unhealthy
        }
    }
    
    var healthSummary: String {
        switch overallHealth {
        case .healthy:
            return "All systems operational"
        case .degraded:
            return "Some features may be limited"
        case .unhealthy:
            return "Service unavailable"
        case .unknown:
            return "Checking system status..."
        }
    }
}

extension Color {
    static let systemGreen = Color.green
    static let systemOrange = Color.orange
    static let systemRed = Color.red
    static let systemGray = Color.gray
}
