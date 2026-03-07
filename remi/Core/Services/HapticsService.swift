import AppKit

enum HapticEvent {
    case noteCreated
    case noteDeleted
    case noteUpdated
    case aiApplied
    case modelSaved
    case apiKeyValidated
}

final class HapticsService {
    static let shared = HapticsService()

    private init() {}

    func perform(_ event: HapticEvent) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch event {
        case .noteCreated, .modelSaved, .noteUpdated, .apiKeyValidated:
            pattern = .alignment
        case .noteDeleted, .aiApplied:
            pattern = .levelChange
        }

        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
