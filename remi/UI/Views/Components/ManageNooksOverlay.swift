import SwiftUI

struct ManageNooksOverlay: View {
    @ObservedObject var viewModel: NookListViewModel
    @Binding var selectedNook: Nook?
    let isPresented: Bool
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool
    @State private var editingNook: Nook?

    var body: some View {
        Themed { theme in
            ZStack {
                if isPresented {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture { onClose() }
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        // Header
                        HStack {
                            Text("Manage Notes")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Button(action: onClose) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)

                        // Search & Create
                        HStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.secondary)
                                TextField("Search or create new...", text: $viewModel.searchText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 13))
                                    .focused($searchFocused)
                                    .onSubmit { handleSubmit() }
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .background {
                                Color.clear
                                    .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.05, interactive: true, fallbackMaterial: .thickMaterial)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)

                        Divider().opacity(0.1)

                        // List
                        ScrollView {
                            LazyVStack(spacing: 6) {
                                if viewModel.filteredNooks.isEmpty && !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button {
                                        handleSubmit()
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle")
                                                .foregroundStyle(theme.accent)
                                            Text("Create \"\(viewModel.searchText)\"")
                                                .font(.system(size: 13, weight: .medium))
                                            Spacer()
                                        }
                                        .padding()
                                        .background {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(theme.accent.opacity(0.1))
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                ForEach(viewModel.filteredNooks) { nook in
                                    HStack {
                                        Image(systemName: nook.iconName)
                                            .foregroundStyle(nook.iconColor.color)
                                            .font(.system(size: 14))
                                            .frame(width: 24)

                                        Text(nook.name)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(theme.textPrimary)

                                        Spacer()

                                        Button {
                                            editingNook = nook
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(theme.textSecondary.opacity(0.7))
                                        }
                                        .buttonStyle(.plain)

                                        Button {
                                            if viewModel.deleteNook(nook) {
                                                HapticsService.shared.perform(.noteDeleted)
                                            }
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 16))
                                                .foregroundStyle(.red.opacity(0.8))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 12)
                                    .background {
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill((selectedNook?.id == nook.id) ? theme.accent.opacity(0.1) : Color.white.opacity(0.02))
                                    }
                                    .onTapGesture {
                                        selectedNook = nook
                                        SettingsManager.shared.setLastViewedNook(nook)
                                        viewModel.searchText = "" // Clear search
                                        onClose()
                                    }
                                }
                            }
                            .padding(16)
                        }
                    }
                    .frame(width: 400, height: 480)
                    .background {
                        Color.clear
                            .liquidGlassSurface(cornerRadius: 16, strokeOpacity: 0.12, fallbackMaterial: .thickMaterial)
                    }
                    .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
                    .transition(.scale(scale: 0.95).combined(with: .opacity))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            searchFocused = true
                        }
                    }
                }
            }
            .animation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.85), value: isPresented)
            .sheet(item: $editingNook) { nook in
                NookEditorSheetHost(initialNook: nook) { updatedNook in
                    if let savedNook = viewModel.updateNook(updatedNook) {
                        if selectedNook?.id == savedNook.id {
                            selectedNook = savedNook
                        }
                    }
                }
            }
        }
    }

    private func handleSubmit() {
        let text = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty && viewModel.filteredNooks.isEmpty {
            let existingNook = viewModel.existingNook(named: text)
            if let created = viewModel.createNook(named: text) {
                selectedNook = created
                if existingNook == nil {
                    HapticsService.shared.perform(.noteCreated)
                }
                viewModel.searchText = ""
                onClose()
            }
        } else if let first = viewModel.filteredNooks.first {
            selectedNook = first
            SettingsManager.shared.setLastViewedNook(first)
            viewModel.searchText = ""
            onClose()
        }
    }
}

// Reusing NookEditorSheetHost from ContentView
private struct NookEditorSheetHost: View {
    let initialNook: Nook
    let onSave: (Nook) -> Void

    @State private var draftNook: Nook
    @State private var isPresented = true
    @Environment(\.dismiss) private var dismiss

    init(initialNook: Nook, onSave: @escaping (Nook) -> Void) {
        self.initialNook = initialNook
        self.onSave = onSave
        _draftNook = State(initialValue: initialNook)
    }

    var body: some View {
        NookEditorSheet(nook: $draftNook, isPresented: $isPresented)
            .onChange(of: isPresented) { _, newValue in
                guard !newValue else { return }
                if draftNook != initialNook {
                    onSave(draftNook)
                }
                dismiss()
            }
    }
}
