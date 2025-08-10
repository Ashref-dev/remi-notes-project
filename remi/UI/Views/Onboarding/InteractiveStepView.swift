import SwiftUI

struct InteractiveStepView: View {
    let theme: Theme
    @ObservedObject var onboardingService: OnboardingService
    @State private var demoNooks: [DemoNook] = [
        DemoNook(id: "1", title: "🤖 AI Prompts", content: "My daily ChatGPT prompts"),
        DemoNook(id: "2", title: "🐳 Docker", content: "Container commands"),
        DemoNook(id: "3", title: "💡 Ideas", content: "Brilliant thoughts")
    ]
    @State private var selectedNookId: String?
    @State private var isEditing = false
    @State private var editingTitle = ""
    @State private var aiDemoStep = 0
    @State private var showAIResponse = false
    @State private var hasTriedDragging = false
    @State private var showingContinueOption = false
    
    struct DemoNook: Identifiable, Equatable { let id: String; var title: String; var content: String }
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.xlarge) {
            VStack(spacing: AppTheme.Spacing.medium) {
                Text("Try It Yourself!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(theme.textPrimary)
                Text("Practice the core features with this interactive demo")
                    .font(.system(size: 16))
                    .foregroundColor(theme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            HStack(spacing: AppTheme.Spacing.xlarge) {
                DemoArea(
                    demoNooks: $demoNooks,
                    selectedNookId: $selectedNookId,
                    isEditing: $isEditing,
                    editingTitle: $editingTitle,
                    aiDemoStep: $aiDemoStep,
                    showAIResponse: $showAIResponse,
                    hasTriedDragging: $hasTriedDragging,
                    theme: theme
                )
                .frame(width: 300)
                Divider()
                InstructionsPanel(
                    selectedNookId: selectedNookId,
                    isEditing: isEditing,
                    aiDemoStep: aiDemoStep,
                    showAIResponse: showAIResponse,
                    hasTriedDragging: hasTriedDragging,
                    showingContinueOption: showingContinueOption,
                    onboardingService: onboardingService,
                    theme: theme
                )
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: 350)
        }
        .padding(.horizontal, AppTheme.Spacing.xlarge)
        .padding(.top, AppTheme.Spacing.xlarge)
        .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 10) { showingContinueOption = true } }
        .onChange(of: aiDemoStep) { step in if step == 1 { DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { showAIResponse = true } } }
    }
}

struct DemoArea: View {
    @Binding var demoNooks: [InteractiveStepView.DemoNook]
    @Binding var selectedNookId: String?
    @Binding var isEditing: Bool
    @Binding var editingTitle: String
    @Binding var aiDemoStep: Int
    @Binding var showAIResponse: Bool
    @Binding var hasTriedDragging: Bool
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            Text("Demo Nooks")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            VStack(spacing: AppTheme.Spacing.small) {
                ForEach(Array(demoNooks.enumerated()), id: \.element.id) { index, nook in
                    DemoNookCard(
                        nook: $demoNooks[index],
                        isSelected: selectedNookId == nook.id,
                        isEditing: isEditing && selectedNookId == nook.id,
                        editingTitle: $editingTitle,
                        onSelect: { selectedNookId = nook.id },
                        onEdit: {
                            selectedNookId = nook.id
                            isEditing = true
                            editingTitle = nook.title
                        },
                        onSave: {
                            demoNooks[index].title = editingTitle
                            isEditing = false
                            selectedNookId = nil
                        },
                        onCancel: {
                            isEditing = false
                            selectedNookId = nil
                        },
                        onAI: {
                            selectedNookId = nook.id
                            aiDemoStep = 1
                        },
                        onMove: { direction in
                            moveNook(from: index, direction: direction)
                        },
                        theme: theme
                    )
                    .onDrag {
                        hasTriedDragging = true
                        return NSItemProvider(object: nook.id as NSString)
                    }
                    .onDrop(of: [.text], delegate: DemoNookDropDelegate(
                        item: nook,
                        items: $demoNooks,
                        draggedItem: nook,
                        onReorder: {
                            hasTriedDragging = true
                        }
                    ))
                }
            }
            
            if showAIResponse {
                AIResponseDemo(
                    onDismiss: {
                        showAIResponse = false
                        aiDemoStep = 0
                        selectedNookId = nil
                    },
                    theme: theme
                )
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(theme.backgroundSecondary)
        )
    }
    
    private func moveNook(from index: Int, direction: MoveDirection) {
        let newIndex: Int
        switch direction {
        case .up:
            newIndex = max(0, index - 1)
        case .down:
            newIndex = min(demoNooks.count - 1, index + 1)
        }
        
        if newIndex != index {
            let nook = demoNooks.remove(at: index)
            demoNooks.insert(nook, at: newIndex)
            hasTriedDragging = true // Also counts as trying reordering
        }
    }
    
    enum MoveDirection {
        case up, down
    }
}

