import SwiftUI

/// The full-screen daily Regalia: 7 armour pieces, Renew Your Mind, Stand Firm.
struct SessionView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var index: Int = 0
    @State private var declaredSteps: Set<String> = []
    @State private var handedOver: String = ""
    @State private var showCompletion = false
    @State private var flash = false
    @FocusState private var noteFocused: Bool

    private let steps = SessionStep.all

    /// Anchor used to snap each new step back to the top of the scroll view.
    private static let topAnchor = "session.top"

    private var step: SessionStep { steps[min(index, steps.count - 1)] }

    private var equippedCountForStage: Int {
        switch step {
        case .armour(let piece): piece.order - 1
        case .renew, .stand: 7
        }
    }

    private var isStepSatisfied: Bool {
        switch step {
        case .armour: declaredSteps.contains(step.id)
        case .renew: true
        case .stand: true
        }
    }

    var body: some View {
        ZStack {
            RegaliaBackground(tint: RegaliaTheme.gold, bloomStrength: 0.26)

            if showCompletion {
                SessionCompleteView {
                    dismiss()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                sessionBody
                    .transition(.opacity)
            }

            if flash {
                RegaliaTheme.gold.opacity(0.16)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }
        }
        .onAppear {
            store.prepareSessionContent()
            handedOver = store.today.handedOver
            index = 0
        }
    }

    // MARK: - Session body

    private var sessionBody: some View {
        VStack(spacing: 0) {
            hud

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: RegaliaLayout.artToCopy) {
                        MascotView(
                            stage: MascotStage.stage(forEquippedCount: equippedCountForStage),
                            intensity: 1.1
                        )
                        .mascotStage(height: RegaliaLayout.sessionArt)
                        .animation(.spring(response: 0.7, dampingFraction: 0.72), value: equippedCountForStage)
                        .id(Self.topAnchor)

                        stepContent
                            .id(step.id)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(y: 22)),
                                removal: .opacity.combined(with: .offset(y: -16))
                            ))
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, RegaliaLayout.scrollBottom)
                }
                .scrollIndicators(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .onChange(of: index) { _, _ in
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                        proxy.scrollTo(Self.topAnchor, anchor: .top)
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            advanceButton
        }
    }

    private var hud: some View {
        VStack(spacing: RegaliaLayout.rowStack + 2) {
            ZStack {
                VStack(spacing: 4) {
                    Text("Step \(index + 1) of \(steps.count)")
                        .font(.footnote)
                        .foregroundStyle(RegaliaTheme.steel)
                    Text(step.title)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(RegaliaTheme.bone)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.7)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 56)

                HStack {
                    Button {
                        Haptics.tap()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(RegaliaTheme.bone.opacity(0.9))
                            .frame(width: 34, height: 34)
                            .regaliaGlass(in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close session")

                    Spacer()
                }
            }

            StepProgressBar(total: steps.count, current: index)

            if case .armour(let piece) = step {
                ArmourTrack(
                    equipped: store.today.equippedPieces,
                    activePiece: piece,
                    shimmerTrigger: store.today.equippedPieces.count
                )
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 14)
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .armour(let piece):
            armourStep(piece)
        case .renew:
            renewStep
        case .stand:
            standStep
        }
    }

    private func armourStep(_ piece: ArmourPiece) -> some View {
        VStack(spacing: RegaliaLayout.cardStack) {
            Text(piece.teaching)
                .font(.subheadline)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineSpacing(2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 6)

            VerseCard(verse: piece.verse)

            if let support = ScriptureLibrary.supportingVerse(for: piece, on: store.today.date) {
                supportingVerseCard(piece, verse: support)
            }

            HoldToDeclareButton(
                title: "Say it: “\(piece.declaration)”",
                isComplete: declaredSteps.contains(step.id)
            ) {
                let id = step.id
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    _ = declaredSteps.insert(id)
                }
            }
        }
    }

    /// A quieter second card: the Scripture behind the piece's truth.
    private func supportingVerseCard(_ piece: ArmourPiece, verse: Verse) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(piece.truthLabel.uppercased())
                .font(.caption2.weight(.semibold))
                .kerning(1.4)
                .foregroundStyle(RegaliaTheme.gold.opacity(0.8))
            Text(verse.text)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            Text(verse.reference)
                .font(.footnote.italic())
                .foregroundStyle(RegaliaTheme.steel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .regaliaCard()
    }

    private var renewStep: some View {
        VStack(spacing: RegaliaLayout.cardStack) {
            VerseCard(verse: Verse(
                id: "rom12-2",
                text: "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.",
                reference: "Romans 12:2"
            ))

            if let renewal = store.today.renewal {
                VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
                    LabeledRow(label: "The lie", value: renewal.lie, tint: RegaliaTheme.crimson, symbol: "xmark.circle.fill")
                    Divider().overlay(RegaliaTheme.hairline)
                    LabeledRow(label: "The truth", value: renewal.truth, tint: RegaliaTheme.gold, symbol: "checkmark.seal.fill")
                    Text(renewal.reference)
                        .font(.footnote.italic())
                        .foregroundStyle(RegaliaTheme.steel)
                }
                .padding(18)
                .regaliaCard()
            }

            if let daily = store.today.dailyVerse {
                VStack(alignment: .leading, spacing: 10) {
                    Text("TODAY'S VERSE")
                        .font(.caption2.weight(.semibold))
                        .kerning(1.4)
                        .foregroundStyle(RegaliaTheme.gold.opacity(0.8))
                    Text(daily.text)
                        .font(.system(size: 17, weight: .regular, design: .serif))
                        .foregroundStyle(RegaliaTheme.bone)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(daily.reference)
                        .font(.footnote.italic())
                        .foregroundStyle(RegaliaTheme.steel)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .regaliaCard()
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("What are you handing over today?")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(RegaliaTheme.bone)

                TextField("The thought I keep going back to…", text: $handedOver, axis: .vertical)
                    .lineLimit(2...4)
                    .textInputAutocapitalization(.sentences)
                    .font(.callout)
                    .foregroundStyle(RegaliaTheme.bone)
                    .tint(RegaliaTheme.gold)
                    .focused($noteFocused)
                    .padding(12)
                    .background {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(RegaliaTheme.canvasBottom.opacity(0.6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(RegaliaTheme.hairline, lineWidth: 1)
                            )
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(18)
            .regaliaCard()
        }
    }

    private var standStep: some View {
        VStack(spacing: RegaliaLayout.cardStack) {
            if let verse = store.today.temptationVerse {
                VerseCard(verse: verse)
            }

            if let prayer = store.today.prayer {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "hands.and.sparkles.fill")
                            .foregroundStyle(RegaliaTheme.gold)
                        Text(prayer.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(RegaliaTheme.bone)
                    }

                    PrayerBody(text: prayer.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .regaliaCard(highlighted: true)
            }

            if !store.profile.guardedApps.isEmpty {
                Text("Sealing the day releases \(store.profile.guardedApps.count) guarded app\(store.profile.guardedApps.count == 1 ? "" : "s").")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var advanceButton: some View {
        VStack(spacing: 8) {
            RegaliaPrimaryButton(
                title: step.actionLabel,
                systemImage: step.symbol,
                showsChevron: false
            ) {
                advance()
            }
            .opacity(isStepSatisfied ? 1 : 0.45)
            .disabled(!isStepSatisfied)
            .animation(.easeInOut(duration: 0.25), value: isStepSatisfied)

            if case .armour = step, !isStepSatisfied {
                Text("Declare it out loud to move on")
                    .font(.caption)
                    .foregroundStyle(RegaliaTheme.steelBright)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .background {
            LinearGradient(
                colors: [RegaliaTheme.canvasBottom.opacity(0), RegaliaTheme.canvasBottom.opacity(0.95)],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
            .ignoresSafeArea()
        }
    }

    // MARK: - Flow

    private func advance() {
        noteFocused = false

        switch step {
        case .armour(let piece):
            store.equip(piece)
            Haptics.equip()
            withAnimation(.easeOut(duration: 0.14)) { flash = true }
            withAnimation(.easeIn(duration: 0.45).delay(0.14)) { flash = false }
        case .renew:
            store.setHandedOver(handedOver.trimmingCharacters(in: .whitespacesAndNewlines))
        case .stand:
            store.completeSession()
            Haptics.success()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showCompletion = true
            }
            return
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
            index = min(index + 1, steps.count - 1)
        }
    }
}

/// A label / value pair used inside the Renew Your Mind card.
private struct LabeledRow: View {
    let label: String
    let value: String
    let tint: Color
    let symbol: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15))
                .foregroundStyle(tint)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                    .kerning(1.2)
                    .foregroundStyle(RegaliaTheme.steel)
                Text(value)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RegaliaTheme.bone)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}
