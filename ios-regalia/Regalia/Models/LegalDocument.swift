import Foundation

/// A legal document rendered inside the app, so the Terms and Privacy Policy are
/// always readable — offline, and without handing a reviewer off to a browser.
///
/// The wording lives in `LegalTerms.swift` and `LegalPrivacy.swift`, and matches the
/// published pages at `SubscriptionLinks.terms` / `SubscriptionLinks.privacy`. When one
/// side is edited the other must be edited to match, and `effectiveDate` bumped on both.
nonisolated struct LegalDocument: Identifiable, Sendable {
    nonisolated struct Section: Identifiable, Sendable {
        let heading: String
        let paragraphs: [String]

        var id: String { heading }
    }

    let id: String
    let title: String
    /// Shown under the title, e.g. "Effective 7 September 2026".
    let effectiveDate: String
    /// Standfirst above the first heading.
    let summary: String
    let sections: [Section]
    /// The published copy of this same document.
    let webURL: String

    /// Bumped on both documents together whenever either is reworded.
    static let currentEffectiveDate = "Effective 7 September 2026"
}

// MARK: - Company

/// The publisher named in both documents.
nonisolated enum LegalEntity {
    static let name = "OMNIAI LTD"
    static let address = "71–75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom"
    static let registration = "Registered in England and Wales, company number 16311606"
    static let registrationSentence = "registered in England and Wales, company number 16311606"
    static let email = "info@omniaiagency.co.uk"
    static let website = "www.omniaiagency.co.uk"

    /// One block naming the company, used to close both documents.
    static let contactBlock = """
        OMNIAI LTD
        71–75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom
        Registered in England and Wales, company number 16311606
        info@omniaiagency.co.uk
        www.omniaiagency.co.uk
        """
}
