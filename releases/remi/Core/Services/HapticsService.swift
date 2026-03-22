import AppKit

enum HapticEvent {
    case noteCreated
    case noteDeleted
    case noteUpdated
    case aiApplied
    case modelSaved
    case apiKeyValidated
    case historyRestored
    case dataExported
    case dataImported
}

final class HapticsService {
    static let shared = HapticsService()

    private init() {}

    func perform(_ event: HapticEvent) {
        let pattern: NSHapticFeedbackManager.FeedbackPattern
        switch event {
        case .noteCreated, .modelSaved, .noteUpdated, .apiKeyValidated, .dataExported, .dataImported:
            pattern = .alignment
        case .noteDeleted, .aiApplied, .historyRestored:
            pattern = .levelChange
        }

        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .now)
    }
}
