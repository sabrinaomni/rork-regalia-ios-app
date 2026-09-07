import Foundation

/// The Terms of Use text, mirroring the published page at `SubscriptionLinks.terms`.
///
/// Each section is its own constant so the Swift type-checker never has to solve
/// one enormous nested literal — that is slow enough to fail the build outright.
extension LegalDocument {
    static let terms = LegalDocument(
        id: "terms",
        title: "Terms of Use",
        effectiveDate: LegalDocument.currentEffectiveDate,
        summary: "These terms cover your use of Regalia. Please read them before you subscribe — by using the app you agree to them.",
        sections: LegalTermsText.sections,
        webURL: SubscriptionLinks.terms
    )
}

nonisolated enum LegalTermsText {
    static var sections: [LegalDocument.Section] {
        [
            whoWeAre,
            whatRegaliaIs,
            subscription,
            appGuard,
            fairUse,
            ownership,
            availability,
            responsibility,
            endingAccess,
            law,
            contact
        ]
    }

    private static let whoWeAre = LegalDocument.Section(
        heading: "Who we are",
        paragraphs: [
            "Regalia is published by OMNIAI LTD, registered in England and Wales, company number 16311606. Our registered office is 71–75 Shelton Street, Covent Garden, London WC2H 9JQ, United Kingdom.",
            "In these terms, “we”, “us” and “our” mean OMNIAI LTD. “You” means the person using the app. You can reach us any time at info@omniaiagency.co.uk."
        ]
    )

    private static let whatRegaliaIs = LegalDocument.Section(
        heading: "What Regalia is",
        paragraphs: [
            "Regalia is a daily Christian discipline app. It guides you through a short morning session built on Ephesians 6:10-18, gives you a prayer and a verse for the day you are in, and can hold chosen apps on your phone shut until you have stood.",
            "Regalia is devotional content, not professional advice. It is not counselling, therapy, medical care, or a crisis service, and it must not be relied on as any of those. If you are in distress or in danger, please contact your doctor or your local emergency services.",
            "Regalia is not a church, and it does not replace one. We encourage you to walk this out alongside real people."
        ]
    )

    private static let subscription = LegalDocument.Section(
        heading: "Your subscription",
        paragraphs: [
            "Full access to Regalia requires a paid subscription, offered monthly or yearly. The exact price in your currency is always shown on the subscription screen before you commit, and that displayed price is the one that applies.",
            "Subscriptions renew automatically at the end of each period until you cancel. Your Apple Account is charged within 24 hours before each renewal.",
            "All payments are taken and processed by Apple through the App Store. We never see or handle your card details.",
            "You can cancel at any time in the App Store: open Settings on your iPhone, tap your name, then Subscriptions. Cancelling stops the next renewal; your access continues until the end of the period you have already paid for. You can also reach the same controls from Manage subscription inside Regalia's own Settings tab.",
            "Refunds are handled by Apple under its own terms, not by us. You can request one from Apple directly, and Manage subscription inside the app will take you there. Nothing in this section affects your statutory rights as a consumer.",
            "If you subscribed on one Apple Account and reinstall the app, use Restore in the app to bring your subscription back."
        ]
    )

    private static let appGuard = LegalDocument.Section(
        heading: "The app guard",
        paragraphs: [
            "Regalia's guard uses Apple's Screen Time system. You choose which apps to hold shut, and iOS enforces it. Your choice of apps is made through Apple's own picker and stays on your device — we never receive a list of the apps you selected or any record of how you use them.",
            "The guard is a discipline aid, not a security product. It can be turned off by you at any time in Regalia's Guard tab or in iOS Settings, and it should not be treated as a way to stop a determined person from reaching an app.",
            "If you decline the Screen Time permission, the rest of Regalia still works — only the blocking does not."
        ]
    )

    private static let fairUse = LegalDocument.Section(
        heading: "Using the app fairly",
        paragraphs: [
            "Please use Regalia only for your own personal, non-commercial use. Do not copy, resell, rent out, or redistribute the app or its content, and do not try to work around the subscription, interfere with the app, or take it apart, except where the law expressly allows you to.",
            "Do not use Regalia in any unlawful way, or in any way that harms us or another person."
        ]
    )

    private static let ownership = LegalDocument.Section(
        heading: "Content and ownership",
        paragraphs: [
            "Scripture quoted in Regalia is drawn from public-domain translations. Everything else — the prayers, the session structure, the artwork, the name Regalia, and the app itself — belongs to us or our licensors.",
            "Your subscription gives you a personal, revocable, non-transferable licence to use the app while it is active. It does not transfer ownership of anything.",
            "What you write in Regalia stays yours. It is stored on your device and we do not claim any right over it."
        ]
    )

    private static let availability = LegalDocument.Section(
        heading: "Availability and changes",
        paragraphs: [
            "We work to keep Regalia running well, but we cannot promise it will always be available or entirely free of faults. We may update the app, and may add, change or retire features over time.",
            "If we ever make a change that materially reduces what a paid subscription gives you, we will tell you before it takes effect so you can decide whether to keep subscribing.",
            "We may update these terms. If a change is significant we will let you know in the app or by updating the effective date above, and continuing to use Regalia after that means you accept the new terms."
        ]
    )

    private static let responsibility = LegalDocument.Section(
        heading: "Our responsibility to you",
        paragraphs: [
            "We provide Regalia with reasonable care and skill, and nothing in these terms limits your rights under the Consumer Rights Act 2015 or any other right that cannot lawfully be limited.",
            "We are not liable for loss that was not reasonably foreseeable, for loss caused by something outside our reasonable control, or for any business loss. We do not exclude or limit our liability for death or personal injury caused by our negligence, or for fraud.",
            "Regalia is a devotional tool. Decisions you make about your health, your relationships, or your circumstances remain yours."
        ]
    )

    private static let endingAccess = LegalDocument.Section(
        heading: "Ending your access",
        paragraphs: [
            "You can stop using Regalia at any time. Cancel the subscription in the App Store, and use Erase everything in Regalia's Settings tab to clear your profile, your streak, and your whole archive from the device.",
            "We may suspend or end your access if you seriously or repeatedly break these terms. If we do, and you have paid for a period you cannot now use, you may be entitled to a refund for the unused part."
        ]
    )

    private static let law = LegalDocument.Section(
        heading: "Law and disputes",
        paragraphs: [
            "These terms and any dispute arising from them are governed by the law of England and Wales, and the courts of England and Wales have jurisdiction.",
            "If you live elsewhere in the United Kingdom or in the European Union, you keep the benefit of any mandatory consumer protections available to you where you live, and you may bring proceedings in your local courts."
        ]
    )

    private static let contact = LegalDocument.Section(
        heading: "Contact us",
        paragraphs: [
            "Questions about these terms, or about your subscription, are welcome.",
            LegalEntity.contactBlock
        ]
    )
}
