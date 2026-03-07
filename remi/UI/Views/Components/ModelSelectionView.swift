import SwiftUI

struct ModelSelectionView: View {
    @StateObject private var settings = SettingsManager.shared
    @State private var models: [RemoteModel] = []
    @State private var searchQuery = ""
    @State private var isLoading = false
    @State private var loadMessage: String?
    @State private var searchTask: Task<Void, Never>?
    @State private var requestGeneration = 0

    var body: some View {
        Themed { theme in
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Search OpenRouter models", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                        .onSubmit {
                            searchTask?.cancel()
                            Task { await loadModels(for: searchQuery) }
                        }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background {
                    Color.clear
                        .liquidGlassSurface(cornerRadius: 10, strokeOpacity: 0.05, interactive: true, fallbackMaterial: .thinMaterial)
                }

                if isLoading {
                    ProgressView("Loading models...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                } else if models.isEmpty {
                    Text(searchQuery.isEmpty ? "No models available." : "No models match \"\(searchQuery)\".")
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 4)
                }

                if let loadMessage {
                    Text(loadMessage)
                        .font(.system(size: 11))
                        .foregroundStyle(theme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 2)
                }

                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(models) { model in
                            Button {
                                guard settings.selectedModelId != model.id else { return }
                                settings.selectedModelId = model.id
                                HapticsService.shared.perform(.modelSaved)
                            } label: {
                                HStack(alignment: .top, spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(model.name)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundStyle(theme.textPrimary)
                                        Text(model.id)
                                            .font(.system(size: 11))
                                            .foregroundStyle(theme.textSecondary)
                                        if model.contextLength > 0 {
                                            Text("Context: \(model.contextLength.formatted()) tokens")
                                                .font(.system(size: 10))
                                                .foregroundStyle(theme.textSecondary)
                                        }
                                    }

                                    Spacer()

                                    if model.id == settings.selectedModelId {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(theme.accent)
                                    }
                                }
                                .padding(10)
                                .background(
                                    Color.clear
                                        .liquidGlassSurface(cornerRadius: 10, strokeOpacity: model.id == settings.selectedModelId ? 0.14 : 0.06, interactive: true, fallbackMaterial: .regularMaterial)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(model.id == settings.selectedModelId ? theme.accent.opacity(0.12) : .clear)
                                        }
                                )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Model \(model.name)")
                            .accessibilityValue(model.id == settings.selectedModelId ? "Selected" : "Not selected")
                        }
                    }
                }
                .frame(maxHeight: 220)
            }
            .task { await loadModels(for: searchQuery) }
            .onChange(of: searchQuery) { _, _ in
                scheduleModelSearch()
            }
            .onDisappear { searchTask?.cancel() }
        }
    }

    private func scheduleModelSearch() {
        searchTask?.cancel()
        let query = searchQuery
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard !Task.isCancelled else { return }
            await loadModels(for: query)
        }
    }

    @MainActor
    private func loadModels(for query: String) async {
        requestGeneration += 1
        let generation = requestGeneration
        isLoading = true
        loadMessage = nil

        let result = await ModelCatalogService.shared.fetchModels(search: query)
        guard generation == requestGeneration else { return }

        models = result.models
        loadMessage = result.message
        isLoading = false
    }
}
