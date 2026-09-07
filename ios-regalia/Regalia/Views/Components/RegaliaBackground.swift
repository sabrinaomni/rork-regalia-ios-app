import SwiftUI

/// The shared midnight canvas: vertical gradient, high gold bloom, faint starlight.
struct RegaliaBackground: View {
    var tint: Color = RegaliaTheme.gold
    var bloomStrength: Double = 0.22

    var body: some View {
        ZStack {
            RegaliaTheme.canvas

            TimelineView(.animation(minimumInterval: 1.0 / 20.0, paused: false)) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                RadialGradient(
                    colors: [tint.opacity(bloomStrength), .clear],
                    center: .init(x: 0.5, y: 0.24),
                    startRadius: 20,
                    endRadius: 420
                )
                .scaleEffect(1 + 0.04 * sin(t * 0.4))
                .blur(radius: 30)
            }

            StarField()
                .opacity(0.5)
        }
        .ignoresSafeArea()
    }
}

private struct StarField: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<46 {
                let seed = Double(index)
                let x = size.width * ((sin(seed * 78.233) + 1) / 2)
                let y = size.height * ((cos(seed * 12.9898) + 1) / 2)
                let radius = 0.6 + (seed.truncatingRemainder(dividingBy: 4)) * 0.25
                let alpha = 0.08 + (seed.truncatingRemainder(dividingBy: 7)) * 0.03
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(RegaliaTheme.bone.opacity(alpha)))
            }
        }
        .allowsHitTesting(false)
    }
}
