import DeviceActivity
import FamilyControls
import Foundation
import ManagedSettings
import Observation

/// Owns the real, OS-level side of the guard: Screen Time authorization, the user's
/// app/category/website selection, the shield itself, and the nightly re-lock schedule.
///
/// Everything degrades quietly. When Apple's Family Controls entitlement isn't active
/// (simulator, or an account still waiting on approval) the app stays in preview mode
/// and the in-app lock gate carries the experience.
@Observable
final class ScreenTimeGuard {
    /// What the guard can actually do right now.
    enum Mode: Equatable {
        /// Screen Time has never been asked for, or the device can't provide it.
        case preview
        /// The user declined, or the entitlement isn't active on this build.
        case denied(String)
        /// Authorized, but nothing has been chosen to block yet.
        case idle
        /// Authorized with a selection — the shield is real.
        case live
    }

    private(set) var mode: Mode = .preview
    private(set) var lastError: String?

    /// The apps, categories, and websites picked through Apple's own picker.
    var selection: FamilyActivitySelection {
        didSet { persistSelection() }
    }

    private let center = AuthorizationCenter.shared

    init() {
        selection = ScreenTimeGuard.loadSelection()
        refreshMode()
    }

    // MARK: - Derived

    var isAuthorized: Bool {
        if case .denied = mode { return false }
        return mode == .live || mode == .idle
    }

    var isLive: Bool { mode == .live }

    var selectionCount: Int {
        selection.applicationTokens.count
            + selection.categoryTokens.count
            + selection.webDomainTokens.count
    }

    var statusTitle: String {
        switch mode {
        case .live: "Blocking is live on this iPhone"
        case .idle: "Screen Time is on — nothing chosen yet"
        case .denied: "Screen Time permission is off"
        case .preview: "Preview mode"
        }
    }

    var statusDetail: String {
        switch mode {
        case .live:
            "\(selectionCount) item\(selectionCount == 1 ? "" : "s") stay shut until today's armour is on."
        case .idle:
            "Choose the apps, categories, or sites you want locked."
        case .denied(let reason):
            reason
        case .preview:
            "Regalia guards inside the app. Turn on Screen Time to lock apps across your whole phone."
        }
    }

    // MARK: - Authorization

    func refreshMode() {
        switch center.authorizationStatus {
        case .approved:
            mode = selectionCount > 0 ? .live : .idle
        case .denied:
            mode = .denied("Allow Regalia in Settings → Screen Time to lock apps for real.")
        case .notDetermined:
            mode = .preview
        @unknown default:
            mode = .preview
        }
    }

    /// Asks the user for individual Screen Time authorization.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            try await center.requestAuthorization(for: .individual)
            lastError = nil
            refreshMode()
            return isAuthorized
        } catch {
            lastError = ScreenTimeGuard.describe(error)
            mode = .denied(ScreenTimeGuard.describe(error))
            return false
        }
    }

    // MARK: - Shielding

    /// Brings the OS shield in line with today's state.
    /// - Parameters:
    ///   - isArmourOn: whether today's session is finished.
    ///   - bedtimeMinutes: when the guard should close again tonight.
    func reconcile(isArmourOn: Bool, bedtimeMinutes: Int) {
        GuardBridge.realBlockingOn = isLive
        guard isAuthorized else { return }

        if isArmourOn {
            releaseEverything()
        } else {
            applyShield()
        }
        scheduleBedtimeRelock(bedtimeMinutes: bedtimeMinutes)
    }

    /// Locks every selected app, category, and website.
    func applyShield() {
        guard isAuthorized else { return }
        let store = GuardBridge.store
        store.shield.applications = selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        store.shield.applicationCategories = selection.categoryTokens.isEmpty
            ? nil
            : .specific(selection.categoryTokens)
        store.shield.webDomains = selection.webDomainTokens.isEmpty ? nil : selection.webDomainTokens
        GuardBridge.releasedTokenData = nil
    }

    /// Clears the shield — used when the armour is on for the day.
    func releaseEverything() {
        let store = GuardBridge.store
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        store.shield.webDomains = nil
        GuardBridge.releasedTokenData = nil
        DeviceActivityCenter().stopMonitoring([GuardActivity.pass])
    }

    /// Lifts the shield for the length of one pass, spent from inside the app.
    func releaseForPass() {
        guard isAuthorized else { return }
        releaseEverything()
    }

    /// Registers the repeating window that closes the guard again each night.
    func scheduleBedtimeRelock(bedtimeMinutes: Int) {
        guard isAuthorized else { return }
        let hour = bedtimeMinutes / 60
        let minute = bedtimeMinutes % 60
        let endMinute = (minute + 59) % 60
        let endHour = (hour + (minute + 59 >= 60 ? 1 : 0) + 23) % 24

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: hour, minute: minute),
            intervalEnd: DateComponents(hour: endHour, minute: endMinute),
            repeats: true
        )

        let activityCenter = DeviceActivityCenter()
        activityCenter.stopMonitoring([GuardActivity.bedtime])
        do {
            try activityCenter.startMonitoring(GuardActivity.bedtime, during: schedule)
            lastError = nil
        } catch {
            lastError = ScreenTimeGuard.describe(error)
        }
    }

    // MARK: - Persistence

    private func persistSelection() {
        guard let data = try? JSONEncoder().encode(selection) else { return }
        GuardBridge.defaults.set(data, forKey: "guard.selection")
        refreshMode()
    }

    private static func loadSelection() -> FamilyActivitySelection {
        guard let data = GuardBridge.defaults.data(forKey: "guard.selection"),
              let decoded = try? JSONDecoder().decode(FamilyActivitySelection.self, from: data) else {
            return FamilyActivitySelection()
        }
        return decoded
    }

    func forget() {
        selection = FamilyActivitySelection()
        releaseEverything()
        DeviceActivityCenter().stopMonitoring([GuardActivity.bedtime, GuardActivity.pass])
        refreshMode()
    }

    /// Turns Apple's opaque Family Controls errors into something a person can act on.
    private static func describe(_ error: Error) -> String {
        guard let familyError = error as? FamilyControlsError else {
            return "Screen Time is unavailable on this device right now."
        }
        switch familyError {
        case .unavailable:
            return "This build can't use Screen Time yet — Apple has to approve app blocking for your developer account."
        case .authorizationCanceled, .authorizationConflict:
            return "Screen Time permission wasn't granted. You can turn it on any time."
        case .invalidAccountType:
            return "Screen Time needs to be set up for this Apple Account first."
        case .restricted:
            return "Screen Time is restricted on this device."
        case .networkError:
            return "Couldn't reach Apple to confirm Screen Time. Try again on a connection."
        @unknown default:
            return "Screen Time is unavailable on this device right now."
        }
    }
}
