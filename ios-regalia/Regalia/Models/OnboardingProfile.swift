import Foundation

/// Why the user came to Regalia. Shown back to them on the lock gate.
nonisolated enum SeekingReason: String, CaseIterable, Codable, Identifiable, Sendable {
    case mornings
    case purity
    case identity
    case anxiety
    case presence
    case discipline

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mornings: "Stop losing my mornings to the feed"
        case .purity: "Walk in purity and break a habit"
        case .identity: "Know who I am in Christ"
        case .anxiety: "Quiet the anxiety I scroll to escape"
        case .presence: "Be present with the people in front of me"
        case .discipline: "Build a discipline that actually lasts"
        }
    }

    var symbol: String {
        switch self {
        case .mornings: "sunrise.fill"
        case .purity: "flame.fill"
        case .identity: "crown.fill"
        case .anxiety: "wind"
        case .presence: "person.2.fill"
        case .discipline: "figure.strengthtraining.traditional"
        }
    }
}

/// What the user says pulls their spiritual life off centre.
nonisolated enum DistractionCause: String, CaseIterable, Codable, Identifiable, Sendable {
    case phoneFirst
    case noise
    case shame
    case loneliness
    case comparison
    case busyness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .phoneFirst: "My phone is the first thing I touch"
        case .noise: "I can't sit in silence"
        case .shame: "Shame makes me avoid God"
        case .loneliness: "I scroll when I feel alone"
        case .comparison: "Comparison steals my peace"
        case .busyness: "I'm too busy to stop"
        }
    }

    var symbol: String {
        switch self {
        case .phoneFirst: "iphone.gen3"
        case .noise: "waveform"
        case .shame: "eye.slash.fill"
        case .loneliness: "moon.stars.fill"
        case .comparison: "arrow.up.arrow.down"
        case .busyness: "clock.badge.exclamationmark.fill"
        }
    }
}

/// Gender captured on the About-you step. Never rewrites prayer text —
/// prayers stay gender-neutral regardless of the answer.
nonisolated enum Gender: String, CaseIterable, Codable, Identifiable, Sendable {
    case male
    case female
    case preferNotToSay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

/// Broad age band captured on the About-you step.
nonisolated enum AgeBand: String, CaseIterable, Codable, Identifiable, Sendable {
    case under25
    case upTo39
    case upTo54
    case fiftyFivePlus

    var id: String { rawValue }

    var label: String {
        switch self {
        case .under25: "Under 25"
        case .upTo39: "25–39"
        case .upTo54: "40–54"
        case .fiftyFivePlus: "55+"
        }
    }
}

/// Marital status captured on the About-you step.
nonisolated enum MaritalStatus: String, CaseIterable, Codable, Identifiable, Sendable {
    case single
    case married
    case preferNotToSay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .single: "Single"
        case .married: "Married"
        case .preferNotToSay: "Prefer not to say"
        }
    }
}

/// Where the user is in their walk, captured on the About-you step.
nonisolated enum FaithStage: String, CaseIterable, Codable, Identifiable, Sendable {
    case exploring
    case newBeliever
    case growing
    case walking

    var id: String { rawValue }

    var label: String {
        switch self {
        case .exploring: "Exploring"
        case .newBeliever: "New to faith"
        case .growing: "Growing"
        case .walking: "Walking for years"
        }
    }
}

/// Everything captured during onboarding, persisted for the life of the account.
nonisolated struct OnboardingProfile: Codable, Equatable, Sendable {
    var name: String = ""
    var gender: Gender?
    var ageBand: AgeBand?
    var maritalStatus: MaritalStatus?
    var faithStage: FaithStage?
    var reasons: Set<SeekingReason> = []
    var baselineMood: Mood = .weary
    var causes: Set<DistractionCause> = []
    var guardedAppIDs: Set<String> = []
    /// Minutes from midnight for the daily Regalia reminder.
    var dailyTimeMinutes: Int = 7 * 60
    var isComplete: Bool = false

    /// The single line surfaced on the lock gate.
    var primaryReason: String {
        SeekingReason.allCases.first { reasons.contains($0) }?.title
            ?? "Put the armour on before the world gets my attention"
    }

    /// One-line summary for Settings; nil until at least one answer exists.
    var aboutYouLine: String? {
        let parts = [gender?.label, ageBand?.label, maritalStatus?.label, faithStage?.label]
            .compactMap { $0 }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }

    var guardedApps: [GuardedApp] {
        GuardedApp.catalog.filter { guardedAppIDs.contains($0.id) }
    }

    var dailyTime: Date {
        Calendar.current.date(
            bySettingHour: dailyTimeMinutes / 60,
            minute: dailyTimeMinutes % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }
}
