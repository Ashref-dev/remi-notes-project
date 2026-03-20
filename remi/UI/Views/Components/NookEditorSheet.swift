import SwiftUI

struct NookEditorRequest: Identifiable {
    let nook: Nook
    let focusArea: NoteEditorFocusArea

    var id: UUID { nook.id }
}

struct NookEditorSheet: View {
    @Binding var nook: Nook
    @Binding var isPresented: Bool
    @State private var editedName: String
    @State private var selectedIcon: String
    @State private var selectedColor: NookIconColor
    @State private var selectedCategory: NookIconCategory
    @State private var tagsText: String
    @State private var isPinned: Bool
    @State private var validationError: String?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let focusArea: NoteEditorFocusArea

    init(
        nook: Binding<Nook>,
        isPresented: Binding<Bool>,
        focusArea: NoteEditorFocusArea = .general
    ) {
        self._nook = nook
        self._isPresented = isPresented
        self.focusArea = focusArea
        _editedName = State(initialValue: nook.wrappedValue.name)
        _selectedIcon = State(initialValue: nook.wrappedValue.iconName)
        _selectedColor = State(initialValue: nook.wrappedValue.iconColor)
        _selectedCategory = State(initialValue: NookIcons.categories.first { category in
            category.icons.contains(nook.wrappedValue.iconName)
        } ?? NookIcons.categories[0])
        _tagsText = State(initialValue: nook.wrappedValue.tags.joined(separator: ", "))
        _isPinned = State(initialValue: nook.wrappedValue.isPinned)
    }

    var body: some View {
        Themed { theme in
            VStack(spacing: 0) {
                header(theme: theme)
                Divider().opacity(0.12)

                if let validationError {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                        Text(validationError)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(theme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 18) {
                            previewSection(theme: theme)
                                .id(NoteEditorFocusArea.general.rawValue)

                            nameSection(theme: theme)
                                .id("name")

                            metadataSection(theme: theme)
                                .id(NoteEditorFocusArea.tags.rawValue)

                            colorSection(theme: theme)
                                .id(NoteEditorFocusArea.color.rawValue)

                            iconSection(theme: theme)
                                .id(NoteEditorFocusArea.icon.rawValue)
                        }
                        .padding(18)
                    }
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            let target = focusArea == .general ? "name" : focusArea.rawValue
                            withOptionalAnimation(.easeInOut(duration: 0.2)) {
                                proxy.scrollTo(target, anchor: .top)
                            }
                        }
                    }
                }
            }
            .frame(width: 470, height: 610)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 18, strokeOpacity: 0.08, fallbackMaterial: .regularMaterial)
            }
            .shadow(color: Color.black.opacity(0.18), radius: 24, x: 0, y: 14)
            .onExitCommand {
                isPresented = false
            }
        }
    }

    @ViewBuilder
    private func header(theme: Theme) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Edit Note")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)
                Text("Update the note name, icon, pin state, and tags.")
                    .font(.system(size: 12))
                    .foregroundStyle(theme.textSecondary)
            }

            Spacer()

            Button("Cancel") {
                isPresented = false
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(theme.textSecondary)

            Button("Save") {
                saveChanges()
            }
            .liquidGlassButtonStyle(prominent: true)
            .disabled(!isValidName)
        }
        .padding(18)
    }

    @ViewBuilder
    private func previewSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Preview", icon: "eye.fill", theme: theme)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(selectedColor.color.opacity(0.14))
                        .frame(width: 42, height: 42)

                    Image(systemName: selectedIcon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(selectedColor.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Untitled Note" : editedName)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(theme.textPrimary)

                        if isPinned {
                            Image(systemName: "pin.fill")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.orange)
                        }
                    }

                    if !parsedTags.isEmpty {
                        Text(parsedTags.joined(separator: ", "))
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    } else {
                        Text("No tags")
                            .font(.system(size: 11))
                            .foregroundStyle(theme.textSecondary)
                    }
                }

                Spacer()
            }
            .padding(12)
            .background {
                Color.clear
                    .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.05, fallbackMaterial: .thinMaterial)
            }
        }
    }

    @ViewBuilder
    private func nameSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Name", icon: "textformat", theme: theme)

            TextField("Enter note name...", text: $editedName)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background {
                    Color.clear
                        .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.05, interactive: true, fallbackMaterial: .thinMaterial)
                }
        }
    }

    @ViewBuilder
    private func metadataSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Metadata", icon: "tag.fill", theme: theme)

            Toggle(isOn: $isPinned) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Pin in Today")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.textPrimary)
                    Text("Pinned notes stay in the Today pinned section.")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                }
            }
            .toggleStyle(.switch)

            VStack(alignment: .leading, spacing: 6) {
                Text("Tags")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.textPrimary)

                TextField("Inbox, writing, personal", text: $tagsText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background {
                        Color.clear
                            .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.05, interactive: true, fallbackMaterial: .thinMaterial)
                    }

                if !parsedTags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(parsedTags, id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(theme.accent)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background {
                                    Capsule()
                                        .fill(theme.accent.opacity(0.12))
                                }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background {
            Color.clear
                .liquidGlassSurface(cornerRadius: 12, strokeOpacity: 0.05, fallbackMaterial: .thinMaterial)
        }
    }

    @ViewBuilder
    private func colorSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Color", icon: "paintpalette.fill", theme: theme)
            NookColorPickerSection(selectedColor: $selectedColor, theme: theme)
        }
    }

    @ViewBuilder
    private func iconSection(theme: Theme) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionHeader(title: "Icon", icon: "app.fill", theme: theme)
            NookIconPickerSection(
                selectedIcon: $selectedIcon,
                selectedCategory: $selectedCategory,
                iconColor: selectedColor,
                theme: theme
            )
        }
    }

    @ViewBuilder
    private func sectionHeader(title: String, icon: String, theme: Theme) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(theme.accent)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(theme.textSecondary)
        }
    }

    private func saveChanges() {
        let cleanedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanedName.isEmpty else {
            validationError = "Note name can't be empty."
            return
        }

        validationError = nil
        nook.name = cleanedName
        nook.iconName = selectedIcon
        nook.iconColor = selectedColor
        nook.tags = parsedTags
        nook.isPinned = isPinned

        withOptionalAnimation(.easeInOut(duration: 0.2)) {
            isPresented = false
        }
    }

    private var isValidName: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var parsedTags: [String] {
        tagsText
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private func withOptionalAnimation(_ animation: Animation, _ updates: @escaping () -> Void) {
        if reduceMotion {
            updates()
        } else {
            withAnimation(animation, updates)
        }
    }
}

