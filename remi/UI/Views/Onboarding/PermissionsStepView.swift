import SwiftUI

struct PermissionsStepView: View {
    @ObservedObject var permissionsService: PermissionsService
    let theme: Theme
    @State private var isRequestingPermissions = false
    @State private var showingManualInstructions = false
    @State private var animateElements = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Header with smooth animation
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(theme.accent)
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.2), value: animateElements)
                
                Text("Quick Permissions")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(theme.textPrimary)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.4), value: animateElements)
                
                Text("Enable seamless background operation")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .offset(y: animateElements ? 0 : 20)
                    .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.6), value: animateElements)
            }
            
            Spacer(minLength: 20)
            
            // Compact Permission Cards
            VStack(spacing: 12) {
                CompactPermissionCard(
                    permission: .backgroundExecution,
                    permissionsService: permissionsService,
                    theme: theme,
                    delay: 0.8
                )
                
                CompactPermissionCard(
                    permission: .launchAtLogin,
                    permissionsService: permissionsService,
                    theme: theme,
                    delay: 1.0
                )
                
                CompactPermissionCard(
                    permission: .menuBarAccess,
                    permissionsService: permissionsService,
                    theme: theme,
                    delay: 1.2
                )
            }
            .opacity(animateElements ? 1.0 : 0.0)
            .offset(y: animateElements ? 0 : 30)
            .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(0.8), value: animateElements)
            
            Spacer(minLength: 20)
            
            // Action Section
            if allPermissionsGranted {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.green)
                    Text("Ready to go!")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    Capsule()
                        .fill(.green.opacity(0.1))
                        .stroke(.green.opacity(0.3), lineWidth: 1)
                )
                .scaleEffect(animateElements ? 1.0 : 0.8)
                .opacity(animateElements ? 1.0 : 0.0)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.4), value: animateElements)
            } else {
                VStack(spacing: 12) {
                    Button(action: {
                        isRequestingPermissions = true
                        Task {
                            await requestAllPermissions()
                            isRequestingPermissions = false
                        }
                    }) {
                        HStack(spacing: 6) {
                            if isRequestingPermissions {
                                ProgressView()
                                    .scaleEffect(0.7)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "shield.fill")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            Text(isRequestingPermissions ? "Requesting..." : "Grant All")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .frame(height: 44)
                        .frame(maxWidth: 200)
                        .background(theme.accent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                    }
                    .disabled(isRequestingPermissions || permissionsService.anyPermissionRequesting)
                    .scaleEffect(animateElements ? 1.0 : 0.8)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(1.4), value: animateElements)
                    
                    Button("Manual Setup") {
                        showingManualInstructions = true
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(theme.textSecondary)
                    .opacity(animateElements ? 1.0 : 0.0)
                    .animation(.easeOut(duration: 0.4).delay(1.6), value: animateElements)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
        .onAppear {
            animateElements = true
            Task {
                await permissionsService.checkAllPermissions()
            }
        }
        .onDisappear {
            animateElements = false
        }
        .sheet(isPresented: $showingManualInstructions) {
            ManualPermissionsInstructionsView(theme: theme)
        }
    }
    
    private var allPermissionsGranted: Bool {
        return permissionsService.allPermissionsGranted
    }
    
    private func requestAllPermissions() async {
        _ = await permissionsService.requestAllPermissions()
    }
}

struct CompactPermissionCard: View {
    let permission: OnboardingService.Permission
    @ObservedObject var permissionsService: PermissionsService
    let theme: Theme
    let delay: Double
    @State private var animate = false
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: permissionsService.getPermissionIcon(for: permission))
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(statusColor)
                .frame(width: 20, height: 20)
                .scaleEffect(animate ? 1.0 : 0.3)
                .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(delay), value: animate)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(permission.title)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(compactDescription)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            StatusIndicator(status: permissionsService.getPermissionStatus(for: permission))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(theme.cardBackground.opacity(0.8))
                .stroke(statusColor.opacity(0.2), lineWidth: 1)
        )
        .opacity(animate ? 1.0 : 0.0)
        .offset(x: animate ? 0 : 20)
        .animation(.spring(response: 0.8, dampingFraction: 0.8).delay(delay), value: animate)
        .onAppear {
            animate = true
        }
    }
    
    private var compactDescription: String {
        switch permission {
        case .backgroundExecution: return "Keep running in background"
        case .launchAtLogin: return "Start with macOS"
        case .menuBarAccess: return "Always accessible"
        }
    }
    
    private var statusColor: Color {
        let status = permissionsService.getPermissionStatus(for: permission)
        switch status {
        case .granted: return .green
        case .denied, .unknown: return theme.accent
        case .requesting: return .orange
        }
    }
    
    struct StatusIndicator: View {
        let status: PermissionsService.PermissionStatus
        
        var body: some View {
            Group {
                switch status {
                case .granted:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                case .requesting:
                    ProgressView()
                        .scaleEffect(0.7)
                        .progressViewStyle(CircularProgressViewStyle())
                case .denied, .unknown:
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                }
            }
            .font(.system(size: 16))
        }
    }
}

