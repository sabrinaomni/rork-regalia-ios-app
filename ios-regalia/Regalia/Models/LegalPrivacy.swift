import Foundation

/// The Privacy Policy text, mirroring the published page at `SubscriptionLinks.privacy`.
///
/// Each section is its own constant so the Swift type-checker never has to solve
/// one enormous nested literal — that is slow enough to fail the build outright.
extension LegalDocument {
    static let privacy = LegalDocument(
        id: "privacy",
        title: "Privacy Policy",
        effectiveDate: LegalDocument.currentEffectiveDate,
        summary: "Regalia is built to hold your prayer life on your own phone. Almost nothing leaves it, and we never sell or track you.",
        sections: LegalPrivacyText.sections,
        webURL: SubscriptionLinks.privacy
    )
}

nonisolated enum LegalPrivacyText {
    static var sections: [LegalDocument.Section] {
        [
            shortVersion,
            responsible,
            onDevice,
            leavesDevice,
            screenTime,
            reminders,
            legalBases,
            retention,
            rights,
            transfers,
            children,
            changes,
            contact
        ]
    }

    private static let shortVersion = LegalDocument.Section(
        heading: "The short version",
        paragraphs: [
            "Your name, your answers, your prayers, your streak and your whole archive stay on your device. We cannot read them.",
            "There are no accounts to create, no advertising, no analytics or tracking tools, and no third party buying your data from us.",
            "The only thing that leaves your phone is what is needed to keep your subscription working."
        ]
    )

    private static let responsible = LegalDocument.Section(
        heading: "Who is responsible",
        paragraphs: [
            "OMNIAI LTD is the data controller for Regalia. We are registered in England and Wales, company number 16311606, with our registered office at 71–75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom.",
            "For anything about privacy or your personal data, write to info@omniaiagency.co.uk."
        ]
    )

    private static let onDevice = LegalDocument.Section(
        heading: "What stays on your device",
        paragraphs: [
            "Regalia stores the following in the app's own storage on your iPhone: the name you enter; the optional details you give on the About-you step; why you say you are here and what pulls you off centre; how you were feeling at the start; your daily Regalia time; your reminder preferences; your guard settings and unlock passes; and every session you complete, including your streak and your archive.",
            "Some of this is kept in a shared area on your device so that the Regalia widget and the app-guarding parts of Regalia can show the right thing. That shared area is still on your phone.",
            "None of it is sent to us. It is not backed up to a server we control. It goes wherever your own iPhone backup goes, under Apple's terms, and nowhere else.",
            "Erase everything in Regalia's Settings tab deletes all of it from the device, and deleting the app removes it too."
        ]
    )

    private static let leavesDevice = LegalDocument.Section(
        heading: "What leaves your device",
        paragraphs: [
            "To sell and honour a subscription we use RevenueCat, a subscription service acting as our processor. It receives an anonymous identifier created for your installation, along with which plan you bought and whether it is still active. That is what lets the app know it should be unlocked, and lets your subscription be restored on a new phone.",
            "This information is not linked to your name, your email, or anything you write in Regalia, because we never send those anywhere.",
            "Payment itself is taken by Apple through the App Store. Apple, not us, handles your payment details, and Apple gives us only the status of the purchase.",
            "We do not use your purchase information for advertising, and we do not track you across other apps or websites. Regalia contains no advertising identifiers and no third-party analytics or advertising software."
        ]
    )

    private static let screenTime = LegalDocument.Section(
        heading: "App blocking and Screen Time",
        paragraphs: [
            "If you use the guard, Regalia asks for Apple's Screen Time permission. You then pick the apps you want held shut using Apple's own picker.",
            "Apple deliberately hands us only opaque tokens for your choice, never app names. Those tokens stay on your device. We receive no list of your apps, no record of what you opened, and no report of your phone use at all.",
            "You can withdraw the permission whenever you like in iOS Settings, and Forget in Regalia's Guard tab clears the selection from the device."
        ]
    )

    private static let reminders = LegalDocument.Section(
        heading: "Reminders",
        paragraphs: [
            "Reminders are scheduled by your own iPhone and delivered locally. There is no push server, and no notification is sent from us.",
            "Turning reminders off in Regalia, or notifications off in iOS Settings, stops them."
        ]
    )

    private static let legalBases = LegalDocument.Section(
        heading: "Why we are allowed to do this",
        paragraphs: [
            "Under the UK GDPR we rely on performance of our contract with you to run your subscription and unlock the app.",
            "For the data held on your own device, we rely on your consent, which you give by entering it and can withdraw at any time by erasing it in Settings.",
            "We do not rely on legitimate interests for any advertising or profiling, because we do neither."
        ]
    )

    private static let retention = LegalDocument.Section(
        heading: "How long anything is kept",
        paragraphs: [
            "What is on your device is kept until you erase it or delete the app. You are in control of it.",
            "Subscription records are kept while your subscription is active and for as long afterwards as we need to meet our legal, tax and accounting duties, then deleted."
        ]
    )

    private static let rights = LegalDocument.Section(
        heading: "Your rights",
        paragraphs: [
            "You have the right to ask for a copy of the personal data we hold about you, to have it corrected, to have it deleted, to restrict or object to how we use it, and to receive it in a portable form. You can also withdraw consent at any time.",
            "Because your prayer life is stored on your device rather than with us, the fastest way to exercise most of these rights is Erase everything in Regalia's Settings tab. For anything held on our side, write to info@omniaiagency.co.uk and we will respond within one month.",
            "If you are unhappy with how we have handled your data you can complain to the Information Commissioner's Office at ico.org.uk, or to the supervisory authority where you live."
        ]
    )

    private static let transfers = LegalDocument.Section(
        heading: "International transfers",
        paragraphs: [
            "Our subscription processor may handle subscription status on servers outside the United Kingdom. Where that happens, the transfer is covered by the safeguards the UK GDPR requires, such as the UK International Data Transfer Addendum to the European Commission's standard contractual clauses."
        ]
    )

    private static let children = LegalDocument.Section(
        heading: "Children",
        paragraphs: [
            "Regalia is not directed at young children and is intended for people aged 13 and over. We do not knowingly collect data from a child under 13. If you believe a child has used the app and you want the data cleared, use Erase everything on the device, or contact us."
        ]
    )

    private static let changes = LegalDocument.Section(
        heading: "Changes to this policy",
        paragraphs: [
            "If we change how Regalia handles your data we will update this policy, change the effective date above, and tell you in the app when the change is significant."
        ]
    )

    private static let contact = LegalDocument.Section(
        heading: "Contact us",
        paragraphs: [
            "We would rather hear from you than have you wonder.",
            LegalEntity.contactBlock
        ]
    )
}
