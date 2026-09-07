import DeviceActivity
import Foundation
import ManagedSettings
import UserNotifications

/// Runs in the background for the two things the app cannot do while closed:
/// closing the guard again at bedtime, and ending an unlock pass once it is spent.
nonisolated final class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        guard activity == GuardActivity.bedtime else { return }
        GuardBridge.isArmourOn = false
        GuardBridge.reclaimReleasedApplication()
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)
        guard event == GuardActivity.passSpent else { return }

        GuardBridge.reclaimReleasedApplication()
        DeviceActivityCenter().stopMonitoring([GuardActivity.pass])
        postPassEndedNotice()
    }

    private func postPassEndedNotice() {
        guard GuardBridge.wantsPassExpiryNote else { return }

        let content = UNMutableNotificationContent()
        content.title = "Your pass is up"
        content.body = "The guard is closed again. The armour is still waiting whenever you're ready."
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "regalia.pass.ended.\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
