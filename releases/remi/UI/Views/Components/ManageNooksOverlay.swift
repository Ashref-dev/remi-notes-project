import SwiftUI

struct ManageNooksOverlay: View {
    @ObservedObject var viewModel: NookListViewModel
    @Binding var selectedNook: Nook?
    let isPresented: Bool
    let onEditNote: (Nook, NoteEditorFocusArea) -> Void
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var searchFocused: Bool

    var body: some View {
        Themed { theme in
            ZStack {
                if isPresented {
                    Color.black.opacity(0.15)
                        .ignoresSafeArea()
                        .onTapGesture { onClose() }
                        .transition(.opacity)

                    VStack(spacing: 0) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Manage Notes")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(theme.textPrimary)
                                Text("Search, create, edit, and clean up your notes.")
                                    .font(.system(size: 11))
                                    .foregroundStyle(theme.textSecondary)
                            }

                            Spacer()

                            Button(action: onClose) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(theme.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)

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

                        ScrollView {
                            LazyVStack(spacing: 6) {
                                if viewModel.filteredNooks.isEmpty,
                                   !viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    Button(action: handleSubmit) {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(theme.accent)
                                            Text("Create \"\(viewModel.searchText)\"")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundStyle(theme.textPrimary)
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background {
                                            Color.clear
                                                .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.05, fallbackMaterial: .thinMaterial)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }

                                ForEach(viewModel.filteredNooks) { nook in
                                    row(for: nook, theme: theme)
                                }
                            }
                            .padding(16)
                        }
                    }
                    .frame(width: 420, height: 500)
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
        }
    }

    @ViewBuilder
    private func row(for nook: Nook, theme: Theme) -> some View {
        HStack(spacing: 10) {
            Image(systemName: nook.iconName)
                .foregroundStyle(nook.iconColor.color)
                .font(.system(size: 14))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(nook.name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(theme.textPrimary)

                    if nook.isInbox {
                        badge(text: "Inbox", tint: theme.accent)
                    }
                }

                if !nook.tags.isEmpty {
                    Text(nook.tags.joined(separator: ", "))
                        .font(.system(size: 10))
                        .foregroundStyle(theme.textSecondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Button {
                onEditNote(nook, .general)
            } label: {
                Image(systemName: "pencil.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(theme.textSecondary.opacity(0.8))
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
            Color.clear
                .liquidGlassSurface(
                    cornerRadius: 12,
                    strokeOpacity: selectedNook?.id == nook.id ? 0.14 : 0.05,
                    fallbackMaterial: .thinMaterial
                )
        }
        .onTapGesture {
            viewModel.select(nook)
            selectedNook = viewModel.selectedNook
            viewModel.searchText = ""
            onClose()
        }
    }

    @ViewBuilder
    private func badge(text: String, tint: Color) -> some View {
        Text(text)
            .font(.system(size: 9, weight: .semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background {
                Capsule()
                    .fill(tint.opacity(0.12))
            }
    }

    private func handleSubmit() {
        let text = viewModel.searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty, viewModel.filteredNooks.isEmpty {
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
            viewModel.select(first)
            selectedNook = viewModel.selectedNook
            viewModel.searchText = ""
            onClose()
        }
    }
}
