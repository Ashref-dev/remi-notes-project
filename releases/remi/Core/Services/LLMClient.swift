import Foundation

protocol LLMClient {
    func sendEdit(prompt: String, context: String, model: String, params: ModelParameters) async throws -> String
    func validateAPIKey() async throws
}
