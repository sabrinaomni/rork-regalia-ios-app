import Foundation

/// The seven pieces of the Armour of God (Ephesians 6:10-18) equipped in every session.
nonisolated enum ArmourPiece: String, CaseIterable, Codable, Identifiable, Sendable {
    case belt
    case breastplate
    case sandals
    case shield
    case helmet
    case sword
    case prayer

    var id: String { rawValue }

    /// Position in the session, 1-based.
    var order: Int { (ArmourPiece.allCases.firstIndex(of: self) ?? 0) + 1 }

    var title: String {
        switch self {
        case .belt: "Belt of Truth"
        case .breastplate: "Breastplate of Righteousness"
        case .sandals: "Sandals of Peace"
        case .shield: "Shield of Faith"
        case .helmet: "Helmet of Salvation"
        case .sword: "Sword of the Spirit"
        case .prayer: "Prayer in the Spirit"
        }
    }

    var shortTitle: String {
        switch self {
        case .belt: "Belt"
        case .breastplate: "Breastplate"
        case .sandals: "Sandals"
        case .shield: "Shield"
        case .helmet: "Helmet"
        case .sword: "Sword"
        case .prayer: "Prayer"
        }
    }

    var symbol: String {
        switch self {
        case .belt: "circle.hexagongrid.fill"
        case .breastplate: "shield.lefthalf.filled"
        case .sandals: "shoeprints.fill"
        case .shield: "shield.fill"
        case .helmet: "crown.fill"
        case .sword: "book.closed.fill"
        case .prayer: "hands.and.sparkles.fill"
        }
    }

    var actionLabel: String {
        switch self {
        case .belt: "Fasten the belt"
        case .breastplate: "Wear the breastplate"
        case .sandals: "Lace the sandals"
        case .shield: "Equip shield"
        case .helmet: "Put on the helmet"
        case .sword: "Take up the sword"
        case .prayer: "Pray in the Spirit"
        }
    }

    var verse: Verse {
        switch self {
        case .belt:
            Verse(id: "eph6-14a", text: "Stand firm then, with the belt of truth buckled around your waist.", reference: "Ephesians 6:14")
        case .breastplate:
            Verse(id: "eph6-14b", text: "…with the breastplate of righteousness in place.", reference: "Ephesians 6:14")
        case .sandals:
            Verse(id: "eph6-15", text: "…and with your feet fitted with the readiness that comes from the gospel of peace.", reference: "Ephesians 6:15")
        case .shield:
            Verse(id: "eph6-16", text: "Take up the shield of faith, with which you can extinguish all the flaming arrows of the evil one.", reference: "Ephesians 6:16")
        case .helmet:
            Verse(id: "eph6-17a", text: "Take the helmet of salvation…", reference: "Ephesians 6:17")
        case .sword:
            Verse(id: "eph6-17b", text: "…and the sword of the Spirit, which is the word of God.", reference: "Ephesians 6:17")
        case .prayer:
            Verse(id: "eph6-18", text: "And pray in the Spirit on all occasions with all kinds of prayers and requests.", reference: "Ephesians 6:18")
        }
    }

    /// The line the user holds to declare over themselves.
    var declaration: String {
        switch self {
        case .belt: "I refuse the lie. Truth holds me together today."
        case .breastplate: "My worth is not my record. Christ covers my heart."
        case .sandals: "Wherever I step today, I carry peace, not panic."
        case .shield: "My faith guards what my eyes cannot."
        case .helmet: "My mind belongs to the One who saved me."
        case .sword: "I answer every voice with the Word of God."
        case .prayer: "I am never alone in this. I pray before I scroll."
        }
    }

    /// Short label naming the truth this piece stands on (used on the supporting verse card).
    var truthLabel: String {
        switch self {
        case .belt: "Truth"
        case .breastplate: "Righteousness"
        case .sandals: "Peace"
        case .shield: "Faith"
        case .helmet: "Salvation"
        case .sword: "The Word"
        case .prayer: "Prayer"
        }
    }

    /// Short pastoral framing shown above the verse.
    var teaching: String {
        switch self {
        case .belt: "Everything else hangs on this piece. Name what is true before the feed names it for you."
        case .breastplate: "The accuser aims at your heart. Righteousness you were given, not earned, covers it."
        case .sandals: "Peace is footing. You cannot stand on ground you keep running from."
        case .shield: "Faith is raised, not felt. Lift it before the arrows come."
        case .helmet: "Salvation guards the mind. What you know decides what you do at 6am."
        case .sword: "The only offensive piece. One verse, spoken, ends most arguments in your head."
        case .prayer: "Armour without prayer is costume. Ask, and let Him fight in front of you."
        }
    }
}
