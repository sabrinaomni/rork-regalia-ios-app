import SwiftUI

/// The teaching-screen mascot: the lion in near-darkness while a slow gold dawn
/// rises behind him, lifting the darkness off his shoulders. `dawnProgress`
/// (0…1) sets how far the sunrise has come — it grows across the teaching steps.
struct DawnMascotView: View {
    var dawnProgress: Double = 1.0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var risen = false

    /// How far the light has actually climbed, animated on appear.
    private var dawn: Double {
        reduceMotion ? dawnProgress : (risen ? dawnProgress : dawnProgress * 0.12)
    }

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
                let t = context.date.timeIntervalSinceReferenceDate

                ZStack {
                    starField(t: t)
                    horizonGlow(t: t, size: size)
                    motes(t: t)
                    lion(t: t, size: size)
                }
                .frame(width: size.width, height: size.height)
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            risen = false
            withAnimation(.easeInOut(duration: 3.4)) {
                risen = true
            }
        }
    }

    // MARK: - Layers

    /// Stars that fade out as the light rises.
    private func starField(t: TimeInterval) -> some View {
        Canvas { context, size in
            for index in 0..<30 {
                let seed = Double(index)
                let x = size.width * ((sin(seed * 78.233) + 1) / 2)
                let y = size.height * ((cos(seed * 12.9898) + 1) / 2) * 0.7
                let radius = 0.6 + (seed.truncatingRemainder(dividingBy: 4)) * 0.25
                let twinkle = 0.5 + 0.5 * sin(t * 0.8 + seed * 2.1)
                let alpha = (0.10 + (seed.truncatingRemainder(dividingBy: 7)) * 0.03) * (1 - dawn)
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(RegaliaTheme.bone.opacity(alpha * twinkle)))
            }
        }
        .allowsHitTesting(false)
    }

    /// Gold light rising from below the horizon, breathing gently. Sized from the
    /// band it was handed so the glow can never reserve height beyond it.
    private func horizonGlow(t: TimeInterval, size: CGSize) -> some View {
        let breathe = 1 + (reduceMotion ? 0 : 0.045 * sin(t * 0.5))
        return VStack {
            Spacer(minLength: 0)
            RadialGradient(
                colors: [
                    RegaliaTheme.gold.opacity(0.55 * dawn),
                    RegaliaTheme.gold.opacity(0.16 * dawn),
                    .clear
                ],
                center: .bottom,
                startRadius: 10,
                endRadius: max(size.width, size.height) * 0.9
            )
            .frame(height: size.height * 0.72)
        }
        .scaleEffect(y: breathe, anchor: .bottom)
        .blur(radius: 16)
        .blendMode(.screen)
        .allowsHitTesting(false)
    }

    /// Fine gold motes drifting up through the light.
    private func motes(t: TimeInterval) -> some View {
        Canvas { context, size in
            for index in 0..<16 {
                let seed = Double(index)
                let speed = 0.10 + (seed.truncatingRemainder(dividingBy: 5)) * 0.035
                let progress = ((t * speed) + seed * 0.37).truncatingRemainder(dividingBy: 1)
                let x = size.width * (0.14 + 0.72 * ((sin(seed * 12.9898) + 1) / 2))
                    + CGFloat(sin(t * 0.4 + seed) * 10)
                let y = size.height * (1.05 - progress * 1.15)
                let alpha = sin(progress * .pi) * 0.5 * (0.2 + dawn)
                let radius = 1.0 + (seed.truncatingRemainder(dividingBy: 3)) * 0.6
                let rect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
                context.fill(Path(ellipseIn: rect), with: .color(RegaliaTheme.gold.opacity(alpha)))
            }
        }
        .blur(radius: 0.6)
        .blendMode(.plusLighter)
        .allowsHitTesting(false)
    }

    /// The lion: dimmed while it is dark, warmed as the dawn climbs.
    private func lion(t: TimeInterval, size: CGSize) -> some View {
        let dim = 0.22 + 0.78 * dawn
        let span = min(size.width, size.height)
        return Image("lion_mascot_sitting_upward")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: span * 0.92, maxHeight: span * 0.92)
            .colorMultiply(Color(red: dim, green: dim * 0.96, blue: dim * 0.88))
            .shadow(color: RegaliaTheme.gold.opacity(0.35 * dawn), radius: 24, y: 6)
            .scaleEffect(reduceMotion ? 1 : (1 + 0.012 * sin(t * 0.6)))
            .offset(y: CGFloat(reduceMotion ? 0 : sin(t * 0.62) * 4))
            .accessibilityHidden(true)
    }
}
