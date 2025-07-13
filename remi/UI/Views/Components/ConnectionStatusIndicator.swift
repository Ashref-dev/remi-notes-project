import SwiftUI

struct ConnectionStatusIndicator: View {
    @ObservedObject private var connectionStatus = ConnectionStatusService.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    private var statusColor: Color {
        if !connectionStatus.isConnected {
            return .red
        } else if !isAPIKeyConfigured {
            return .orange
        } else {
            return .green
        }
    }
    
    private var statusIcon: String {
        if !connectionStatus.isConnected {
            return "wifi.slash"
        } else if !isAPIKeyConfigured {
            return "key.slash"
        } else {
            return "checkmark.circle.fill"
        }
    }
    
    private var statusMessage: String {
        if !connectionStatus.isConnected {
            return "No Internet Connection"
        } else if !isAPIKeyConfigured {
            return "API Key Required"
        } else {
            return "Ready for AI"
        }
    }
    
    var body: some View {
        Themed { theme in
            HStack(spacing: 6) {
                Image(systemName: statusIcon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(statusColor)
                
                Text(statusMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.secondaryText)
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(statusColor.opacity(0.1))
                    .stroke(statusColor.opacity(0.3), lineWidth: 0.5)
            )
        }
    }
}

// Mini version for compact spaces
struct ConnectionStatusDot: View {
    @ObservedObject private var connectionStatus = ConnectionStatusService.shared
    @ObservedObject private var settingsManager = SettingsManager.shared
    
    private var isAPIKeyConfigured: Bool {
        let key = settingsManager.groqAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return !key.isEmpty && key.starts(with: "gsk_") && key.count > 20
    }
    
    private var statusColor: Color {
        if !connectionStatus.isConnected {
            return .red
        } else if !isAPIKeyConfigured {
            return .orange
        } else {
            return .green
        }
    }
    
    var body: some View {
        Circle()
            .fill(statusColor)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    .scaleEffect(1.5)
            )
    }
}

struct ConnectionStatusIndicator_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ConnectionStatusIndicator()
            ConnectionStatusDot()
        }
        .padding()
    }
}
