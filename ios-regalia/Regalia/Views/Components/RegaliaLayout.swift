import SwiftUI

/// One spacing and art-band scale for the whole app, so onboarding, Today and the
/// session all breathe with the same rhythm and every mascot stays inside a band
/// that owns its layout height.
nonisolated enum RegaliaLayout {
    // MARK: - Spacing

    /// Gap between a heading block and the content beneath it.
    static let headerToContent: CGFloat = 24
    /// Gap between major sections on a scrolling screen.
    static let sectionStack: CGFloat = 22
    /// Fixed gap between a mascot band and the copy that follows it.
    static let artToCopy: CGFloat = 20
    /// Gap between stacked cards.
    static let cardStack: CGFloat = 14
    /// Gap between stacked selectable rows.
    static let rowStack: CGFloat = 10
    /// Room under the last line so a floating footer never hides it.
    static let scrollBottom: CGFloat = 152
    /// Room under the last line on the three tabbed screens, clearing the glass tab bar.
    static let tabbedScrollBottom: CGFloat = 104

    // MARK: - Art bands

    /// Shared band height for the three onboarding teaching screens.
    static let teachingArt: CGFloat = 176
    /// The generous lion on the welcome, covenant and Today screens.
    static let heroArt: CGFloat = 272
    /// The slightly shorter lion inside a session, where the HUD sits above it.
    static let sessionArt: CGFloat = 248
    /// The closing full-armour moment.
    static let celebrationArt: CGFloat = 296
    /// The lion standing in front of a locked app.
    static let lockArt: CGFloat = 286
}
