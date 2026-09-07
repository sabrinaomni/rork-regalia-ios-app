import SwiftUI

/// Central design tokens for Regalia: midnight canvas, molten gold accent, warm bone text.
enum RegaliaTheme {
    static let canvasTop = Color(hex: 0x0B1020)
    static let canvasBottom = Color(hex: 0x05070F)
    static let surface = Color(hex: 0x151C31)
    static let gold = Color(hex: 0xE8B44A)
    static let goldDeep = Color(hex: 0xC9A227)
    static let bone = Color(hex: 0xF2E7D0)
    static let steel = Color(hex: 0x6E88C4)
    /// Lifted blue-steel for secondary copy that has to stay legible on the midnight canvas.
    static let steelBright = Color(hex: 0x8FA6DA)
    static let crimson = Color(hex: 0xB33A3A)

    static let cardRadius: CGFloat = 22
    static let hairline = Color(hex: 0xE8B44A).opacity(0.18)

    static var canvas: LinearGradient {
        LinearGradient(
            colors: [canvasTop, canvasBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var goldSheen: LinearGradient {
        LinearGradient(
            colors: [Color(hex: 0xF6D488), gold, goldDeep],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    /// Creates a color from a 24-bit RGB literal such as `0xE8B44A`.
    nonisolated init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

extension View {
    /// Content-surface treatment: translucent midnight panel with a gold hairline.
    func regaliaCard(cornerRadius: CGFloat = RegaliaTheme.cardRadius, highlighted: Bool = false) -> some View {
        background {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(RegaliaTheme.surface.opacity(0.62))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            highlighted ? RegaliaTheme.gold.opacity(0.55) : RegaliaTheme.hairline,
                            lineWidth: highlighted ? 1.2 : 1
                        )
                )
        }
        .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Floating-control treatment: real Liquid Glass on iOS 26, material fallback below.
    @ViewBuilder
    func regaliaGlass(in shape: some Shape = Capsule(), tint: Color? = nil) -> some View {
        if #available(iOS 26.0, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint.opacity(0.35)).interactive(), in: shape)
            } else {
                self.glassEffect(.regular.interactive(), in: shape)
            }
        } else {
            self.background {
                shape.fill(.ultraThinMaterial)
                    .overlay(shape.fill((tint ?? .white).opacity(tint == nil ? 0.06 : 0.22)))
                    .overlay(shape.stroke(Color.white.opacity(0.16), lineWidth: 0.6))
            }
        }
    }
}
