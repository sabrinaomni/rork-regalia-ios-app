import Foundation
import Observation
import UserNotifications

/// Schedules the day's nudges. Each refresh rebuilds the whole set, so finishing
/// a session silences today's evening and streak reminders immediately, and the
/// morning reminder is a one-shot appointment written for one specific morning —
/// never a repeating trigger that nags days that are already finished.
@Observable
final class ReminderScheduler {
    enum Permission: Equatable {
        case notAsked, granted, denied
    }

    private(set) var permission: Permission = .notAsked

    private enum ID {
        static let daily = "regalia.daily"
        static let evening = "regalia.evening"
        static let streak = "regalia.streak"
        static let milestone = "regalia.milestone"
    }

    /// The notification category that gives every reminder its "Stand now" button.
    static let standCategoryID = "regalia.stand"
    static let standActionID = "regalia.stand.now"
    /// Posted on the main actor when a Regalia reminder is tapped — body or
    /// "Stand now" — so the UI can open today's session directly.
    static let openSessionSignal = Notification.Name("regalia.openSessionSignal")

    /// Hour the evening nudge lands, if the armour still isn't on.
    private static let eveningHour = 20
    private static let eveningMinute = 30
    /// Later, sharper warning used only when a real streak is on the line.
    private static let streakHour = 21
    private static let streakMinute = 45
    /// Unbroken-day marks worth celebrating the morning after.
    private static let milestones: Set<Int> = [3, 7, 14, 30]

    private let center = UNUserNotificationCenter.current()

    init() {
        registerStandCategory()
    }

