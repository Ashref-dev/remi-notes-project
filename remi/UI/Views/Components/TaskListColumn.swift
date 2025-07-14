import SwiftUI

struct TaskListColumn: View {
    let selectedNook: Nook?
    @State private var selectedTask: String?
    @State private var tasks: [String] = []
    @State private var showingNewTaskEditor = false
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header
                HStack {
                    if let nook = selectedNook {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(nook.name)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(theme.textPrimary)
                            Text("\(tasks.count) task\(tasks.count == 1 ? "" : "s")")
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                        }
                    } else {
                        Text("Select a Nook")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(theme.textSecondary)
                    }
                    
                    Spacer()
                    
                    if selectedNook != nil {
                        Button(action: { showingNewTaskEditor = true }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(theme.accent)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(AppTheme.Spacing.large)
                
                Divider()
                
                // Task List or Empty State
                if let nook = selectedNook {
                    if tasks.isEmpty {
                        emptyTasksView(theme: theme)
                    } else {
                        taskScrollView(theme: theme)
                    }
                } else {
                    selectNookPrompt(theme: theme)
                }
            }
        }
        .onChange(of: selectedNook) { newNook in
            loadTasks()
        }
        .onAppear {
            loadTasks()
        }
        .sheet(isPresented: $showingNewTaskEditor) {
            if let nook = selectedNook {
                NewTaskSheet(nook: nook) {
                    loadTasks()
                }
            }
        }
    }
    
    private func taskScrollView(theme: Theme) -> some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.Spacing.small) {
                ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                    TaskCard(
                        task: task,
                        isSelected: selectedTask == task,
                        onTap: { selectedTask = task }
                    )
                }
            }
            .padding(AppTheme.Spacing.large)
        }
    }
    
    private func emptyTasksView(theme: Theme) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 40))
                .foregroundColor(theme.accent)
            Text("No tasks yet")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            Text("Click the + button to create your first task")
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
    
    private func selectNookPrompt(theme: Theme) -> some View {
        VStack(spacing: AppTheme.Spacing.medium) {
            Spacer()
            Image(systemName: "arrow.left")
                .font(.system(size: 40))
                .foregroundColor(theme.textSecondary)
            Text("Select a Nook")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(theme.textSecondary)
            Text("Choose a Nook from the sidebar to view its tasks")
                .font(.system(size: 12))
                .foregroundColor(theme.textSecondary)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .padding(AppTheme.Spacing.large)
    }
    
    private func loadTasks() {
        guard let nook = selectedNook else {
            tasks = []
            selectedTask = nil
            return
        }
        
        let content = NookManager.shared.fetchTasks(for: nook)
        // Split content by double newlines to get individual tasks/sections
        tasks = content.components(separatedBy: "\n\n").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        // If no tasks but we have content, treat the whole content as one task
        if tasks.isEmpty && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            tasks = [content]
        }
        
        // Clear selection if the selected task no longer exists
        if let selected = selectedTask, !tasks.contains(selected) {
            selectedTask = nil
        }
    }
}

struct TaskCard: View {
    let task: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var isHovering = false
    @State private var isCompleted = false
    @State private var scale: CGFloat = 1.0
    @State private var checkboxScale: CGFloat = 1.0
    
    private var taskTitle: String {
        let lines = task.components(separatedBy: .newlines)
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "Untitled Task"
    }
    
    private var taskPreview: String {
        let lines = task.components(separatedBy: .newlines)
        let preview = lines.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return String(preview.prefix(100))
    }
    
    var body: some View {
        Themed { theme in
            Button(action: onTap) {
                HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
                    // Animated Checkbox
                    Button(action: { 
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            checkboxScale = 1.3
                        }
                        withAnimation(.easeInOut(duration: 0.3).delay(0.1)) {
                            isCompleted.toggle()
                            checkboxScale = 1.0
                        }
                    }) {
                        ZStack {
                            Circle()
                                .stroke(isCompleted ? theme.accent : theme.textSecondary, lineWidth: 2)
                                .frame(width: 16, height: 16)
                            
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(theme.accent)
                                    .scaleEffect(checkboxScale)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(checkboxScale)
                    
                    VStack(alignment: .leading, spacing: AppTheme.Spacing.xsmall) {
                        Text(taskTitle)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(isSelected ? theme.accent : theme.textPrimary)
                            .strikethrough(isCompleted)
                            .opacity(isCompleted ? 0.6 : 1.0)
                            .lineLimit(1)
                            .animation(.easeInOut(duration: 0.3), value: isCompleted)
                        
                        if !taskPreview.isEmpty {
                            Text(taskPreview)
                                .font(.system(size: 12))
                                .foregroundColor(theme.textSecondary)
                                .opacity(isCompleted ? 0.5 : 1.0)
                                .lineLimit(2)
                                .animation(.easeInOut(duration: 0.3), value: isCompleted)
                        }
                    }
                    
                    Spacer()
                    
                    // Status indicator
                    if isSelected {
                        Circle()
                            .fill(theme.accent)
                            .frame(width: 6, height: 6)
                            .scaleEffect(scale)
                    }
                }
                .padding(AppTheme.Spacing.medium)
                .background(cardBackgroundColor(theme: theme))
                .cornerRadius(AppTheme.CornerRadius.medium)
                .scaleEffect(scale)
                .opacity(isCompleted ? 0.7 : 1.0)
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .stroke(
                            isSelected ? theme.accent.opacity(0.3) : Color.clear,
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isHovering = hovering
                    scale = hovering ? 1.01 : 1.0
                }
            }
            .animation(.easeInOut(duration: 0.15), value: isSelected)
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

struct NewTaskSheet: View {
    let nook: Nook
    let onTaskCreated: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var taskContent = ""
    
    var body: some View {
        Themed { theme in
            VStack(spacing: AppTheme.Spacing.large) {
                HStack {
                    Text("New Task")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    Spacer()
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(theme.textSecondary)
                }
                
                TextEditor(text: $taskContent)
                    .font(.system(size: 14))
                    .scrollContentBackground(.hidden)
                    .background(theme.backgroundSecondary)
                    .cornerRadius(AppTheme.CornerRadius.medium)
                
                HStack {
                    Spacer()
                    Button("Create Task") {
                        createTask()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(taskContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(AppTheme.Spacing.large)
            .frame(minWidth: 400, minHeight: 300)
        }
    }
    
    private func createTask() {
        let currentContent = NookManager.shared.fetchTasks(for: nook)
        let newContent = currentContent.isEmpty ? taskContent : currentContent + "\n\n" + taskContent
        NookManager.shared.saveTasks(for: nook, content: newContent)
        onTaskCreated()
        dismiss()
    }
}
