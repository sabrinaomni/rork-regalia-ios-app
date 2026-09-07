import DeviceActivity
import Foundation

/// Names shared by the app, the shield action extension, and the monitor extension.
nonisolated enum GuardActivity {
    /// Repeating daily window that re-closes the guard at the user's bedtime hour.
    static let bedtime = DeviceActivityName("regalia.bedtime")
    /// Window that watches a single released app while an unlock pass is burning down.
    static let pass = DeviceActivityName("regalia.pass")
    /// Fires once the released app has been used for the length of a pass.
    static let passSpent = DeviceActivityEvent.Name("regalia.pass.spent")
}
