import SwiftUI

// MARK: - Nook Editor Sheet

struct NookEditorSheet: View {
    @Binding var nook: Nook
    @Binding var isPresented: Bool
    @State private var editedName: String
    @State private var selectedIcon: String
    @State private var selectedColor: NookIconColor
    @State private var selectedCategory: NookIconCategory
    @State private var isHoveringCancel = false
    @State private var isHoveringSave = false
    
    init(nook: Binding<Nook>, isPresented: Binding<Bool>) {
        self._nook = nook
        self._isPresented = isPresented
        self._editedName = State(initialValue: nook.wrappedValue.name)
        self._selectedIcon = State(initialValue: nook.wrappedValue.iconName)
        self._selectedColor = State(initialValue: nook.wrappedValue.iconColor)
        self._selectedCategory = State(initialValue: NookIcons.categories.first { category in
            category.icons.contains(nook.wrappedValue.iconName)
        } ?? NookIcons.categories[0])
    }
    
    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                // Header with title and action buttons
                HStack {
                    Text("Edit Nook")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                    
                    Spacer()
                    
                    HStack(spacing: AppTheme.Spacing.medium) {
                        Button(action: { isPresented = false }) {
                            HStack(spacing: 6) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 12, weight: .medium))
                                Text("Cancel")
                            }
                            .foregroundColor(isHoveringCancel ? theme.textPrimary : theme.textSecondary)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, AppTheme.Spacing.medium)
                            .padding(.vertical, AppTheme.Spacing.small + 2)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                    .fill(isHoveringCancel ? theme.backgroundSecondary.opacity(0.5) : Color.clear)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                            .stroke(isHoveringCancel ? theme.border.opacity(0.5) : theme.border.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            .scaleEffect(isHoveringCancel ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringCancel)
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isHoveringCancel = hovering
                        }
                        
                        Button(action: { saveChanges() }) {
                            HStack(spacing: 6) {
                                Image(systemName: isValidName ? "checkmark" : "exclamationmark.triangle")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Save")
                            }
                            .foregroundColor(.white)
                            .font(.system(size: 15, weight: .semibold))
                            .padding(.horizontal, AppTheme.Spacing.large)
                            .padding(.vertical, AppTheme.Spacing.small + 2)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                    .fill(isValidName ? 
                                          (isHoveringSave ? theme.accent.opacity(0.9) : theme.accent) : 
                                          theme.textSecondary.opacity(0.3))
                            )
                            .scaleEffect(isHoveringSave && isValidName ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 0.15), value: isHoveringSave)
                        }
                        .disabled(!isValidName)
                        .opacity(isValidName ? 1.0 : 0.6)
                        .animation(.easeInOut(duration: 0.2), value: isValidName)
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            isHoveringSave = hovering
                        }
                    }
                }
                .padding(AppTheme.Spacing.large)
                .background(theme.backgroundSecondary)
                
                Divider()
                
                // Content
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.large) {
                        // Live Preview
                        NookPreviewSection(
                            name: editedName,
                            iconName: selectedIcon,
                            iconColor: selectedColor,
                            theme: theme
                        )
                        
                        // Name Editor
                        NookNameEditorSection(
                            name: $editedName,
                            theme: theme
                        )
                        
                        // Color Picker
                        NookColorPickerSection(
                            selectedColor: $selectedColor,
                            theme: theme
                        )
                        
                        // Icon Picker
                        NookIconPickerSection(
                            selectedIcon: $selectedIcon,
                            selectedCategory: $selectedCategory,
                            iconColor: selectedColor,
                            theme: theme
                        )
                    }
                    .padding(AppTheme.Spacing.large)
                }
                .background(theme.background)
            }
            .frame(width: 460, height: 550)
            .background(theme.background)
            .cornerRadius(AppTheme.CornerRadius.medium)
            .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                // Handle app termination gracefully
            }
            .onExitCommand {
                isPresented = false
            }
        }
    }
    
    private func saveChanges() {
        // Validate and clean the name
        let cleanedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Ensure we have a valid name
        guard !cleanedName.isEmpty else {
            return
        }
        
        // Update the nook with validated changes
        nook.name = cleanedName
        nook.iconName = selectedIcon
        nook.iconColor = selectedColor
        
        // Add haptic feedback for successful save
        #if os(macOS)
        // No haptic feedback on macOS, but we could add a subtle animation
        #endif
        
        // Close the sheet with animation
        withAnimation(.easeInOut(duration: 0.25)) {
            isPresented = false
        }
    }
    
    private var hasChanges: Bool {
        let cleanedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        return cleanedName != nook.name || 
               selectedIcon != nook.iconName || 
               selectedColor != nook.iconColor
    }
    
    private var isValidName: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Nook Preview Section

private struct NookPreviewSection: View {
    let name: String
    let iconName: String
    let iconColor: NookIconColor
    let theme: Theme
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                    Text("Preview")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
            
