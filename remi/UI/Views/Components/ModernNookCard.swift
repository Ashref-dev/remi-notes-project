import SwiftUI

struct ModernNookCard: View {
    let nook: Nook
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    @State private var scale: CGFloat = 1.0
    @State private var glowOpacity: Double = 0.0
    
    private func preview(for nook: Nook) -> String {
        let content = NookManager.shared.fetchTasks(for: nook)
        return content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
    }
    
    private var taskCount: Int {
        let content = NookManager.shared.fetchTasks(for: nook)
        let tasks = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : max(1, tasks.count)
    }

    var body: some View {
        Themed { theme in
            Button(action: onTap) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    // Icon with subtle animation
                    ZStack {
                        Circle()
                            .fill(isSelected ? theme.accent.opacity(0.2) : theme.textSecondary.opacity(0.1))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                    }
                    .scaleEffect(isHovering ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isHovering)

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                        HStack {
                            Text(nook.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Task count badge
                            if taskCount > 0 {
                                Text("\(taskCount)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(isSelected ? theme.accent.opacity(0.2) : theme.textSecondary.opacity(0.15))
                                    )
                            }
                        }
                        
                        if !preview(for: nook).isEmpty {
                            Text(preview(for: nook))
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        } else {
                            Text("Empty nook")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary.opacity(0.6))
                                .italic()
                        }
                    }
                    
                    Spacer()
                }
                .padding(AppTheme.Spacing.medium)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(cardBackgroundColor(theme: theme))
                .cornerRadius(AppTheme.CornerRadius.medium)
                .scaleEffect(scale)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            isSelected ? theme.accent.opacity(0.5) : Color.clear,
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: theme.accent.opacity(glowOpacity),
                    radius: isSelected ? 12 : 6,
                    x: 0,
                    y: isSelected ? 4 : 2
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                    scale = hovering ? 1.02 : 1.0
                    glowOpacity = hovering ? 0.3 : (isSelected ? 0.2 : 0.0)
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
            .onAppear {
                if isSelected {
                    glowOpacity = 0.2
                }
            }
        }
    }
    
    private func cardBackgroundColor(theme: Theme) -> Color {
        if isSelected {
            return theme.cardBackgroundSelected
        } else if isHovering {
            return theme.cardBackgroundHover
        } else {
            return theme.cardBackground
        }
    }
}
