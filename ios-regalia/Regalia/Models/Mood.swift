import SwiftUI

/// The morning emotional check-in that drives dynamic verse selection.
nonisolated enum Mood: String, CaseIterable, Codable, Identifiable, Sendable {
    case anxious
    case tempted
    case numb
    case grateful
    case weary

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anxious: "Anxious"
        case .tempted: "Tempted"
        case .numb: "Numb"
        case .grateful: "Grateful"
        case .weary: "Weary"
        }
    }

    var symbol: String {
        switch self {
        case .anxious: "cloud.fill"
        case .tempted: "flame.fill"
        case .numb: "face.dashed"
        case .grateful: "heart.fill"
        case .weary: "battery.25percent"
        }
    }

    /// Short pastoral line shown under the mascot once a mood is chosen.
    var response: String {
        switch self {
        case .anxious: "Then we hand the weight over first."
        case .tempted: "Then we put the armour on before the door opens."
        case .numb: "Then we start with truth, not feeling."
        case .grateful: "Then let's build on it while it's warm."
        case .weary: "Then we go slow, and He carries the rest."
        }
    }
}