struct DemoNookCard: View {
    @Binding var nook: InteractiveStepView.DemoNook
    let isSelected: Bool
    let isEditing: Bool
    @Binding var editingTitle: String
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onSave: () -> Void
    let onCancel: () -> Void
    let onAI: () -> Void
    let onMove: (DemoArea.MoveDirection) -> Void
    let theme: Theme
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: AppTheme.Spacing.small) {
            // Content area
            HStack(spacing: AppTheme.Spacing.medium) {
                VStack(alignment: .leading, spacing: 2) {
                    if isEditing {
                        TextField("Nook title", text: $editingTitle)
                            .textFieldStyle(.plain)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                    } else {
                        Text(nook.title)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(theme.textPrimary)
                    }
                    
                    Text(nook.content)
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if !isEditing {
                    onSelect()
                }
            }
            
            // Action buttons
            if isEditing {
                HStack(spacing: AppTheme.Spacing.small) {
                    Button(action: onSave) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onCancel) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
            } else if isSelected || isHovered {
                HStack(spacing: AppTheme.Spacing.small) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12))
                            .foregroundColor(theme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onAI) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12))
                            .foregroundColor(theme.accent)
                    }
                    .buttonStyle(.plain)
                    
                    VStack(spacing: 2) {
                        Button(action: { onMove(.up) }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 8))
                                .foregroundColor(theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: { onMove(.down) }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(theme.textSecondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.small)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                .fill(isSelected ? theme.accent.opacity(0.1) : theme.cardBackground)
                .stroke(isSelected ? theme.accent : Color.clear, lineWidth: 1)
        )
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct AIResponseDemo: View {
    let onDismiss: () -> Void
    let theme: Theme
    @State private var showContent = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
            HStack {
                HStack(spacing: AppTheme.Spacing.small) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 14))
                        .foregroundColor(theme.accent)
                    
                    Text("AI Response")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                .buttonStyle(.plain)
            }
            
            if showContent {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("Improved Content:")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("🤖 AI Prompts & Templates\nCurated collection of ChatGPT, Claude, and other AI prompts for productivity")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                        .padding(AppTheme.Spacing.small)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .fill(theme.background)
                        )
                    
                    HStack {
                        Button("Apply") {
                            onDismiss()
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, AppTheme.Spacing.medium)
                        .padding(.vertical, AppTheme.Spacing.small)
                        .background(theme.accent)
                        .foregroundColor(.white)
                        .cornerRadius(AppTheme.CornerRadius.small)
                        
                        Button("Dismiss") {
                            onDismiss()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(theme.textSecondary)
                    }
                }
            }
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(theme.cardBackground)
                .stroke(theme.accent, lineWidth: 1)
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    showContent = true
                }
            }
        }
    }
}

struct InstructionsPanel: View {
    let selectedNookId: String?
    let isEditing: Bool
    let aiDemoStep: Int
    let showAIResponse: Bool
    let hasTriedDragging: Bool
    let showingContinueOption: Bool
    let onboardingService: OnboardingService
    let theme: Theme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.large) {
            Text("Instructions")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(theme.textPrimary)
            
            VStack(alignment: .leading, spacing: AppTheme.Spacing.medium) {
                InteractiveInstructionStep(
                    number: 1,
                    title: "Select a Nook",
                    description: "Click on any nook to select it and see available actions",
                    isCompleted: selectedNookId != nil,
                    theme: theme
                )
                
                InteractiveInstructionStep(
                    number: 2,
                    title: "Try Editing",
                    description: "Click the edit icon (pencil) to rename a nook",
                    isCompleted: isEditing,
                    theme: theme
                )
                
                InteractiveInstructionStep(
                    number: 3,
                    title: "Reorder Nooks",
                    description: "Use the up/down arrows or drag nooks to change order",
                    isCompleted: hasTriedDragging,
                    theme: theme
                )
                
                InteractiveInstructionStep(
                    number: 4,
                    title: "AI Enhancement",
                    description: "Click the AI icon (brain) to improve content with AI",
                    isCompleted: aiDemoStep > 0,
                    theme: theme
                )
            }
            
            if aiDemoStep > 0 && !showAIResponse {
                VStack(alignment: .leading, spacing: AppTheme.Spacing.small) {
                    Text("✨ AI is processing...")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.accent)
                    
                    Text("Analyzing content and generating improvements")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                .padding(AppTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(theme.accent.opacity(0.1))
                )
            }
            
            if showingContinueOption {
                VStack(spacing: AppTheme.Spacing.small) {
                    Text("Ready to continue?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(theme.textPrimary)
                    
                    Text("You can explore more or move to the next step")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                    
                    Button("Continue to Next Step") {
                        onboardingService.nextStep()
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(theme.accent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(AppTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                        .fill(theme.cardBackground)
                        .stroke(theme.accent.opacity(0.3), lineWidth: 1)
                )
            }
            
            Spacer()
        }
        .padding(AppTheme.Spacing.medium)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.medium)
                .fill(theme.backgroundSecondary)
        )
    }
}

struct InteractiveInstructionStep: View {
    let number: Int
    let title: String
    let description: String
    let isCompleted: Bool
    let theme: Theme
    
    var body: some View {
        HStack(alignment: .top, spacing: AppTheme.Spacing.medium) {
            ZStack {
                Circle()
                    .fill(isCompleted ? theme.accent : theme.cardBackground)
                    .frame(width: 24, height: 24)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isCompleted ? theme.accent : theme.textPrimary)
                
                Text(description)
                    .font(.system(size: 12))
                    .foregroundColor(theme.textSecondary)
            }
        }
    }
}

struct DemoNookDropDelegate: DropDelegate {
    let item: InteractiveStepView.DemoNook
    @Binding var items: [InteractiveStepView.DemoNook]
    let draggedItem: InteractiveStepView.DemoNook
    let onReorder: () -> Void
    
    func performDrop(info: DropInfo) -> Bool {
        onReorder()
        return true
    }
    
    func dropEntered(info: DropInfo) {
        guard draggedItem.id != item.id else { return }
        
        let from = items.firstIndex(of: draggedItem)!
        let to = items.firstIndex(of: item)!
        
        withAnimation(.default) {
            items.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }
}

struct InteractiveStepView_Previews: PreviewProvider {
    static var previews: some View {
        Themed { theme in
            InteractiveStepView(
                theme: theme,
                onboardingService: OnboardingService.shared
            )
        }
        .frame(width: 800, height: 600)
    }
}
