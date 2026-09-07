import SwiftUI

/// The lion mascot, which gains one armour piece per completed session step.
nonisolated enum MascotStage: Int, CaseIterable, Sendable {
    case bare = 0
    case belt
    case breastplate
    case sandals
    case shield
    case helmet
    case sword
    case radiant

    var assetName: String {
        switch self {
        case .bare: "lion_mascot_sitting_upward"
        case .belt: "lion_guardian_mascot"
        case .breastplate: "lion_mascot_golden_armor"
        case .sandals: "lion_armoured_mascot"
        case .shield: "lion_shield_armor"
        case .helmet: "lion_knight_armored"
        case .sword: "lion_knight_armor_sword"
        case .radiant: "lion_knight_praying"
        }
    }

    static func stage(forEquippedCount count: Int) -> MascotStage {
        MascotStage(rawValue: max(0, min(count, 7))) ?? .bare
    }
}

/// Animated mascot: slow breathing, gentle float, rotating armour arcs, drifting embers.
struct MascotView: View {
    let stage: MascotStage
    var glow: Color = RegaliaTheme.gold
    var showEmbers: Bool = true
    var intensity: Double = 1

    @State private var breathe = false
    @State private var appeared = false

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let span = min(size.width, size.height)

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: false)) { context in
                let t = context.date.timeIntervalSinceReferenceDate

                ZStack {
                    bloom(t: t, span: span)
                    arcs(t: t, span: span)
                    if showEmbers {
                        EmberField(time: t, tint: glow)
                            .allowsHitTesting(false)
                    }
                    lion(t: t, span: span)
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.4).repeatForever(autoreverses: true)) {
                breathe = true
            }
            withAnimation(.spring(response: 0.9, dampingFraction: 0.75).delay(0.05)) {
                appeared = true
            }
        }
    }

    /// Halo bloom, sized from the stage it was given so it can never reach past it.
    private func bloom(t: TimeInterval, span: CGFloat) -> some View {
        let pulse = 1 + 0.05 * sin(t * 0.9)
        return RadialGradient(
            colors: [
                glow.opacity(0.42 * intensity),
                glow.opacity(0.14 * intensity),
                .clear
            ],
            center: .center,
            startRadius: 6,
            endRadius: max(span * 0.60, 40)
        )
        .scaleEffect(pulse)
        .blur(radius: 14)
    }

    /// Counter-rotating rings, scaled to the stage instead of a fixed 306pt reservation.
    private func arcs(t: TimeInterval, span: CGFloat) -> some View {
        ZStack {
            ForEach(0..<3, id: \.self) { index in
                let ring = Double(index)
                let diameter = span * (0.58 + ring * 0.15)
                Circle()
                    .trim(from: 0.04 + ring * 0.05, to: 0.42 - ring * 0.06)
                    .stroke(
                        glow.opacity(0.30 - ring * 0.07),
                        style: StrokeStyle(lineWidth: 1.1, lineCap: .round)
                    )
                    .frame(width: diameter, height: diameter)
                    .rotationEffect(.degrees(t * (7 + ring * 4) * (index.isMultiple(of: 2) ? 1 : -1)))
            }
        }
        .blendMode(.screen)
    }

    private func lion(t: TimeInterval, span: CGFloat) -> some View {
        Image(stage.assetName)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: span * 0.92, maxHeight: span * 0.92)
            .shadow(color: glow.opacity(0.45), radius: 26, y: 6)
            .scaleEffect(appeared ? (breathe ? 1.018 : 0.985) : 0.9)
            .offset(y: CGFloat(sin(t * 0.62) * 5))
            .opacity(appeared ? 1 : 0)
            .id(stage.rawValue)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.94)),
                removal: .opacity
            ))
    }
}

extension View {
    /// Pins art into a band that owns its layout height: the art is clipped to the
    /// band and its edges dissolve instead of cutting, so nothing above or below
    /// (headings, subtitles, copy) can ever be overlapped by a glow or halo.
    func mascotStage(height: CGFloat, fade: CGFloat = 18) -> some View {
        let edge = min(0.42, Double(fade / max(height, 1)))
        return Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay { self.allowsHitTesting(false) }
            .clipShape(Rectangle())
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black.opacity(0), location: 0),
                        .init(color: .black, location: edge),
                        .init(color: .black, location: 1 - edge),
                        .init(color: .black.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .accessibilityHidden(true)
    }
}

/// Warm embers drifting upward behind the mascot.
private struct EmberField: View {
    let time: TimeInterval
    let tint: Color

    var body: some View {
        Canvas { context, size in
            for index in 0..<18 {
                let seed = Double(index)
                let speed = 0.16 + (seed.truncatingRemainder(dividingBy: 5)) * 0.05
                let progress = ((time * speed) + seed * 0.37).truncatingRemainder(dividingBy: 1)
                let x = size.width * (0.12 + 0.76 * ((sin(seed * 12.9898) + 1) / 2))
                    + CGFloat(sin(time * 0.5 + seed) * 12)
                let y = size.height * (1.05 - progress * 1.15)
                let alpha = sin(progress * .pi) * 0.55
                let radius = 1.1 + (seed.truncatingRemainder(dividingBy: 3)) * 0.7

                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(tint.opacity(alpha)))
            }
        }
        .blur(radius: 0.6)
        .blendMode(.plusLighter)
    }
}
