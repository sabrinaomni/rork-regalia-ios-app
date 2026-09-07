import Foundation

/// A single Scripture passage with a stable identifier for non-repeating rotation.
nonisolated struct Verse: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let text: String
    let reference: String
}

/// A written prayer used to close the daily session.
nonisolated struct DailyPrayer: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let title: String
    let body: String
}

/// A lie/truth pair used in the Renew Your Mind step (Romans 12:2).
nonisolated struct MindRenewal: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let lie: String
    let truth: String
    let reference: String
}
