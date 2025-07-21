    import SwiftUI

struct ModernNookCard: View {
    let nook: Nook
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: ((Nook) -> Void)?
    
    @State private var isHovering = false
    @State private var showingEditSheet = false
    @State private var editableNook: Nook
    
    init(nook: Nook, isSelected: Bool, onTap: @escaping () -> Void, onEdit: ((Nook) -> Void)? = nil) {
        self.nook = nook
        self.isSelected = isSelected
        self.onTap = onTap
        self.onEdit = onEdit
        self._editableNook = State(initialValue: nook)
    }
    
    private func preview(for nook: Nook) -> String {
        let content = NookManager.shared.fetchTasks(for: nook)
        return content.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "\n", with: " ")
    }
    
    private var taskCount: Int {
        let content = NookManager.shared.fetchTasks(for: nook)
        let tasks = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        return content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0 : max(1, tasks.count)
    }
    
    // Pre-computed colors to avoid flickering - Apple-like design
    private func cardBackgroundColor(theme: Theme) -> Color {
        if isSelected {
            return nook.iconColor.color.opacity(0.12)
        } else if isHovering {
            // Slightly darker gray for hover
            return Color(NSColor.controlBackgroundColor).opacity(0.9)
        } else {
            // Light gray background by default for better visibility
            return Color(NSColor.controlBackgroundColor).opacity(0.6)
        }
    }
    
    private func shadowColor(theme: Theme) -> Color {
        if isSelected {
            return nook.iconColor.color.opacity(0.25)
        } else if isHovering {
            return nook.iconColor.color.opacity(0.15)
        } else {
            return nook.iconColor.color.opacity(0.05)
        }
    }

    var body: some View {
        Themed { theme in
            Button(action: onTap) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    // Icon with modern hover animation
                    ZStack {
                        Circle()
                            .fill(nook.iconColor.color.opacity(isSelected ? 0.25 : (isHovering ? 0.2 : 0.15)))
                            .frame(width: 32, height: 32)
                            .scaleEffect(isHovering ? 1.05 : 1.0)
                        
                        Image(systemName: nook.iconName)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(nook.iconColor.color.opacity(isHovering ? 0.9 : 0.8))
                            .scaleEffect(isHovering ? 1.08 : 1.0)
                    }

                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                        HStack {
                            Text(nook.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            // Edit button (always reserve space to prevent shifting)
                            if onEdit != nil {
                                Button(action: { showingEditSheet = true }) {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 10, weight: .medium))
                                        .foregroundColor(theme.textSecondary)
                                        .padding(4)
                                        .background(
                                            Circle()
                                                .fill(theme.backgroundSecondary)
                                        )
                                }
                                .buttonStyle(.plain)
                                .opacity(isHovering ? 1.0 : 0.0)
                                .accessibilityLabel("Edit nook")
                            }
                            
                            // Task count badge
                            if taskCount > 0 {
                                Text("\(taskCount)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(theme.textSecondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(theme.textSecondary.opacity(0.15))
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
                .scaleEffect(isHovering ? 1.02 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            isSelected ? nook.iconColor.color.opacity(0.4) : 
                            (isHovering ? nook.iconColor.color.opacity(0.3) : nook.iconColor.color.opacity(0.2)),
                            lineWidth: isSelected ? 2 : (isHovering ? 1.5 : 1)
                        )
                )
                .shadow(
                    color: shadowColor(theme: theme),
                    radius: isSelected ? 12 : (isHovering ? 8 : 4),
                    x: 0,
                    y: isSelected ? 4 : (isHovering ? 3 : 2)
                )
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovering)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                editableNook = nook
            }
            .onChange(of: nook) { newNook in
                editableNook = newNook
            }
            .sheet(isPresented: $showingEditSheet) {
                NookEditorSheet(nook: $editableNook, isPresented: $showingEditSheet)
                    .onDisappear {
                        if editableNook != nook {
                            onEdit?(editableNook)
                        }
                    }
            }
        }
    }
}

