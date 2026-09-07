import Foundation

/// The nine steps of the daily Regalia: seven armour pieces, Renew Your Mind, Stand Firm.
nonisolated enum SessionStep: Hashable, Identifiable, Sendable {
    case armour(ArmourPiece)
    case renew
    case stand

    var id: String {
        switch self {
        case .armour(let piece): "armour-\(piece.rawValue)"
        case .renew: "renew"
        case .stand: "stand"
        }
    }

    nonisolated static let all: [SessionStep] =
        ArmourPiece.allCases.map(SessionStep.armour) + [.renew, .stand]

    var title: String {
        switch self {
        case .armour(let piece): piece.title
        case .renew: "Renew Your Mind"
        case .stand: "Stand Firm"
        }
    }

    var actionLabel: String {
        switch self {
        case .armour(let piece): piece.actionLabel
        case .renew: "Take the truth"
        case .stand: "Amen · seal the day"
        }
    }

    var symbol: String {
        switch self {
        case .armour(let piece): piece.symbol
        case .renew: "brain.head.profile"
        case .stand: "figure.stand"
        }
    }
}
