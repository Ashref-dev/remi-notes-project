import SwiftUI

struct ModernNookCard: View {
    let nook: Nook
    let isSelected: Bool
    let onTap: () -> Void
    let onEdit: ((Nook) -> Void)?
    @Binding var showEditSheet: Bool
    
    @State private var isHovering = false
    @State private var editableNook: Nook
    
    init(nook: Nook, isSelected: Bool, onTap: @escaping () -> Void, onEdit: ((Nook) -> Void)? = nil, showEditSheet: Binding<Bool> = .constant(false)) {
        self.nook = nook
        self.isSelected = isSelected
        self.onTap = onTap
        self.onEdit = onEdit
        self._showEditSheet = showEditSheet
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
        if isSelected { return nook.iconColor.color.opacity(0.12) }
        return isHovering 
            ? Color(NSColor.controlBackgroundColor).opacity(0.9)
            : Color(NSColor.controlBackgroundColor).opacity(0.6)
    }
    
    private func shadowColor(theme: Theme) -> Color {
        if isSelected { return nook.iconColor.color.opacity(0.25) }
        return nook.iconColor.color.opacity(isHovering ? 0.15 : 0.05)
    }

    private var strokeColor: Color {
        if isSelected { return nook.iconColor.color.opacity(0.4) }
        return nook.iconColor.color.opacity(isHovering ? 0.3 : 0.2)
    }

    private var strokeWidth: CGFloat {
        if isSelected { return 2 }
        return isHovering ? 1.5 : 1
    }

    private var shadowRadius: CGFloat {
        if isSelected { return 12 }
        return isHovering ? 8 : 4
    }

    private var shadowY: CGFloat {
        if isSelected { return 4 }
        return isHovering ? 3 : 2
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
                        Text(nook.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                            .lineLimit(1)
                        
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
                        .stroke(strokeColor, lineWidth: strokeWidth)
                )
                .shadow(
                    color: shadowColor(theme: theme),
                    radius: shadowRadius,
                    x: 0,
                    y: shadowY
                )
            }
            .buttonStyle(.plain)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isHovering)
            .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isSelected)
            .contextMenu {
                // Edit Nook Action
                Button {
                    showEditSheet = true
                } label: {
                    Label("Edit Nook", systemImage: "pencil")
                }
                
                Divider()
                
                // Pin to Desktop Action
                Button {
                    NotificationCenter.default.post(name: .toggleStickyWindow, object: nook)
                } label: {
                    Label("Pin to Desktop", systemImage: "pin.fill")
                }
            }
            .onHover { hovering in
                isHovering = hovering
            }
            .onAppear {
                editableNook = nook
            }
            .onChange(of: nook) { _, newNook in
                editableNook = newNook
            }
            .sheet(isPresented: $showEditSheet) {
                NookEditorSheet(nook: $editableNook, isPresented: $showEditSheet)
                    .onDisappear {
                        if editableNook != nook {
                            onEdit?(editableNook)
                        }
                    }
            }
        }
    }
}
