import Foundation
import Observation
import SwiftUI
import WidgetKit

/// Single source of truth for the profile, today's session, and the archive.
/// Persists to `UserDefaults` as JSON — small, local, and private to the device.
@Observable
final class RegaliaStore {
    private(set) var profile: OnboardingProfile
    private(set) var records: [SessionRecord]
    private(set) var today: SessionRecord

    /// Verse / prayer ids already used, so the daily rotation never repeats until exhausted.
    private var usedDailyVerseIDs: [String]
    private var usedPrayerIDs: [String]
    private var usedRenewalIDs: [String]
    /// The same no-repeat treatment for the verses that used to be drawn at random.
    private var usedTemptationIDs: [String]
    private var usedMoodVerseIDs: [String]

    /// Timestamps of the temporary unlock passes spent, used for the weekly allowance.
    /// Mirrored through the App Group so passes spent on the OS block screen count too.
    private(set) var unlockGrants: [Date]

    /// Set while a temporary unlock pass is active.
    var activeUnlockUntil: Date?

    /// True for one hand-off only: the covenant was just signed, so Today should
    /// open the first session automatically. Never persisted — a relaunch clears it.
    var wantsSessionAfterOnboarding: Bool = false

    /// Real-blocking and reminder settings.
    private(set) var guardPreferences: GuardPreferences

    static let weeklyUnlockAllowance = GuardBridge.weeklyPassAllowance
    static let unlockDuration: TimeInterval = TimeInterval(GuardBridge.passMinutes) * 60
    static let sessionMinutes = 8

    private let defaults: UserDefaults
    private enum Key {
        static let profile = "regalia.profile"
        static let records = "regalia.records"
        static let usedVerses = "regalia.usedVerses"
        static let usedPrayers = "regalia.usedPrayers"
        static let usedRenewals = "regalia.usedRenewals"
        static let usedTemptations = "regalia.usedTemptations"
        static let usedMoodVerses = "regalia.usedMoodVerses"
        static let unlocks = "regalia.unlocks"
        static let guardPreferences = "regalia.guardPreferences"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        profile = RegaliaStore.decode(OnboardingProfile.self, from: defaults, key: Key.profile) ?? OnboardingProfile()
        records = RegaliaStore.decode([SessionRecord].self, from: defaults, key: Key.records) ?? []
        usedDailyVerseIDs = defaults.stringArray(forKey: Key.usedVerses) ?? []
        usedPrayerIDs = defaults.stringArray(forKey: Key.usedPrayers) ?? []
        usedRenewalIDs = defaults.stringArray(forKey: Key.usedRenewals) ?? []
        usedTemptationIDs = defaults.stringArray(forKey: Key.usedTemptations) ?? []
        usedMoodVerseIDs = defaults.stringArray(forKey: Key.usedMoodVerses) ?? []
        guardPreferences = RegaliaStore.decode(GuardPreferences.self, from: defaults, key: Key.guardPreferences)
            ?? GuardPreferences()

        let legacyGrants = RegaliaStore.decode([Date].self, from: defaults, key: Key.unlocks) ?? []
        let sharedGrants = GuardBridge.passGrants
        unlockGrants = sharedGrants.isEmpty ? legacyGrants : sharedGrants
        if sharedGrants.isEmpty, !legacyGrants.isEmpty {
            GuardBridge.passGrants = legacyGrants
        }

        let storedRecords = RegaliaStore.decode([SessionRecord].self, from: defaults, key: Key.records) ?? []
        let key = SessionRecord.dayKey(for: Date())
        today = storedRecords.first(where: { $0.id == key }) ?? SessionRecord.empty(for: Date())

        mirrorGuardState()
    }

    // MARK: - Derived state

    var isOnboarded: Bool { profile.isComplete }

    var isArmourComplete: Bool { today.isComplete }

