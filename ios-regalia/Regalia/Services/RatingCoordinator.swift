import Foundation
import Observation

/// Remembers every rating ask, rating, and piece of feedback, so the firm limits
/// hold across relaunches: at most three asks in a lifetime, at least five days
/// between asks, and a permanent stop once the person rates or sends feedback.
@Observable
final class RatingCoordinator {
    private(set) var askCount: Int
    private(set) var lastAskDate: Date?
    private(set) var hasRated: Bool
    private(set) var hasSentFeedback: Bool

    /// The earned moments a dismissal can be followed up on, as streak counts.
    nonisolated static let milestoneStreaks: Set<Int> = [3, 7, 30]
    nonisolated static let lifetimeAskLimit = 3
    nonisolated static let daysBetweenAsks = 5

    private let defaults: UserDefaults
    private enum Key {
        static let askCount = "regalia.rating.askCount"
        static let lastAskDate = "regalia.rating.lastAskDate"
        static let hasRated = "regalia.rating.hasRated"
        static let hasSentFeedback = "regalia.rating.hasSentFeedback"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        askCount = defaults.integer(forKey: Key.askCount)
        lastAskDate = defaults.object(forKey: Key.lastAskDate) as? Date
        hasRated = defaults.bool(forKey: Key.hasRated)
        hasSentFeedback = defaults.bool(forKey: Key.hasSentFeedback)
    }

    /// True once no automatic ask should ever be raised again.
    var isFinished: Bool {
        hasRated || hasSentFeedback || askCount >= RatingCoordinator.lifetimeAskLimit
    }

    /// Whether the session celebration may raise the card right now. Only ever
    /// allowed on earned moments, and never the morning after a missed day or in
    /// the same session as a spent unlock pass.
    func shouldAskOnCompletion(streak: Int, completedSessions: Int, missedYesterday: Bool, spentPassToday: Bool) -> Bool {
        guard !isFinished else { return false }
        guard !missedYesterday, !spentPassToday else { return false }

        if let last = lastAskDate {
            guard let due = Calendar.current.date(byAdding: .day, value: RatingCoordinator.daysBetweenAsks, to: last), due <= Date() else {
                return false
            }
        }

        // The very first completed session, or a milestone streak morning.
        return completedSessions == 1 || RatingCoordinator.milestoneStreaks.contains(streak)
    }

    func markAsked() {
        askCount += 1
        lastAskDate = Date()
        persist()
    }

    func markRated() {
        hasRated = true
        persist()
    }

    func markFeedbackSent() {
        hasSentFeedback = true
        persist()
    }

    /// Clears the memory when the person erases their walk from Settings.
    nonisolated static func eraseAll(from defaults: UserDefaults) {
        [Key.askCount, Key.lastAskDate, Key.hasRated, Key.hasSentFeedback]
            .forEach { defaults.removeObject(forKey: $0) }
    }

    private func persist() {
        defaults.set(askCount, forKey: Key.askCount)
        defaults.set(lastAskDate, forKey: Key.lastAskDate)
        defaults.set(hasRated, forKey: Key.hasRated)
        defaults.set(hasSentFeedback, forKey: Key.hasSentFeedback)
    }
}
