import Foundation

struct RemoteModel: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let contextLength: Int
    let provider: String?
    let promptPrice: String?
    let completionPrice: String?

    static let defaultModelId = "openrouter/auto"
    static let fallbackModels: [RemoteModel] = [
        RemoteModel(
            id: "openrouter/auto",
            name: "Auto Router (Default)",
            contextLength: 128_000,
            provider: "OpenRouter",
            promptPrice: nil,
            completionPrice: nil
        ),
        RemoteModel(
            id: "local",
            name: "LM Studio (localhost:1234)",
            contextLength: 8192,
            provider: "Local",
            promptPrice: "Free",
            completionPrice: "Free"
        )
    ]
}
