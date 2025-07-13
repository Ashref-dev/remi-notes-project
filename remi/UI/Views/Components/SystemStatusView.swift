import SwiftUI

struct SystemStatusView: View {
    @ObservedObject private var healthService = HealthCheckService.shared
    @ObservedObject private var connectionService = ConnectionStatusService.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var errorService = ErrorHandlingService.shared
    
    @State private var isRefreshing = false
    
    var body: some View {
        Themed { theme in
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("System Status")
                        .font(.headline)
                        .foregroundColor(theme.primaryText)
                    
                    Spacer()
                    
                    Button(action: refreshStatus) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(theme.accent)
                            .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                            .animation(.linear(duration: 1).repeatCount(isRefreshing ? 5 : 0, autoreverses: false), value: isRefreshing)
                    }
                    .buttonStyle(.plain)
                    .disabled(isRefreshing)
                }
                
                // Overall Status
                StatusCard(
                    title: "Overall Health",
                    status: healthService.overallHealth.description,
                    statusColor: healthService.overallHealth.color,
                    description: healthService.healthSummary,
                    icon: "heart.fill",
                    theme: theme
                )
                
                // Individual Components
                VStack(spacing: 8) {
                    // Network Status
                    StatusRow(
                        title: "Network Connection",
                        status: connectionService.isConnected ? "Connected" : "Disconnected",
                        statusColor: connectionService.isConnected ? .green : .red,
                        detail: connectionService.connectionDescription,
                        icon: connectionService.isConnected ? "wifi" : "wifi.slash",
                        theme: theme
                    )
                    
                    // API Configuration
                    StatusRow(
                        title: "API Configuration",
                        status: isAPIKeyConfigured ? "Configured" : "Not Configured",
                        statusColor: isAPIKeyConfigured ? .green : .orange,
                        detail: isAPIKeyConfigured ? "Groq API key is set" : "API key required for AI features",
                        icon: isAPIKeyConfigured ? "key.fill" : "key.slash",
                        theme: theme
                    )
                    
                    // API Health
                    if isAPIKeyConfigured {
                        StatusRow(
                            title: "API Service",
                            status: healthService.apiHealth.description,
                            statusColor: healthService.apiHealth.color,
                            detail: apiHealthDetail,
                            icon: "server.rack",
                            theme: theme
                        )
                    }
                    
                    // Error History
                    if !errorService.errorHistory.isEmpty {
                        StatusRow(
                            title: "Recent Issues",
                            status: "\(errorService.errorHistory.count) errors",
                            statusColor: .orange,
                            detail: "Tap to view error history",
                            icon: "exclamationmark.triangle",
                            theme: theme,
                            action: {
                                // Could expand to show error history
                            }
                        )
                    }
                }
                
                // Last Updated
                if let lastCheck = healthService.lastHealthCheck {
                    HStack {
                        Text("Last updated: \(timeAgoString(from: lastCheck))")
                            .font(.caption)
                            .foregroundColor(theme.secondaryText)
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            Task {
                await healthService.performHealthCheck()
            }
        }
    }
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    private var apiHealthDetail: String {
        switch healthService.apiHealth {
        case .healthy:
            return "API is responding normally"
        case .degraded:
            return "API has some limitations"
        case .unhealthy:
            return "API is not accessible"
        case .unknown:
            return "Checking API status..."
        }
    }
    
    private func refreshStatus() {
        isRefreshing = true
        Task {
            await healthService.performHealthCheck()
            try? await Task.sleep(nanoseconds: 500_000_000) // Brief delay for UX
            isRefreshing = false
        }
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        }
    }
}

struct StatusCard: View {
    let title: String
    let status: String
    let statusColor: Color
    let description: String
    let icon: String
    let theme: Theme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(theme.primaryText)
                
                Text(status)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(statusColor)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(statusColor.opacity(0.05))
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
    }
}

struct StatusRow: View {
    let title: String
    let status: String
    let statusColor: Color
    let detail: String
    let icon: String
    let theme: Theme
    let action: (() -> Void)?
    
    init(title: String, status: String, statusColor: Color, detail: String, icon: String, theme: Theme, action: (() -> Void)? = nil) {
        self.title = title
        self.status = status
        self.statusColor = statusColor
        self.detail = detail
        self.icon = icon
        self.theme = theme
        self.action = action
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(statusColor)
                    .frame(width: 20)
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(title)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(theme.primaryText)
                        
                        Spacer()
                        
                        Text(status)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(statusColor)
                    }
                    
                    Text(detail)
                        .font(.system(size: 11))
                        .foregroundColor(theme.secondaryText)
                        .lineLimit(1)
                }
                
                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(theme.secondaryText)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.clear)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

struct SystemStatusView_Previews: PreviewProvider {
    static var previews: some View {
        SystemStatusView()
            .frame(width: 400, height: 500)
    }
}