    func refreshPermission() async {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral: permission = .granted
        case .denied: permission = .denied
        default: permission = .notAsked
        }
    }

    @discardableResult
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            permission = granted ? .granted : .denied
            return granted
        } catch {
            permission = .denied
            return false
        }
    }

    /// Rebuilds every pending reminder from the current state of the walk.
    func refresh(
        preferences: GuardPreferences,
        dailyMinutes: Int,
        verseLine: String?,
        verseReference: String?,
        name: String,
        isArmourOn: Bool,
        streak: Int,
        missedYesterday: Bool
    ) {
        center.removePendingNotificationRequests(
            withIdentifiers: [ID.daily, ID.evening, ID.streak, ID.milestone]
        )
        GuardBridge.wantsPassExpiryNote = preferences.passExpiryNote

        guard preferences.remindersEnabled, permission == .granted else { return }

        if let milestoneDate = nextMilestoneDate(
            streak: streak,
            isArmourOn: isArmourOn,
            yesterdayComplete: !missedYesterday,
            dailyMinutes: dailyMinutes
        ) {
            scheduleMilestone(streak: streak, at: milestoneDate)
            // The celebration carries that morning; the next ordinary reminder
            // waits for the day after so the two never arrive together.
            let dayAfter = nextDailyOccurrence(after: milestoneDate, dailyMinutes: dailyMinutes)
            scheduleDaily(
                minutes: dailyMinutes,
                verseLine: verseLine,
                verseReference: verseReference,
                name: name,
                isGrace: false,
                fireDate: dayAfter
            )
        } else {
            scheduleDaily(
                minutes: dailyMinutes,
                verseLine: verseLine,
                verseReference: verseReference,
                name: name,
                isGrace: missedYesterday && !isArmourOn,
                fireDate: nextDailyFireDate(dailyMinutes: dailyMinutes, isArmourOn: isArmourOn)
            )
        }

        if preferences.eveningNudge {
            scheduleEvening(isArmourOn: isArmourOn)
        }
        if preferences.streakWarning, streak >= 2, !isArmourOn {
            scheduleStreakWarning(streak: streak)
        }
    }

    func cancelAll() {
        center.removePendingNotificationRequests(
            withIdentifiers: [ID.daily, ID.evening, ID.streak, ID.milestone]
        )
    }

    /// Fallback note for a pass spent inside the app, where no monitor event fires.
    func schedulePassEndNote(in minutes: Int) {
        guard permission == .granted, GuardBridge.wantsPassExpiryNote else { return }
        let content = UNMutableNotificationContent()
        content.title = "Your pass is up"
        content.body = "The guard is closed again. The armour is still waiting whenever you're ready."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(TimeInterval(minutes) * 60, 60),
            repeats: false
        )
        center.add(UNNotificationRequest(identifier: "regalia.pass.ended", content: content, trigger: trigger))
    }

    // MARK: - Morning reminder

    /// The next morning the reminder should ring: later today if that slot
    /// hasn't passed and the armour is still off, otherwise tomorrow. A day
    /// that ended with the armour on never schedules one for itself — standing
    /// triggers a refresh that clears the pending morning note.
    private func nextDailyFireDate(dailyMinutes: Int, isArmourOn: Bool) -> Date? {
        let calendar = Calendar.current
        guard let todayAtTime = calendar.date(
            bySettingHour: dailyMinutes / 60,
            minute: dailyMinutes % 60,
            second: 0,
            of: Date()
        ) else { return nil }

        if !isArmourOn, todayAtTime > Date() {
            return todayAtTime
        }
        return calendar.date(byAdding: .day, value: 1, to: todayAtTime)
    }

    private func scheduleDaily(
        minutes: Int,
        verseLine: String?,
        verseReference: String?,
        name: String,
        isGrace: Bool,
        fireDate: Date?
    ) {
        guard let fireDate else { return }
        let copy = Self.dailyCopy(
            name: name,
            verseLine: verseLine,
            verseReference: verseReference,
            isGrace: isGrace,
            for: fireDate
        )

        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = ReminderScheduler.standCategoryID

        center.add(
            UNNotificationRequest(
                identifier: ID.daily,
                content: content,
                trigger: ReminderScheduler.trigger(for: fireDate)
            )
        )
    }

    /// One of several gentle openings, chosen by the day so the same sentence
    /// never lands two mornings running. A missed day shifts the whole tone —
    /// no guilt, no streak shaming, just the invitation back.
    private static func dailyCopy(
        name: String,
        verseLine: String?,
        verseReference: String?,
        isGrace: Bool,
        for date: Date
    ) -> (title: String, body: String) {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: date) ?? 0
        let firstName = name.trimmingCharacters(in: .whitespaces)
        let verse = verseLine ?? ""
        let reference = verseReference ?? ""

        if isGrace {
            let titles = ["Mercy this morning", "Today is still yours", "Start again, standing"]
            let bodies = [
                "Yesterday came and went. That's what mercy is for. Eight minutes and today stands covered.",
                "One quiet day doesn't unmake the walk. The armour is still yours — put it on.",
                "No guilt this morning. Just an invitation: eight minutes and you're standing again.",
            ]
            return (titles[day % titles.count], bodies[day % bodies.count])
        }

        switch day % 4 {
        case 1:
            let body = verse.isEmpty
                ? "Eight quiet minutes. Put the armour on before the day puts its weight on you."
                : "\(verse)\(reference.isEmpty ? "" : " — \(reference)")"
            return ("Before the world gets your attention", body)
        case 2:
            return ("The armour is on the floor", "It won't lift itself. Eight minutes and you stand covered.")
        case 3:
            let body = verse.isEmpty
                ? "Stand before you scroll. The armour is waiting."
                : "Stand before you scroll: \(verse)"
            return ("A quiet eight minutes", body)
        default:
            let title = firstName.isEmpty ? "Your Regalia is waiting" : "\(firstName), your Regalia is waiting"
            let body = verse.isEmpty
                ? "Seven pieces, eight minutes. Put the armour on before the world gets your attention."
                : verse
            return (title, body)
        }
    }

    // MARK: - Milestones

    /// The morning a milestone celebration should land, if one was just earned:
    /// the day after the streak hit the mark. `nil` when there's nothing to
    /// celebrate — a break resets the ladder, and the next mark is earned fresh.
    private func nextMilestoneDate(
        streak: Int,
        isArmourOn: Bool,
        yesterdayComplete: Bool,
        dailyMinutes: Int
    ) -> Date? {
        guard ReminderScheduler.milestones.contains(streak) else { return nil }
        let calendar = Calendar.current
        guard let todayAtTime = calendar.date(
            bySettingHour: dailyMinutes / 60,
            minute: dailyMinutes % 60,
            second: 0,
            of: Date()
        ) else { return nil }

        if isArmourOn {
            // The streak includes today, so the milestone was reached today —
            // celebrate tomorrow morning.
            return calendar.date(byAdding: .day, value: 1, to: todayAtTime)
        }

        // Armour off: the streak ends yesterday, so the milestone landed
        // yesterday — celebrate this morning, but only while the slot is ahead.
        guard yesterdayComplete, todayAtTime > Date() else { return nil }
        return todayAtTime
    }

    private func scheduleMilestone(streak: Int, at fireDate: Date) {
        let copy = ReminderScheduler.milestoneCopy(streak: streak)
        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = ReminderScheduler.standCategoryID

        center.add(
            UNNotificationRequest(
                identifier: ID.milestone,
                content: content,
                trigger: ReminderScheduler.trigger(for: fireDate)
            )
        )
    }

    private static func milestoneCopy(streak: Int) -> (title: String, body: String) {
        switch streak {
        case 3: ("Three days standing", "Three days of putting the armour on. A rhythm is forming — keep standing.")
        case 7: ("Seven days standing", "A full week armoured. What took effort is becoming who you are.")
        case 14: ("Fourteen days standing", "Two weeks of standing, day after day. The old doors are swinging shut.")
        case 30: ("Thirty days standing", "A month armoured. This isn't a streak anymore — it's a posture.")
        default: ("\(streak) days standing", "Day after day, you stand. Keep going.")
        }
    }

    /// The first daily-time occurrence on the day after the given date.
    private func nextDailyOccurrence(after date: Date, dailyMinutes: Int) -> Date? {
        let calendar = Calendar.current
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) else { return nil }
        return calendar.date(
            bySettingHour: dailyMinutes / 60,
            minute: dailyMinutes % 60,
            second: 0,
            of: nextDay
        )
    }

    // MARK: - Evening + streak

    private func scheduleEvening(isArmourOn: Bool) {
        guard let fireDate = nextDate(
            hour: ReminderScheduler.eveningHour,
            minute: ReminderScheduler.eveningMinute,
            skipToday: isArmourOn
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "The armour is still on the floor"
        content.body = "There's still time today. Eight minutes and you stand covered."
        content.sound = .default
        content.categoryIdentifier = ReminderScheduler.standCategoryID

        center.add(
            UNNotificationRequest(
                identifier: ID.evening,
                content: content,
                trigger: ReminderScheduler.trigger(for: fireDate)
            )
        )
    }

    private func scheduleStreakWarning(streak: Int) {
        guard let fireDate = nextDate(
            hour: ReminderScheduler.streakHour,
            minute: ReminderScheduler.streakMinute,
            skipToday: false
        ), Calendar.current.isDateInToday(fireDate) else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(streak) days standing"
        content.body = "Don't let tonight be the break. The session is short and it's waiting."
        content.sound = .default
        content.categoryIdentifier = ReminderScheduler.standCategoryID

        center.add(
            UNNotificationRequest(
                identifier: ID.streak,
                content: content,
                trigger: ReminderScheduler.trigger(for: fireDate)
            )
        )
    }

    // MARK: - "Stand now" category

    /// Registers the category every reminder carries, so long-pressing any of
    /// them offers "Stand now" — a foreground action that opens the session.
    private func registerStandCategory() {
        let stand = UNNotificationAction(
            identifier: ReminderScheduler.standActionID,
            title: "Stand now",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: ReminderScheduler.standCategoryID,
            actions: [stand],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }

    // MARK: - Helpers

    /// The next occurrence of an hour/minute, optionally skipping straight to tomorrow.
    private func nextDate(hour: Int, minute: Int, skipToday: Bool) -> Date? {
        let calendar = Calendar.current
        let today = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: Date())
        guard let today else { return nil }
        if !skipToday, today > Date() {
            return today
        }
        return calendar.date(byAdding: .day, value: 1, to: today)
    }

    private static func trigger(for date: Date) -> UNCalendarNotificationTrigger {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    }
}
