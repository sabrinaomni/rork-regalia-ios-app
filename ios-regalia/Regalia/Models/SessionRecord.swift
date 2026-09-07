import Foundation

/// A completed (or in-progress) day of Regalia, kept in the Archive.
nonisolated struct SessionRecord: Identifiable, Codable, Hashable, Sendable {
    /// Day key in `yyyy-MM-dd` form — one record per calendar day.
    let id: String
    var date: Date
    var mood: Mood?
    var equippedPieces: [ArmourPiece]
    var moodVerse: Verse?
    var dailyVerse: Verse?
    var temptationVerse: Verse?
    var renewal: MindRenewal?
    var handedOver: String
    var prayer: DailyPrayer?
    /// Supporting verse of the day behind each equipped piece, keyed by `ArmourPiece.rawValue`.
    /// Optional so previously archived days keep decoding.
    var supportingVerses: [String: Verse]?
    var completedAt: Date?
    var minutesReclaimed: Int

    var isComplete: Bool { completedAt != nil }

    var equippedCount: Int { equippedPieces.count }

    /// The armour stage index (0…7) the mascot should render for this day.
    var mascotStage: Int { min(equippedPieces.count, 7) }

    nonisolated static func empty(for date: Date) -> SessionRecord {
        SessionRecord(
            id: SessionRecord.dayKey(for: date),
            date: Calendar.current.startOfDay(for: date),
            mood: nil,
            equippedPieces: [],
            moodVerse: nil,
            dailyVerse: nil,
            temptationVerse: nil,
            renewal: nil,
            handedOver: "",
            prayer: nil,
            supportingVerses: nil,
            completedAt: nil,
            minutesReclaimed: 0
        )
    }

    nonisolated static func dayKey(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}
