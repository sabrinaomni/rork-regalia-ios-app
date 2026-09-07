import SwiftUI

/// Press-and-hold control used to speak a declaration aloud before advancing.
struct HoldToDeclareButton: View {
    let title: String
    var holdSeconds: Double = 1.6
    var isComplete: Bool
    let onComplete: () -> Void

    @State private var progress: Double = 0
    @State private var isHolding = false
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(RegaliaTheme.steel.opacity(0.3), lineWidth: 2)
                Circle()
                    .trim(from: 0, to: isComplete ? 1 : progress)
                    .stroke(RegaliaTheme.gold, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: isComplete ? "checkmark" : "quote.bubble")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isComplete ? RegaliaTheme.gold : RegaliaTheme.bone.opacity(0.85))
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RegaliaTheme.bone)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(isComplete ? "Declared" : (isHolding ? "Keep holding…" : "Hold to declare"))
                    .font(.caption)
                    .foregroundStyle(isComplete ? RegaliaTheme.gold.opacity(0.9) : RegaliaTheme.steel)
                    .contentTransition(.opacity)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .regaliaCard(cornerRadius: 18, highlighted: isComplete)
        .scaleEffect(isHolding ? 0.985 : 1)
        .animation(.easeOut(duration: 0.15), value: isHolding)
        .contentShape(.rect)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isComplete, !isHolding else { return }
                    startHold()
                }
                .onEnded { _ in
                    endHold()
                }
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint("Press and hold to declare this aloud")
        .accessibilityAction {
            guard !isComplete else { return }
            complete()
        }
        .onDisappear { invalidate() }
    }

    private func startHold() {
        isHolding = true
        Haptics.tap()
        let tick = 0.02
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { _ in
            Task { @MainActor in
                guard isHolding else { return }
                progress = min(progress + tick / holdSeconds, 1)
                if progress >= 1 {
                    complete()
                }
            }
        }
    }

    private func endHold() {
        guard !isComplete else { return }
        isHolding = false
        invalidate()
        withAnimation(.easeOut(duration: 0.3)) { progress = 0 }
    }

    private func complete() {
        isHolding = false
        invalidate()
        progress = 1
        Haptics.success()
        onComplete()
    }

    private func invalidate() {
        timer?.invalidate()
        timer = nil
    }
}
