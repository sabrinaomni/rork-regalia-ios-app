import DeviceActivity
import Foundation
import ManagedSettings

/// Handles the two buttons on the Regalia block screen.
///
/// The primary button simply dismisses so the user can open Regalia and put the armour on.
/// The secondary button spends one of the weekly passes, lifts the shield from the single
/// app that was reached for, and asks DeviceActivity to re-shield it after five minutes of use.
nonisolated final class ShieldActionExtension: ShieldActionDelegate {
    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        switch action {
        case .primaryButtonPressed:
            completionHandler(.close)
        case .secondaryButtonPressed:
            completionHandler(grantPass(for: application) ? .close : .none)
        @unknown default:
            completionHandler(.close)
        }
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(.close)
    }

    /// Lifts the shield from one app for the length of a pass. Returns `false` when none are left.
    private func grantPass(for application: ApplicationToken) -> Bool {
        guard GuardBridge.spendPass() else { return false }

        GuardBridge.reclaimReleasedApplication()

        let store = GuardBridge.store
        var shielded = store.shield.applications ?? []
        shielded.remove(application)
        store.shield.applications = shielded
        GuardBridge.releaseApplication(application)

        startPassWindow(for: application)
        return true
    }

    /// Watches the released app and calls the monitor extension once the pass is used up.
    private func startPassWindow(for application: ApplicationToken) {
        let center = DeviceActivityCenter()
        center.stopMonitoring([GuardActivity.pass])

        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: [application],
            threshold: DateComponents(minute: GuardBridge.passMinutes)
        )

        do {
            try center.startMonitoring(
                GuardActivity.pass,
                during: schedule,
                events: [GuardActivity.passSpent: event]
            )
        } catch {
            // Monitoring is best-effort; the app re-closes the guard the next time it opens.
            GuardBridge.defaults.set(true, forKey: "guard.passMonitorFailed")
        }
    }
}
