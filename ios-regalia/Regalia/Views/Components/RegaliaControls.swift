import SwiftUI
import UIKit

/// Light haptic helpers used across the session flow.
enum Haptics {
    static func tap() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    static func equip() {
        UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: 0.9)
    }

    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    static func warn() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }
}

/// The single gold call-to-action used on Today, the lock gate, and the session.
struct RegaliaPrimaryButton: View {
    let title: String
    var systemImage: String?
    var showsChevron: Bool = true
    var tint: Color = RegaliaTheme.gold
    let action: () -> Void

    @State private var pressed = false

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if showsChevron {
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .opacity(0.7)
                }
            }
            .foregroundStyle(tint)
            .padding(.vertical, 17)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .background {
                Capsule()
                    .fill(tint.opacity(0.14))
                    .overlay(Capsule().stroke(tint.opacity(0.75), lineWidth: 1.2))
                    .shadow(color: tint.opacity(0.35), radius: pressed ? 6 : 16, y: 4)
            }
            .clipShape(.capsule)
            .scaleEffect(pressed ? 0.97 : 1)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isButton)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { pressed = false }
                }
        )
    }
}

/// Scripture presented on a translucent midnight panel.
struct VerseCard: View {
    let verse: Verse
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "quote.opening")
                .font(.system(size: compact ? 14 : 18, weight: .bold))
                .foregroundStyle(RegaliaTheme.gold.opacity(0.8))
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 8) {
                Text(verse.text)
                    .font(compact ? .callout : .system(size: 19, weight: .medium, design: .serif))
                    .foregroundStyle(RegaliaTheme.bone)
                    .lineSpacing(compact ? 2 : 5)
                    .fixedSize(horizontal: false, vertical: true)

                Text(verse.reference)
                    .font(.footnote.italic())
                    .foregroundStyle(RegaliaTheme.steel)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 14 : 18)
        .regaliaCard()
    }
}

/// The seven-shield armour track shown on Today and inside the session HUD.
/// Bump `shimmerTrigger` (e.g. to the equipped count) to replay the travelling
/// gold sheen whenever a piece is fastened.
struct ArmourTrack: View {
    let equipped: [ArmourPiece]
    var activePiece: ArmourPiece?
    var shimmerTrigger: Int = 0

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sheenOffset: CGFloat = -1
    @State private var poppedPiece: ArmourPiece?

    var body: some View {
        HStack(spacing: 10) {
            ForEach(ArmourPiece.allCases) { piece in
                let isOn = equipped.contains(piece)
                let isActive = activePiece == piece

                Image(systemName: isOn ? "shield.fill" : "shield")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(isOn ? AnyShapeStyle(RegaliaTheme.goldSheen) : AnyShapeStyle(RegaliaTheme.steel.opacity(0.45)))
                    .shadow(color: isOn ? RegaliaTheme.gold.opacity(0.6) : .clear, radius: 8)
                    .scaleEffect(scale(for: piece, isActive: isActive))
                    .overlay {
                        if isActive {
                            Circle()
                                .stroke(RegaliaTheme.gold.opacity(0.5), lineWidth: 1)
                                .frame(width: 34, height: 34)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel("\(piece.shortTitle) \(isOn ? "equipped" : "not equipped")")
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.6), value: equipped)
        .overlay { sheen }
        .onChange(of: shimmerTrigger) { _, _ in
            runSheen()
        }
        .onChange(of: equipped) { oldValue, newValue in
            guard newValue.count > oldValue.count, let added = newValue.last else { return }
            poppedPiece = added
            Task {
                try? await Task.sleep(for: .milliseconds(450))
                poppedPiece = nil
            }
        }
    }

    private func scale(for piece: ArmourPiece, isActive: Bool) -> CGFloat {
        if poppedPiece == piece { return 1.28 }
        if isActive { return 1.18 }
        return 1
    }

    /// A bright band of gold light that sweeps the track left to right.
    @ViewBuilder
    private var sheen: some View {
        GeometryReader { geo in
            if sheenOffset > -0.5, !reduceMotion {
                LinearGradient(
                    colors: [.clear, RegaliaTheme.gold.opacity(0.85), RegaliaTheme.bone.opacity(0.6), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: geo.size.width * 0.22)
                .offset(x: sheenOffset * geo.size.width)
                .blendMode(.screen)
                .allowsHitTesting(false)
            }
        }
        .allowsHitTesting(false)
    }

    private func runSheen() {
        guard !reduceMotion else { return }
        sheenOffset = -0.4
        withAnimation(.easeInOut(duration: 0.8)) {
            sheenOffset = 1.4
        }
    }
}

/// Segmented step indicator used at the top of the session.
struct StepProgressBar: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { index in
                Capsule()
                    .fill(index <= current ? AnyShapeStyle(RegaliaTheme.goldSheen) : AnyShapeStyle(RegaliaTheme.steel.opacity(0.28)))
                    .frame(height: 5)
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: current)
        .accessibilityLabel("Step \(current + 1) of \(total)")
    }
}

/// A selectable capsule used for moods, filters, and onboarding options.
struct RegaliaChip: View {
    let title: String
    var systemImage: String?
    /// Filled variant: a selected chip becomes solid gold with dark text.
    var isFilled: Bool = false
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .regular))
            }
            .foregroundStyle(foreground)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background {
                Capsule()
                    .fill(fill)
                    .overlay(
                        Capsule().stroke(
                            isSelected && isFilled ? Color.clear : stroke,
                            lineWidth: 1
                        )
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }

    private var foreground: Color {
        if isSelected { return isFilled ? RegaliaTheme.canvasBottom : RegaliaTheme.gold }
        return RegaliaTheme.bone.opacity(0.85)
    }

    private var fill: Color {
        if isSelected { return isFilled ? RegaliaTheme.gold : RegaliaTheme.gold.opacity(0.16) }
        return RegaliaTheme.surface.opacity(0.55)
    }

    private var stroke: Color {
        isSelected ? RegaliaTheme.gold.opacity(0.8) : RegaliaTheme.hairline
    }
}

/// A full-width selectable row used throughout onboarding and settings.
struct RegaliaSelectRow: View {
    let title: String
    var subtitle: String?
    var systemImage: String
    var tint: Color = RegaliaTheme.gold
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? tint : RegaliaTheme.steel)
                    .frame(width: 34, height: 34)
                    .background {
                        Circle().fill(isSelected ? tint.opacity(0.16) : RegaliaTheme.surface.opacity(0.7))
                    }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(RegaliaTheme.bone)
                        .multilineTextAlignment(.leading)
                    if let subtitle {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steel)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 8)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? tint : RegaliaTheme.steel.opacity(0.4))
            }
            .padding(.vertical, 13)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .regaliaCard(cornerRadius: 18, highlighted: isSelected)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}
