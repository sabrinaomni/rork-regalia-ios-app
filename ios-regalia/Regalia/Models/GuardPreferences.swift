import Foundation

/// Settings for the real device guard and the reminder set.
/// Stored separately from `OnboardingProfile` so existing profiles keep decoding cleanly.
nonisolated struct GuardPreferences: Codable, Equatable, Sendable {
    /// The user has been through the Screen Time step and wants the real lock.
    var realBlockingRequested: Bool = false
    /// Minutes from midnight when the guard closes again for the night.
    var bedtimeMinutes: Int = 22 * 60

    var remindersEnabled: Bool = true
    var eveningNudge: Bool = true
    var streakWarning: Bool = true
    var passExpiryNote: Bool = true

    var bedtimeDate: Date {
        Calendar.current.date(
            bySettingHour: bedtimeMinutes / 60,
            minute: bedtimeMinutes % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    var bedtimeLabel: String {
        bedtimeDate.formatted(date: .omitted, time: .shortened)
    }
}
