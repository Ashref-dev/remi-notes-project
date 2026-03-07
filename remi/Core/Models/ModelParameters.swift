import Foundation

// This file is intentionally kept for project compatibility while v2 transitions
// from provider-specific naming to provider-agnostic AI settings.
struct ModelParameters: Codable {
    var temperature: Double
    var maxTokens: Int
    var topP: Double
    var frequencyPenalty: Double
    var presencePenalty: Double

    static let `default` = ModelParameters(
        temperature: 0.3,
        maxTokens: 4000,
        topP: 0.9,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0
    )

    static let creative = ModelParameters(
        temperature: 0.8,
        maxTokens: 4000,
        topP: 0.9,
        frequencyPenalty: 0.3,
        presencePenalty: 0.3
    )

    static let precise = ModelParameters(
        temperature: 0.1,
        maxTokens: 4000,
        topP: 0.8,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0
    )

    static let balanced = ModelParameters(
        temperature: 0.5,
        maxTokens: 4000,
        topP: 0.9,
        frequencyPenalty: 0.1,
        presencePenalty: 0.1
    )
}
