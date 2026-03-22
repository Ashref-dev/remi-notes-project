import Foundation

final class ModelCatalogService {
    static let shared = ModelCatalogService()
    private let endpoint = "https://openrouter.ai/api/v1/models"

    private init() {}

    struct CatalogResult {
        let models: [RemoteModel]
        let usedFallback: Bool
        let message: String?
    }

    func fetchModels(search: String = "") async -> CatalogResult {
        guard let url = URL(string: endpoint) else {
            return CatalogResult(
                models: filter(RemoteModel.fallbackModels, search: search),
                usedFallback: true,
                message: "Model endpoint is unavailable. Using fallback list."
            )
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 20

        let apiKey = SettingsManager.shared.llmAPIKey.trimmingCharacters(in: .whitespacesAndNewlines)
        if !apiKey.isEmpty {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                return CatalogResult(
                    models: filter(RemoteModel.fallbackModels, search: search),
                    usedFallback: true,
                    message: "Couldn't load models from OpenRouter. Using fallback list."
                )
            }

            let decoded = try JSONDecoder().decode(OpenRouterModelListResponse.self, from: data)
            let mapped = decoded.data.map { item in
                RemoteModel(
                    id: item.id,
                    name: item.name ?? item.id,
                    contextLength: item.contextLength ?? 0,
                    provider: item.topProvider?.contextLength != nil ? "OpenRouter" : nil,
                    promptPrice: item.pricing?.prompt,
                    completionPrice: item.pricing?.completion
                )
            }

            let unique = Array(Set(mapped)).sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            let models = unique.isEmpty ? RemoteModel.fallbackModels : unique
            return CatalogResult(
                models: filter(models, search: search),
                usedFallback: unique.isEmpty,
                message: unique.isEmpty ? "No models returned by provider. Using fallback list." : nil
            )
        } catch {
            let message: String
            if let urlError = error as? URLError, urlError.code == .notConnectedToInternet {
                message = "No internet connection. Showing fallback models."
            } else {
                message = "Failed to load models. Showing fallback models."
            }
            return CatalogResult(
                models: filter(RemoteModel.fallbackModels, search: search),
                usedFallback: true,
                message: message
            )
        }
    }

    private func filter(_ models: [RemoteModel], search: String) -> [RemoteModel] {
        let trimmed = search.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return models }
        return models.filter { model in
            model.name.localizedCaseInsensitiveContains(trimmed) || model.id.localizedCaseInsensitiveContains(trimmed)
        }
    }
}

private struct OpenRouterModelListResponse: Decodable {
    let data: [OpenRouterModelItem]
}

private struct OpenRouterModelItem: Decodable {
    struct Pricing: Decodable {
        let prompt: String?
        let completion: String?
    }

    struct TopProvider: Decodable {
        let contextLength: Int?

        enum CodingKeys: String, CodingKey {
            case contextLength = "context_length"
        }
    }

    let id: String
    let name: String?
    let contextLength: Int?
    let pricing: Pricing?
    let topProvider: TopProvider?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case contextLength = "context_length"
        case pricing
        case topProvider = "top_provider"
    }
}
