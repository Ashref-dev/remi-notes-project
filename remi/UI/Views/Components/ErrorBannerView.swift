import SwiftUI

struct ErrorBannerView: View {
    let error: AppError
    let onDismiss: () -> Void
    let onRetry: (() -> Void)?
    
    @State private var isVisible = false
    
    var body: some View {
        Themed { theme in
            HStack(spacing: 12) {
                // Error Icon
                Image(systemName: iconName)
                    .foregroundColor(iconColor(theme: theme))
                    .font(.system(size: 16, weight: .medium))
                
                VStack(alignment: .leading, spacing: 4) {
                    // Error Message
                    Text(error.message)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                    
                    // Timestamp (for debug/info)
                    if error.severity == .info || error.severity == .warning {
                        Text(timeAgoString)
                            .font(.system(size: 11))
                            .foregroundColor(theme.textSecondary)
                    }
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 8) {
                    // Retry Button
                    if error.canRetry, let onRetry = onRetry {
                        Button(action: onRetry) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .medium))
                                Text("Retry")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(theme.accent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(theme.accent.opacity(0.1))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    
                    // Dismiss Button
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(theme.textSecondary)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.escape, modifiers: [])
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(backgroundColor(theme: theme))
                    .stroke(borderColor(theme: theme), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 4,
                x: 0,
                y: 2
            )
            .scaleEffect(isVisible ? 1.0 : 0.95)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
            .onAppear {
                withAnimation {
                    isVisible = true
                }
            }
        }
    }
    
    private var iconName: String {
        switch error.severity {
        case .info:
            return "info.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .error:
            return "exclamationmark.circle.fill"
        case .critical:
            return "xmark.octagon.fill"
        }
    }
    
    private func iconColor(theme: Theme) -> Color {
        switch error.severity {
        case .info:
            return .blue
        case .warning:
            return .orange
        case .error:
            return .red
        case .critical:
            return .red
        }
    }
    
    private func backgroundColor(theme: Theme) -> Color {
        switch error.severity {
        case .info:
            return Color.blue.opacity(0.05)
        case .warning:
            return Color.orange.opacity(0.05)
        case .error:
            return Color.red.opacity(0.05)
        case .critical:
            return Color.red.opacity(0.1)
        }
    }
    
    private func borderColor(theme: Theme) -> Color {
        switch error.severity {
        case .info:
            return Color.blue.opacity(0.2)
        case .warning:
            return Color.orange.opacity(0.3)
        case .error:
            return Color.red.opacity(0.3)
        case .critical:
            return Color.red.opacity(0.4)
        }
    }
    
    private var timeAgoString: String {
        let interval = Date().timeIntervalSince(error.timestamp)
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

// MARK: - Error Banner Modifier
struct ErrorBannerModifier: ViewModifier {
    @ObservedObject private var errorService = ErrorHandlingService.shared
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            content
            
            if let error = errorService.currentError {
                VStack {
                    ErrorBannerView(
                        error: error,
                        onDismiss: {
                            errorService.clearError()
                        },
                        onRetry: error.canRetry ? {
                            errorService.retry()
                        } : nil
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    
                    Spacer()
                }
                .zIndex(1000)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: errorService.currentError != nil)
    }
}

extension View {
    func errorBanner() -> some View {
        modifier(ErrorBannerModifier())
    }
}

// MARK: - Preview
struct ErrorBannerView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            ErrorBannerView(
                error: AppError(message: "API key is missing. Please set it in Settings.", severity: .warning),
                onDismiss: {},
                onRetry: nil
            )
            
            ErrorBannerView(
                error: AppError(
                    message: "Network error occurred. Please check your connection.",
                    severity: .error,
                    canRetry: true,
                    retryAction: {}
                ),
                onDismiss: {},
                onRetry: {}
            )
            
            ErrorBannerView(
                error: AppError(message: "Rate limit exceeded. Please wait before trying again.", severity: .info),
                onDismiss: {},
                onRetry: nil
            )
            
            ErrorBannerView(
                error: AppError(message: "Critical system error occurred.", severity: .critical),
                onDismiss: {},
                onRetry: nil
            )
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
}