            HStack(spacing: AppTheme.Spacing.medium) {
                ZStack {
                    Circle()
                        .fill(iconColor.color.opacity(0.15))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: iconName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(iconColor.color)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(name.isEmpty ? "Untitled Nook" : name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(theme.textPrimary)
                        .lineLimit(1)
                    
                    Text("Live preview of your nook")
                        .font(.system(size: 12))
                        .foregroundColor(theme.textSecondary)
                }
                
                Spacer()
            }
            .padding(AppTheme.Spacing.medium)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                    .fill(theme.backgroundSecondary.opacity(0.8))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                            .stroke(iconColor.color.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
    }
}

// MARK: - Nook Name Editor Section

private struct NookNameEditorSection: View {
    @Binding var name: String
    let theme: Theme
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "textformat")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                    Text("Name")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
            
            TextField("Enter nook name...", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(AppTheme.Spacing.medium)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                        .fill(theme.backgroundSecondary.opacity(0.8))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppTheme.CornerRadius.small)
                                .stroke(
                                    isNameFocused ? theme.accent.opacity(0.6) : theme.border.opacity(0.3),
                                    lineWidth: isNameFocused ? 2 : 1
                                )
                        )
                )
                .focused($isNameFocused)
                .onSubmit {
                    // Save when Return is pressed if name is valid
                    if !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // We can't directly call saveChanges here since it's in the parent
                        // But the onSubmit will trigger when the user presses Return
                    }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isNameFocused = true
                    }
                }
        }
    }
}

// MARK: - Nook Color Picker Section

private struct NookColorPickerSection: View {
    @Binding var selectedColor: NookIconColor
    let theme: Theme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.small), count: 10)
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                    Text("Color")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
            
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.small) {
                ForEach(NookIconColor.allCases, id: \.self) { color in
                    ColorPickerButton(
                        color: color,
                        isSelected: selectedColor == color,
                        onTap: { selectedColor = color }
                    )
                }
            }
        }
    }
}

private struct ColorPickerButton: View {
    let color: NookIconColor
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 28, height: 28)
                    .scaleEffect(isHovering ? 1.15 : 1.0)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: isSelected ? 3 : 0)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.black.opacity(0.15), lineWidth: 1)
                    )
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel(color.displayName)
    }
}

// MARK: - Nook Icon Picker Section

private struct NookIconPickerSection: View {
    @Binding var selectedIcon: String
    @Binding var selectedCategory: NookIconCategory
    let iconColor: NookIconColor
    let theme: Theme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppTheme.Spacing.medium), count: 7)
    
    var body: some View {
        VStack(spacing: AppTheme.Spacing.small) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "app.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(theme.accent)
                    Text("Icon")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(theme.textSecondary)
                }
                Spacer()
            }
            
            // Category Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.Spacing.small) {
                    ForEach(NookIcons.categories, id: \.name) { category in
                        CategoryButton(
                            category: category,
                            isSelected: selectedCategory.name == category.name,
                            onTap: { selectedCategory = category },
                            theme: theme
                        )
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // Icon Grid
            LazyVGrid(columns: columns, spacing: AppTheme.Spacing.medium) {
                ForEach(selectedCategory.icons, id: \.self) { iconName in
                    IconPickerButton(
                        iconName: iconName,
                        iconColor: iconColor,
                        isSelected: selectedIcon == iconName,
                        onTap: { selectedIcon = iconName }
                    )
                }
            }
        }
    }
}

private struct CategoryButton: View {
    let category: NookIconCategory
    let isSelected: Bool
    let onTap: () -> Void
    let theme: Theme
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            Text(category.name)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(isSelected ? theme.accent : theme.textSecondary)
                .padding(.horizontal, AppTheme.Spacing.small)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(isSelected ? theme.accent.opacity(0.2) : (isHovering ? theme.backgroundSecondary.opacity(0.8) : Color.clear))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(
                                    isSelected ? theme.accent.opacity(0.4) : theme.border.opacity(0.3),
                                    lineWidth: 1.5
                                )
                        )
                )
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                .animation(.easeInOut(duration: 0.2), value: isHovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}

private struct IconPickerButton: View {
    let iconName: String
    let iconColor: NookIconColor
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isHovering = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(isSelected ? iconColor.color.opacity(0.25) : (isHovering ? iconColor.color.opacity(0.15) : Color.clear))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                isSelected ? iconColor.color.opacity(0.7) : Color.clear,
                                lineWidth: 2
                            )
                    )
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor.color)
                    .scaleEffect(isHovering ? 1.15 : 1.0)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
        .accessibilityLabel("Icon: \(iconName)")
    }
}

// MARK: - Preview

#if DEBUG
struct NookEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        NookEditorSheet(
            nook: .constant(Nook(name: "Sample Nook", url: URL(string: "file://")!)),
            isPresented: .constant(true)
        )
    }
}
#endif