struct PermissionCard: View {
    let permission: OnboardingService.Permission
    @ObservedObject var permissionsService: PermissionsService
    let theme: Theme
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.medium) {
            Image(systemName: permissionsService.getPermissionIcon(for: permission))
                .font(.system(size: 24))
                .foregroundColor(theme.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(permissionsService.getPermissionDescription(for: permission))
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
            }
            
            Spacer()
            
            PermissionStatusIndicator(
                status: permissionsService.getPermissionStatus(for: permission),
                onRequest: {
                    Task {
                        await permissionsService.retryPermissionRequest(for: permission)
                    }
                },
                theme: theme
            )
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(theme.cardBackground)
                .stroke(statusBorderColor, lineWidth: 1)
        )
    }
    
    private var statusBorderColor: Color {
        let status = permissionsService.getPermissionStatus(for: permission)
        switch status {
        case .granted: return .green.opacity(0.3)
        case .denied: return .red.opacity(0.3)
        case .requesting: return .orange.opacity(0.3)
        case .unknown: return Color.clear
        }
    }
}

struct PermissionStatusIndicator: View {
    let status: PermissionsService.PermissionStatus
    let onRequest: () -> Void
    let theme: Theme
    
    var body: some View {
        switch status {
        case .unknown:
            Button("Grant") {
                onRequest()
            }
            .buttonStyle(SecondaryButtonStyle(theme: theme))
            
        case .requesting:
            HStack(spacing: 6) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .orange))
                    .scaleEffect(0.7)
                Text("Requesting...")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
        case .granted:
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Granted")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
        case .denied:
            Button("Retry") {
                onRequest()
            }
            .buttonStyle(SecondaryButtonStyle(theme: theme))
        }
    }
}

struct ManualPermissionsInstructionsView: View {
    let theme: Theme
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            HStack {
                Text("Manual Setup Instructions")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(PrimaryButtonStyle(theme: theme))
            }
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                InstructionStep(
                    number: 1,
                    title: "Background Execution",
                    description: "This is automatically configured. Remi runs as a menu bar app.",
                    theme: theme
                )
                
                InstructionStep(
                    number: 2,
                    title: "Launch at Login",
                    description: "Go to System Settings → General → Login Items and add Remi to the list.",
                    action: {
                        PermissionsService.shared.openLoginItemsPreferences()
                    },
                    actionTitle: "Open Settings",
                    theme: theme
                )
                
                InstructionStep(
                    number: 3,
                    title: "Menu Bar Access",
                    description: "This is automatically available. Look for Remi's icon in your menu bar.",
                    theme: theme
                )
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.xlarge)
        .frame(width: 500, height: 400)
        .background(theme.background)
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    let action: (() -> Void)?
    let actionTitle: String?
    let theme: Theme
    
    init(number: Int, title: String, description: String, action: (() -> Void)? = nil, actionTitle: String? = nil, theme: Theme) {
        self.number = number
        self.title = title
        self.description = description
        self.action = action
        self.actionTitle = actionTitle
        self.theme = theme
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            Text("\(number)")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(theme.accent))
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(theme.textSecondary)
                
                if let action = action, let actionTitle = actionTitle {
                    Button(actionTitle) {
                        action()
                    }
                    .buttonStyle(SecondaryButtonStyle(theme: theme))
                }
            }
        }
    }
}

struct PermissionsStepView_Previews: PreviewProvider {
    static var previews: some View {
        Themed { theme in
            PermissionsStepView(
                permissionsService: PermissionsService.shared,
                theme: theme
            )
        }
        .frame(width: 600, height: 500)
    }
}
