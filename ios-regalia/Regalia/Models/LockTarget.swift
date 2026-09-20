import FamilyControls
import ManagedSettings
import SwiftUI

/// What the lock gate is standing in front of.
///
/// Apple's guidelines don't allow another company's app icon to be bundled into
/// Regalia, so the curated tiles use SF Symbols. When someone has chosen real apps
/// through Screen Time, the system can draw the genuine icon and name from an
/// `ApplicationToken` — that's the `screenTime` case, and it is always preferred.
nonisolated struct LockTarget: Identifiable, Hashable {
    enum Source: Hashable {
        /// A real app the person picked in Screen Time. The icon and name are
        /// rendered by the system; the token itself reveals neither to us.
        case screenTime(ApplicationToken)
        /// One of Regalia's own demo tiles, used before anything real is chosen.
        case preview(GuardedApp)
    }

    let id: String
    let source: Source

    init(token: ApplicationToken) {
        source = .screenTime(token)
        id = "token-\(token.hashValue)"
    }

    init(app: GuardedApp) {
        source = .preview(app)
        id = "preview-\(app.id)"
    }

    /// The real app's token, when there is one.
    var token: ApplicationToken? {
        if case .screenTime(let token) = source { return token }
        return nil
    }

    /// The headline over the gate. A real app's name is only ever known to the
    /// system, so its own label carries the name just beneath this line.
    var title: String {
        switch source {
        case .screenTime: "This app is locked"
        case .preview(let app): "\(app.name) is locked"
        }
    }

    /// The plate behind the lion, tinted to the app it stands for.
    var tint: Color {
        switch source {
        case .screenTime: RegaliaTheme.gold
        case .preview(let app): app.tint
        }
    }

    var symbol: String {
        switch source {
        case .screenTime: "app.dashed"
        case .preview(let app): app.symbol
        }
    }
}
