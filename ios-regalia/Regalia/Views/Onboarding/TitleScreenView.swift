import SwiftUI

/// The animated title screen: REGALIA lights up, then the three promises write
/// themselves out over the lion before the first-run onboarding begins.
struct TitleScreenView: View {
    var onBegin: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var nameAppeared = false
    @State private var ruleShown = false
    @State private var sheenMoved = false
    @State private var typed: [String] = ["", "", ""]
    @State private var activeLine: Int?
    @State private var lionAppeared = false
    @State private var buttonAppeared = false
    @State private var typingTask: Task<Void, Never>?

    private let promises = ["Fight Temptation.", "Renew Your Mind.", "Embrace Your Identity."]
    private let scriptureLine = "Ephesians 6:10-18 · Romans 12:2 · 1 Corinthians 10:13"

    private var isComplete: Bool { buttonAppeared }

    var body: some View {
        ZStack {
            RegaliaBackground(bloomStrength: 0.26)

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                nameBlock
                rule
                promisesBlock

                MascotView(stage: .radiant, intensity: 1.15)
                    .mascotStage(height: RegaliaLayout.heroArt - 48)
                    .opacity(lionAppeared ? 1 : 0)
                    .scaleEffect(lionAppeared ? 1.0 : 0.96, anchor: .bottom)
                    .animation(.easeOut(duration: 1.0), value: lionAppeared)

                if lionAppeared {
                    Text(scriptureLine)
                        .font(.footnote)
                        .foregroundStyle(RegaliaTheme.steelBright)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 6)
                        .transition(.opacity)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { skipToComplete() }
        }
        .safeAreaInset(edge: .bottom) {
            beginButton
        }
        .onAppear(perform: playIntro)
        .onDisappear { typingTask?.cancel() }
    }

    // MARK: - Pieces

    /// REGALIA: letters fade up in a stagger, then a slow sheen sweeps across once.
    private var nameBlock: some View {
        Text("REGALIA")
            .font(.system(size: 34, weight: .bold, design: .serif))
            .kerning(10)
            .foregroundStyle(RegaliaTheme.gold)
            .overlay {
                sheen
                    .mask { Text("REGALIA").font(.system(size: 34, weight: .bold, design: .serif)).kerning(10) }
            }
            .opacity(nameAppeared ? 1 : 0)
            .offset(y: nameAppeared ? 0 : 12)
            .animation(.easeOut(duration: 0.7), value: nameAppeared)
    }

    /// A single pass of light across the settled name.
    private var sheen: some View {
        GeometryReader { proxy in
            let span = proxy.size.width + 120
            LinearGradient(
                colors: [.clear, RegaliaTheme.bone.opacity(0.85), .clear],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: 70)
            .offset(x: sheenMoved ? span : -70)
            .blur(radius: 3)
            .blendMode(.screen)
            .frame(width: proxy.size.width)
        }
        .allowsHitTesting(false)
    }

    /// A thin gold rule that draws outward from the centre under the name.
    private var rule: some View {
        HStack {
            Spacer(minLength: 0)
            Rectangle()
                .fill(RegaliaTheme.gold.opacity(0.7))
                .frame(height: 1)
                .scaleEffect(x: ruleShown ? 1 : 0.02, anchor: .center)
                .animation(.easeInOut(duration: 0.6), value: ruleShown)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 88)
        .padding(.vertical, 16)
    }

    /// The three promises, typed one after another. The line being written carries
    /// the gold accent; finished lines rest in warm bone.
    private var promisesBlock: some View {
        VStack(spacing: 12) {
            ForEach(promises.indices, id: \.self) { index in
                promiseLine(index)
            }
        }
        .padding(.bottom, 4)
    }

    private func promiseLine(_ index: Int) -> some View {
        let isActive = activeLine == index
        return HStack(spacing: 2) {
            Text(typed[index])
                .font(.system(size: 19, weight: isActive ? .semibold : .medium, design: .serif))
                .foregroundStyle(isActive ? RegaliaTheme.gold : RegaliaTheme.bone.opacity(0.94))
            if isActive {
                Cursor()
                    .padding(.leading, 1)
            }
        }
        .font(.system(size: 19, design: .serif))
    }

    private var beginButton: some View {
        Group {
            if buttonAppeared {
                RegaliaPrimaryButton(title: "Begin") {
                    Haptics.tap()
                    onBegin()
                }
                .transition(.opacity)
            } else {
                Color.clear
                    .frame(height: 54)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }

    // MARK: - Sequence

    private func playIntro() {
        guard !isComplete else { return }

        if reduceMotion {
            withAnimation(.easeOut(duration: 0.45)) {
                nameAppeared = true
                ruleShown = true
                sheenMoved = false
                typed = promises
                lionAppeared = true
                buttonAppeared = true
            }
            return
        }

        typingTask = Task { @MainActor in
            withAnimation(.easeOut(duration: 0.7)) { nameAppeared = true }
            try? await Task.sleep(for: .seconds(0.65))
            guard !Task.isCancelled else { return }
            Haptics.tap()

            withAnimation(.easeInOut(duration: 0.6)) { ruleShown = true }
            withAnimation(.easeInOut(duration: 1.0).delay(0.15)) { sheenMoved = true }
            try? await Task.sleep(for: .seconds(0.7))
            guard !Task.isCancelled else { return }

            for index in promises.indices {
                guard !Task.isCancelled else { return }
                activeLine = index
                typed[index] = ""
                for character in promises[index] {
                    guard !Task.isCancelled else { return }
                    typed[index].append(character)
                    try? await Task.sleep(for: .milliseconds(26))
                }
                try? await Task.sleep(for: .milliseconds(200))
            }
            guard !Task.isCancelled else { return }
            activeLine = nil

            withAnimation(.easeOut(duration: 0.9)) { lionAppeared = true }
            try? await Task.sleep(for: .seconds(0.5))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.5)) { buttonAppeared = true }
        }
    }

    /// Tapping anywhere finishes the writing immediately.
    private func skipToComplete() {
        guard !isComplete else { return }
        typingTask?.cancel()
        typingTask = nil
        Haptics.tap()
        withAnimation(.easeOut(duration: 0.3)) {
            nameAppeared = true
            ruleShown = true
            sheenMoved = true
            typed = promises
            activeLine = nil
            lionAppeared = true
            buttonAppeared = true
        }
    }
}

/// The soft gold caret at the end of the line being written.
private struct Cursor: View {
    @State private var visible = true

    var body: some View {
        Rectangle()
            .fill(RegaliaTheme.gold)
            .frame(width: 2, height: 18)
            .opacity(visible ? 0.9 : 0.15)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true)) {
                    visible = false
                }
            }
            .offset(y: 2)
    }
}