private struct NookColorPickerSection: View {
    @Binding var selectedColor: NookIconColor
    let theme: Theme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 10)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(NookIconColor.allCases, id: \.self) { color in
                Button {
                    selectedColor = color
                } label: {
                    ZStack {
                        Circle()
                            .fill(color.color)
                            .frame(width: 28, height: 28)
                            .overlay {
                                Circle()
                                    .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                            }
                        if selectedColor == color {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(color.displayName)
            }
        }
    }
}

private struct NookIconPickerSection: View {
    @Binding var selectedIcon: String
    @Binding var selectedCategory: NookIconCategory
    let iconColor: NookIconColor
    let theme: Theme

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(NookIcons.categories, id: \.name) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(selectedCategory.name == category.name ? theme.accent : theme.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background {
                                    Capsule()
                                        .fill(selectedCategory.name == category.name ? theme.accent.opacity(0.14) : Color.clear)
                                }
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(selectedCategory.icons, id: \.self) { iconName in
                    Button {
                        selectedIcon = iconName
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(selectedIcon == iconName ? iconColor.color.opacity(0.18) : Color.clear)
                                .frame(width: 40, height: 40)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(selectedIcon == iconName ? iconColor.color.opacity(0.6) : Color.clear, lineWidth: 1.5)
                                }

                            Image(systemName: iconName)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(iconColor.color)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#if DEBUG
struct NookEditorSheet_Previews: PreviewProvider {
    static var previews: some View {
        NookEditorSheet(
            nook: .constant(Nook(name: "Sample Note", url: URL(fileURLWithPath: "/tmp/sample"))),
            isPresented: .constant(true)
        )
    }
}
#endif
