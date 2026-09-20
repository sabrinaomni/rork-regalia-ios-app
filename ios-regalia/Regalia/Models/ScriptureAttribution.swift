import Foundation

/// Scripture translation attribution for everything quoted from the NIV.
///
/// Biblica permits quoting up to 500 verses without written permission provided
/// each use carries proper acknowledgment. The library holds roughly 162 verses,
/// so the short tag rides beside every reference and the full notice appears in
/// the Terms of Use. Kept in one place so the wording can never drift between
/// the app, the widget, and the shield extensions.
nonisolated enum ScriptureAttribution {
    /// The short credit shown beside verse references, e.g. "Philippians 4:6 · NIV".
    static let translationTag = "NIV"

    /// The acknowledgment Biblica requires, shown in the Terms of Use.
    static let copyrightNotice = "Scripture quotations taken from The Holy Bible, New International Version® NIV®. Copyright © 1973, 1978, 1984, 2011 by Biblica, Inc.™ Used by permission. All rights reserved worldwide."

    /// A reference with the translation credit appended, for string-only
    /// surfaces: notifications, the widget snapshot, and the shield.
    static func credited(_ reference: String) -> String {
        reference.isEmpty ? reference : "\(reference) · \(translationTag)"
    }
}