    /// Days completed in an unbroken run ending today or yesterday.
    var streak: Int {
        let completed = Set(records.filter(\.isComplete).map(\.id))
        var count = 0
        var cursor = Calendar.current.startOfDay(for: Date())
        if !completed.contains(SessionRecord.dayKey(for: cursor)) {
            guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { return 0 }
            cursor = yesterday
        }
        while completed.contains(SessionRecord.dayKey(for: cursor)) {
            count += 1
            guard let previous = Calendar.current.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// The day number of the user's walk (1-based), counting from the first record.
    var dayNumber: Int {
        guard let first = records.map(\.date).min() else { return 1 }
        let days = Calendar.current.dateComponents([.day], from: first, to: Date()).day ?? 0
        return max(days + 1, 1)
    }

    var versesKept: Int {
        records.filter(\.isComplete).reduce(0) { total, record in
            total + [record.moodVerse, record.dailyVerse, record.temptationVerse].compactMap { $0 }.count
        }
    }

    var minutesReclaimed: Int {
        records.reduce(0) { $0 + $1.minutesReclaimed }
    }

    var unlocksLeftThisWeek: Int {
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let recent = unlockGrants.filter { $0 > weekAgo }.count
        return max(RegaliaStore.weeklyUnlockAllowance - recent, 0)
    }

    /// The line the OS block screen shows above the Scripture.
    var guardHeadline: String {
        let name = profile.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "The armour isn't on yet" : "\(name), the armour isn't on yet"
    }

    var isTemporarilyUnlocked: Bool {
        guard let until = activeUnlockUntil else { return false }
        return until > Date()
    }

    /// True when yesterday came and went without a completed session — and the
    /// walk had already begun before yesterday, so a brand-new user never starts
    /// with a guilt note.
    var missedYesterday: Bool {
        guard let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Calendar.current.startOfDay(for: Date())) else { return false }
        let key = SessionRecord.dayKey(for: yesterday)
        if let record = records.first(where: { $0.id == key }) { return !record.isComplete }
        return records.contains { $0.date < Calendar.current.startOfDay(for: yesterday) }
    }

    var completedRecords: [SessionRecord] {
        records.filter(\.isComplete).sorted { $0.date > $1.date }
    }

    // MARK: - Onboarding

    func saveProfile(_ newProfile: OnboardingProfile) {
        var updated = newProfile
        updated.isComplete = true
        profile = updated
        persistProfile()
        if today.mood == nil {
            setMood(updated.baselineMood)
        }
        wantsSessionAfterOnboarding = !today.isComplete
    }

    func updateProfile(_ mutate: (inout OnboardingProfile) -> Void) {
        var copy = profile
        mutate(&copy)
        profile = copy
        persistProfile()
        mirrorGuardState()
    }

    func updateGuardPreferences(_ mutate: (inout GuardPreferences) -> Void) {
        var copy = guardPreferences
        mutate(&copy)
        guardPreferences = copy
        RegaliaStore.encode(copy, to: defaults, key: Key.guardPreferences)
        mirrorGuardState()
    }

    // MARK: - Daily flow

    /// Rolls today's record over when the calendar day changes.
    func refreshForNewDayIfNeeded() {
        let key = SessionRecord.dayKey(for: Date())
        guard today.id != key else { return }
        commitToday()
        if let existing = records.first(where: { $0.id == key }) {
            today = existing
        } else {
            today = SessionRecord.empty(for: Date())
        }
        activeUnlockUntil = nil
    }

    func setMood(_ mood: Mood) {
        today.mood = mood
        today.moodVerse = RegaliaStore.nextItem(from: ScriptureLibrary.verses(for: mood), used: &usedMoodVerseIDs)
        defaults.set(usedMoodVerseIDs, forKey: Key.usedMoodVerses)
        commitToday()
    }

    /// Prepares the non-repeating daily verse, prayer, renewal, and temptation Scripture.
    func prepareSessionContent() {
        if today.dailyVerse == nil {
            let verse = RegaliaStore.nextItem(from: ScriptureLibrary.daily, used: &usedDailyVerseIDs)
            today.dailyVerse = verse
            defaults.set(usedDailyVerseIDs, forKey: Key.usedVerses)
        }
        if today.prayer == nil {
            let reason = profile.reasons.first
            if let prayer = PrayerLibrary.nextPrayer(
                mood: today.mood,
                reason: reason,
                name: profile.name,
                used: &usedPrayerIDs
            ) {
                today.prayer = prayer
                defaults.set(usedPrayerIDs, forKey: Key.usedPrayers)
            }
        }
        if today.renewal == nil {
            let renewal = RegaliaStore.nextItem(from: ScriptureLibrary.renewals, used: &usedRenewalIDs)
            today.renewal = renewal
            defaults.set(usedRenewalIDs, forKey: Key.usedRenewals)
        }
        if today.temptationVerse == nil {
            today.temptationVerse = RegaliaStore.nextItem(from: ScriptureLibrary.temptation, used: &usedTemptationIDs)
            defaults.set(usedTemptationIDs, forKey: Key.usedTemptations)
        }
        if today.moodVerse == nil, let mood = today.mood {
            today.moodVerse = RegaliaStore.nextItem(from: ScriptureLibrary.verses(for: mood), used: &usedMoodVerseIDs)
            defaults.set(usedMoodVerseIDs, forKey: Key.usedMoodVerses)
        }
        commitToday()
    }

    func equip(_ piece: ArmourPiece) {
        guard !today.equippedPieces.contains(piece) else { return }
        today.equippedPieces.append(piece)
        if let verse = ScriptureLibrary.supportingVerse(for: piece, on: today.date) {
            var supporting = today.supportingVerses ?? [:]
            supporting[piece.rawValue] = verse
            today.supportingVerses = supporting
        }
        commitToday()
    }

    func setHandedOver(_ text: String) {
        today.handedOver = text
        commitToday()
    }

    func completeSession() {
        guard today.completedAt == nil else { return }
        today.completedAt = Date()
        today.minutesReclaimed = RegaliaStore.sessionMinutes
        activeUnlockUntil = nil
        commitToday()
    }

    /// Discards progress for today so the user can walk through the session again.
    func resetToday() {
        today = SessionRecord.empty(for: Date())
        commitToday()
    }

    // MARK: - Lock gate

    @discardableResult
    func spendUnlockPass() -> Bool {
        guard GuardBridge.spendPass() else { return false }
        unlockGrants = GuardBridge.passGrants
        activeUnlockUntil = Date().addingTimeInterval(RegaliaStore.unlockDuration)
        RegaliaStore.encode(unlockGrants, to: defaults, key: Key.unlocks)
        mirrorGuardState()
        return true
    }

    /// Picks up passes spent on the OS block screen while the app was closed.
    func syncPassesFromGuard() {
        let shared = GuardBridge.passGrants
        guard shared != unlockGrants else { return }
        unlockGrants = shared
        RegaliaStore.encode(unlockGrants, to: defaults, key: Key.unlocks)
    }

    /// Mirrors everything the Screen Time extensions need into the App Group.
    func mirrorGuardState() {
        GuardBridge.isArmourOn = today.isComplete
        GuardBridge.armourCount = today.equippedCount
        GuardBridge.headline = guardHeadline
        GuardBridge.wantsPassExpiryNote = guardPreferences.passExpiryNote

        if let verse = today.temptationVerse ?? ScriptureLibrary.temptation.first {
            GuardBridge.verseText = verse.text
            GuardBridge.verseReference = verse.reference
        }
    }

    func isGuarded(_ app: GuardedApp) -> Bool {
        profile.guardedAppIDs.contains(app.id) && !isArmourComplete && !isTemporarilyUnlocked
    }

    // MARK: - Maintenance

    func eraseEverything() {
        profile = OnboardingProfile()
        records = []
        today = SessionRecord.empty(for: Date())
        usedDailyVerseIDs = []
        usedPrayerIDs = []
        usedRenewalIDs = []
        usedTemptationIDs = []
        usedMoodVerseIDs = []
        unlockGrants = []
        activeUnlockUntil = nil
        guardPreferences = GuardPreferences()
        GuardBridge.passGrants = []
        GuardBridge.releasedTokenData = nil
        [Key.profile, Key.records, Key.usedVerses, Key.usedPrayers, Key.usedRenewals, Key.usedTemptations, Key.usedMoodVerses, Key.unlocks, Key.guardPreferences]
            .forEach { defaults.removeObject(forKey: $0) }
        ["widget.verseText", "widget.verseReference", "widget.isArmourOn", "widget.equippedCount", "widget.streak"]
            .forEach { GuardBridge.defaults.removeObject(forKey: $0) }
        mirrorGuardState()
        mirrorWidgetSnapshot()
    }

    // MARK: - Persistence

    private func commitToday() {
        if let index = records.firstIndex(where: { $0.id == today.id }) {
            records[index] = today
        } else {
            records.append(today)
        }
        RegaliaStore.encode(records, to: defaults, key: Key.records)
        mirrorGuardState()
        mirrorWidgetSnapshot()
    }

    // MARK: - Widget snapshot

    private var lastWidgetFingerprint: String?

    /// Mirrors the kept verse and today's progress into the App Group for the
    /// Home Screen widget, then asks WidgetKit to refresh when anything changed.
    private func mirrorWidgetSnapshot() {
        let shared = GuardBridge.defaults
        let verse = today.dailyVerse
        shared.set(verse?.text ?? "", forKey: "widget.verseText")
        shared.set(verse?.reference ?? "", forKey: "widget.verseReference")
        shared.set(today.isComplete, forKey: "widget.isArmourOn")
        shared.set(today.equippedCount, forKey: "widget.equippedCount")
        shared.set(streak, forKey: "widget.streak")

        let fingerprint = "\(verse?.id ?? "")|\(today.isComplete)|\(today.equippedCount)|\(streak)"
        guard fingerprint != lastWidgetFingerprint else { return }
        lastWidgetFingerprint = fingerprint
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func persistProfile() {
        RegaliaStore.encode(profile, to: defaults, key: Key.profile)
    }

    private nonisolated static func decode<T: Decodable>(_ type: T.Type, from defaults: UserDefaults, key: String) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private nonisolated static func encode<T: Encodable>(_ value: T, to defaults: UserDefaults, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        defaults.set(data, forKey: key)
    }

    /// Picks the next unused item, resetting the cycle once every item has been seen.
    private nonisolated static func nextItem<T: Identifiable>(from pool: [T], used: inout [String]) -> T? where T.ID == String {
        let remaining = pool.filter { !used.contains($0.id) }
        let candidates = remaining.isEmpty ? pool : remaining
        if remaining.isEmpty { used = [] }
        guard let pick = candidates.randomElement() else { return nil }
        used.append(pick.id)
        return pick
    }
}
