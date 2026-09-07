import Foundation
import ManagedSettings

extension ManagedSettingsStore.Name {
    /// The single shield store Regalia owns. Named so extensions target the same store.
    nonisolated(unsafe) static let regalia = Self("regalia")
}

/// State shared between the Regalia app and its Screen Time extensions through the App Group.
///
/// The extensions run as separate processes and cannot read the app's own `UserDefaults`,
/// so everything the shield screen needs is mirrored here whenever the app's state changes.
/// This file is duplicated verbatim in each extension target.
nonisolated enum GuardBridge {
    static let appGroupID = "group.app.rork.c9feujhlfbusu7b56fh6w"

    /// Minutes of usage a single unlock pass buys.
    static let passMinutes = 5
    static let weeklyPassAllowance = 3

    enum Key {
        static let isArmourOn = "guard.isArmourOn"
        static let armourCount = "guard.armourCount"
        static let headline = "guard.headline"
        static let verseText = "guard.verseText"
        static let verseReference = "guard.verseReference"
        static let passGrants = "guard.passGrants"
        static let releasedToken = "guard.releasedToken"
        static let passStartedAt = "guard.passStartedAt"
        static let realBlockingOn = "guard.realBlockingOn"
        static let passExpiryNote = "guard.passExpiryNote"
    }

    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroupID) ?? .standard
    }

    static var store: ManagedSettingsStore {
        ManagedSettingsStore(named: .regalia)
    }

    // MARK: - Mirrored session state

    static var isArmourOn: Bool {
        get { defaults.bool(forKey: Key.isArmourOn) }
        set { defaults.set(newValue, forKey: Key.isArmourOn) }
    }

    static var armourCount: Int {
        get { defaults.integer(forKey: Key.armourCount) }
        set { defaults.set(newValue, forKey: Key.armourCount) }
    }

    static var headline: String {
        get { defaults.string(forKey: Key.headline) ?? "The armour isn't on yet" }
        set { defaults.set(newValue, forKey: Key.headline) }
    }

    static var verseText: String {
        get {
            defaults.string(forKey: Key.verseText)
                ?? "No temptation has overtaken you except what is common to mankind. God is faithful; he will also provide a way out."
        }
        set { defaults.set(newValue, forKey: Key.verseText) }
    }

    static var verseReference: String {
        get { defaults.string(forKey: Key.verseReference) ?? "1 Corinthians 10:13" }
        set { defaults.set(newValue, forKey: Key.verseReference) }
    }

    static var realBlockingOn: Bool {
        get { defaults.bool(forKey: Key.realBlockingOn) }
        set { defaults.set(newValue, forKey: Key.realBlockingOn) }
    }

    static var wantsPassExpiryNote: Bool {
        get { defaults.object(forKey: Key.passExpiryNote) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Key.passExpiryNote) }
    }

    // MARK: - Unlock passes

    static var passGrants: [Date] {
        get {
            guard let data = defaults.data(forKey: Key.passGrants),
                  let dates = try? JSONDecoder().decode([Date].self, from: data) else { return [] }
            return dates
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: Key.passGrants)
        }
    }

    static var passesLeftThisWeek: Int {
        let weekAgo = Date().addingTimeInterval(-7 * 24 * 3600)
        let recent = passGrants.filter { $0 > weekAgo }.count
        return max(weeklyPassAllowance - recent, 0)
    }

    /// Spends one weekly pass. Returns `false` when the allowance is exhausted.
    @discardableResult
    static func spendPass() -> Bool {
        guard passesLeftThisWeek > 0 else { return false }
        passGrants = passGrants + [Date()]
        defaults.set(Date(), forKey: Key.passStartedAt)
        return true
    }

    static var passStartedAt: Date? {
        defaults.object(forKey: Key.passStartedAt) as? Date
    }

    // MARK: - The app released by the active pass

    static var releasedTokenData: Data? {
        get { defaults.data(forKey: Key.releasedToken) }
        set {
            if let newValue {
                defaults.set(newValue, forKey: Key.releasedToken)
            } else {
                defaults.removeObject(forKey: Key.releasedToken)
            }
        }
    }

    static func releaseApplication(_ token: ApplicationToken) {
        releasedTokenData = try? JSONEncoder().encode(token)
    }

    static var releasedApplication: ApplicationToken? {
        guard let data = releasedTokenData else { return nil }
        return try? JSONDecoder().decode(ApplicationToken.self, from: data)
    }

    /// Puts the released app back behind the shield and clears the pass.
    static func reclaimReleasedApplication() {
        if let token = releasedApplication {
            var shielded = store.shield.applications ?? []
            shielded.insert(token)
            store.shield.applications = shielded
        }
        releasedTokenData = nil
        defaults.removeObject(forKey: Key.passStartedAt)
    }
}
