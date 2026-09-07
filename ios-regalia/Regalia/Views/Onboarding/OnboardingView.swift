import SwiftUI

/// The first-run flow: why they came, how they feel, what distracts them,
/// which apps to guard, and when their daily Regalia happens.
struct OnboardingView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ReminderScheduler.self) private var reminders
    @Environment(SubscriptionStore.self) private var subscriptions

    @State private var stepIndex: Int = 0
    @State private var wantsReminders = true
    @State private var piecesRevealed = false
    @State private var proofFactsRevealed = false
    @State private var draft = OnboardingProfile()
    @State private var time: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @FocusState private var nameFocused: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let steps: [OnboardingStep] = OnboardingStep.allCases

    /// Scroll anchor at the very top of the flow, used to reset each step.
    private static let topAnchor = "onboarding-flow-top"

    private var step: OnboardingStep { steps[min(stepIndex, steps.count - 1)] }

    var body: some View {
        Group {
            if step == .paywall {
                PaywallView(
                    context: .onboarding,
                    onSubscribed: { advance() },
                    onBack: { retreat() },
                    name: draft.name
                )
                .transition(.opacity)
                .task {
                    // A restored subscriber never has to see the plans again.
                    if subscriptions.hasAccess { advance() }
                }
            } else {
                flow
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: step)
    }

    private var flow: some View {
        ZStack {
            RegaliaBackground(bloomStrength: 0.24)

            VStack(spacing: 0) {
                topBar

                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(spacing: 0) {
                            // Stable anchor outside the per-step identity, so the
                            // proxy can always pull the next screen to the top.
                            Color.clear
                                .frame(height: 0)
                                .id(Self.topAnchor)

                            VStack(alignment: .leading, spacing: RegaliaLayout.headerToContent) {
                                header
                                content
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, step.needsBreathingRoom ? 18 : 6)
                            .padding(.bottom, RegaliaLayout.scrollBottom)
                            .id(step)
                            .transition(.asymmetric(
                                insertion: .opacity.combined(with: .offset(x: 30)),
                                removal: .opacity.combined(with: .offset(x: -24))
                            ))
                        }
                    }
                    .scrollIndicators(.hidden)
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: stepIndex) { _, _ in
                        // Every step opens at the top, forwards and backwards,
                        // with the same gentle glide the daily session uses.
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.9)) {
                            proxy.scrollTo(Self.topAnchor, anchor: .top)
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) { footer }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack(spacing: 12) {
            if stepIndex > 0 {
                Button {
                    retreat()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(RegaliaTheme.bone.opacity(0.9))
                        .frame(width: 34, height: 34)
                        .regaliaGlass(in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }

            StepProgressBar(total: steps.count, current: stepIndex)
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 18)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(step.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(RegaliaTheme.bone)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            if let subtitle = step.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:
            welcomeStep
        case .battle:
            battleStep
        case .armour:
            armourStep
        case .stand:
            standStep
        case .name:
            nameStep
        case .reasons:
            multiSelect(SeekingReason.allCases, selected: draft.reasons) { reason in
                toggle(reason, in: \.reasons)
            }
        case .mood:
            moodStep
        case .causes:
            multiSelect(DistractionCause.allCases, selected: draft.causes) { cause in
                toggle(cause, in: \.causes)
            }
        case .apps:
            appsStep
        case .time:
            timeStep
        case .proof:
            proofStep
        case .covenant:
            covenantStep
        case .paywall:
            // Drawn full-bleed by `PaywallView`, which replaces this whole flow.
            EmptyView()
        case .deviceGuard:
            deviceGuardStep
        }
    }

    private var welcomeStep: some View {
        VStack(spacing: 14) {
            MascotView(stage: .radiant, intensity: 1.2)
                .mascotStage(height: RegaliaLayout.heroArt)
                .padding(.bottom, 4)

            WelcomeVerseTicker()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Teaching steps

    private var battleStep: some View {
        VStack(spacing: RegaliaLayout.artToCopy) {
            DawnMascotView(dawnProgress: 0.25)
                .mascotStage(height: RegaliaLayout.teachingArt)

            Text("Your phone isn't the enemy. Behind every scroll is a real fight for your attention, your purity, and your peace — and Scripture says it isn't fought by trying harder. It's fought standing, in armour God provides.")
                .font(.system(size: 16))
                .foregroundStyle(RegaliaTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            teachingVerse(
                "For our struggle is not against flesh and blood, but against the powers of this dark world.",
                reference: "Ephesians 6:12"
            )
        }
    }

    private var armourStep: some View {
        VStack(spacing: RegaliaLayout.artToCopy) {
            DawnMascotView(dawnProgress: 0.6)
                .mascotStage(height: RegaliaLayout.teachingArt - 28)

            Text("You don't fight for victory — you dress for it. Seven pieces, already given, put on one at a time:")
                .font(.system(size: 16))
                .foregroundStyle(RegaliaTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(ArmourPiece.allCases) { piece in
                    armourRow(piece)
                }
            }
            .padding(18)
            .regaliaCard(highlighted: true)

            Text("Ephesians 6:13-18")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .kerning(3)
                .textCase(.uppercase)
                .foregroundStyle(RegaliaTheme.gold)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .onAppear {
            guard !piecesRevealed else { return }
            withAnimation(.easeOut(duration: 0.5).delay(2.6)) {
                piecesRevealed = true
            }
        }
    }

    /// Each piece settles into place as the dawn reaches it — a soft gold stagger.
    private func armourRow(_ piece: ArmourPiece) -> some View {
        let index = piece.order - 1
        return HStack(spacing: 12) {
            Image(systemName: piece.symbol)
                .font(.system(size: 14))
                .foregroundStyle(RegaliaTheme.gold)
                .frame(width: 22)
            Text(piece.title)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(RegaliaTheme.bone)
            Spacer(minLength: 0)
        }
        .opacity(piecesRevealed ? 1 : 0)
        .offset(y: piecesRevealed ? 0 : 8)
        .animation(
            .easeOut(duration: 0.45).delay(Double(index) * 0.28),
            value: piecesRevealed
        )
    }

    private var standStep: some View {
        VStack(spacing: RegaliaLayout.artToCopy) {
            DawnMascotView(dawnProgress: 1.0)
                .mascotStage(height: RegaliaLayout.teachingArt - 16)

            VStack(alignment: .leading, spacing: 14) {
                standLine("sunrise.fill", "About eight minutes each morning, before the world gets your attention.")
                standLine("hand.raised.fill", "One piece at a time — you hold each declaration for a breath before it's fastened.")
                standLine("book.fill", "A verse and a prayer are chosen for you, and kept in your archive forever.")
                standLine("lock.fill", "Your guarded apps stay shut until the armour is on.")
            }
            .padding(18)
            .regaliaCard()

            teachingVerse(
                "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.",
                reference: "Romans 12:2"
            )
        }
    }

    private func standLine(_ symbol: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 13))
                .foregroundStyle(RegaliaTheme.gold)
                .frame(width: 20)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 15))
                .foregroundStyle(RegaliaTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private func teachingVerse(_ text: String, reference: String) -> some View {
        VStack(spacing: 8) {
            Text("\u{201C}\(text)\u{201D}")
                .font(.system(size: 15, weight: .medium).italic())
                .foregroundStyle(RegaliaTheme.bone.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(reference)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .kerning(3)
                .textCase(.uppercase)
                .foregroundStyle(RegaliaTheme.gold)
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .regaliaCard()
    }

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
            TextField("Your name", text: $draft.name)
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(RegaliaTheme.bone)
                .tint(RegaliaTheme.gold)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($nameFocused)
                .padding(18)
                .frame(maxWidth: .infinity)
                .regaliaCard()

            chipGroup("Gender", selection: draft.gender, label: { $0.label }) { value in
                draft.gender = value
            }

            chipGroup("Age", selection: draft.ageBand, label: { $0.label }) { value in
                draft.ageBand = value
            }

            chipGroup("Marital status", selection: draft.maritalStatus, label: { $0.label }) { value in
                draft.maritalStatus = value
            }

            chipGroup("Faith stage", selection: draft.faithStage, label: { $0.label }) { value in
                draft.faithStage = value
            }

            Text("Only stored on this device.")
                .font(.caption)
                .foregroundStyle(RegaliaTheme.steelBright)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear { nameFocused = true }
    }

    /// A labelled group of single-select chips; tapping the selected chip clears it.
    private func chipGroup<T: Identifiable & Hashable & CaseIterable>(
        _ heading: String,
        selection: T?,
        label: @escaping (T) -> String,
        onChange: @escaping (T?) -> Void
    ) -> some View where T.AllCases: RandomAccessCollection {
        VStack(alignment: .leading, spacing: 10) {
            Text(heading)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .kerning(2)
                .textCase(.uppercase)
                .foregroundStyle(RegaliaTheme.steel)

            RegaliaFlowLayout(spacing: 10) {
                ForEach(T.allCases) { option in
                    RegaliaChip(
                        title: label(option),
                        isFilled: true,
                        isSelected: selection == option
                    ) {
                        onChange(selection == option ? nil : option)
                    }
                }
            }
        }
    }

    private var moodStep: some View {
        VStack(spacing: RegaliaLayout.rowStack) {
            ForEach(Mood.allCases) { mood in
                RegaliaSelectRow(
                    title: mood.label,
                    subtitle: mood.response,
                    systemImage: mood.symbol,
                    isSelected: draft.baselineMood == mood
                ) {
                    draft.baselineMood = mood
                }
            }
        }
    }

    private var appsStep: some View {
        VStack(spacing: RegaliaLayout.rowStack) {
            ForEach(GuardedApp.catalog) { app in
                RegaliaSelectRow(
                    title: app.name,
                    systemImage: app.symbol,
                    tint: app.tint,
                    isSelected: draft.guardedAppIDs.contains(app.id)
                ) {
                    if draft.guardedAppIDs.contains(app.id) {
                        draft.guardedAppIDs.remove(app.id)
                    } else {
                        draft.guardedAppIDs.insert(app.id)
                    }
                }
            }
        }
    }

    private var timeStep: some View {
        VStack(spacing: RegaliaLayout.cardStack + 2) {
            DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .tint(RegaliaTheme.gold)
                .environment(\.colorScheme, .dark)
                .frame(maxWidth: .infinity)
                .frame(height: 204)
                .padding(.vertical, 6)
                .regaliaCard()

            HStack(spacing: 10) {
                Image(systemName: "sunrise.fill")
                    .foregroundStyle(RegaliaTheme.gold)
                Text("Most people put the armour on before their first scroll.")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var covenantStep: some View {
        VStack(spacing: RegaliaLayout.artToCopy) {
            MascotView(stage: .radiant, intensity: 1.2)
                .mascotStage(height: 228)

            VStack(alignment: .leading, spacing: 14) {
                covenantLine("All seven pieces of the armour, every day.")
                covenantLine("A renewed mind before a scrolled feed.")
                covenantLine("\(draft.guardedAppIDs.count) app\(draft.guardedAppIDs.count == 1 ? "" : "s") guarded until you're armoured.")
                covenantLine("One verse and one prayer kept forever.")
            }
            .padding(18)
            .regaliaCard(highlighted: true)
        }
    }

    private var proofStep: some View {
        VStack(spacing: RegaliaLayout.artToCopy) {
            DisciplineCurve()

            VStack(alignment: .leading, spacing: 14) {
                proofFact(
                    "clock.badge.checkmark",
                    "Most mornings lose the first hour to the feed before a single word of Scripture.",
                    index: 0
                )
                proofFact(
                    "flame.fill",
                    "Discipline isn't willpower. It's a short stand, repeated every morning, until it holds you.",
                    index: 1
                )
            }
            .padding(18)
            .regaliaCard()

            teachingVerse(
                "Do not conform to the pattern of this world, but be transformed by the renewing of your mind.",
                reference: "Romans 12:2"
            )
        }
        .onAppear {
            guard !proofFactsRevealed else { return }
            if reduceMotion {
                proofFactsRevealed = true
            } else {
                withAnimation(.easeOut(duration: 0.5).delay(2.15)) {
                    proofFactsRevealed = true
                }
            }
        }
    }

    private func proofFact(_ symbol: String, _ text: String, index: Int) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(RegaliaTheme.gold)
                .font(.system(size: 15))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(RegaliaTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .opacity(proofFactsRevealed ? 1 : 0)
        .offset(y: proofFactsRevealed ? 0 : 10)
        .animation(.easeOut(duration: 0.45).delay(Double(index) * 0.35), value: proofFactsRevealed)
    }

    private var deviceGuardStep: some View {
        VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
            GuardSetupPanel(showsFootnote: false)
                .padding(18)
                .regaliaCard()

            VStack(alignment: .leading, spacing: 12) {
                Toggle(isOn: $wantsReminders) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Daily reminder")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(RegaliaTheme.bone)
                        Text("One nudge at your Regalia time, carrying the day's verse.")
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steelBright)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(RegaliaTheme.gold)
            }
            .padding(18)
            .regaliaCard()

            Text("Apple has to approve app blocking for your developer account before the lock works on a physical iPhone. Until then Regalia guards inside the app — everything else here works today.")
                .font(.caption)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineSpacing(1.5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
    }

    private func covenantLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(RegaliaTheme.gold)
                .font(.system(size: 15))
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 16))
                .foregroundStyle(RegaliaTheme.bone)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            RegaliaPrimaryButton(
                title: step.actionTitle,
                systemImage: step == .deviceGuard ? "shield.fill" : nil,
                showsChevron: step != .deviceGuard
            ) {
                advance()
            }
            .opacity(canAdvance ? 1 : 0.45)
            .disabled(!canAdvance)
            .animation(.easeInOut(duration: 0.2), value: canAdvance)

            if step.isSkippable {
                Button("Skip for now") {
                    Haptics.tap()
                    advance()
                }
                .font(.footnote)
                .foregroundStyle(RegaliaTheme.steel)
                .buttonStyle(.plain)
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

    // MARK: - Logic

    private var canAdvance: Bool {
        switch step {
        case .welcome, .battle, .armour, .stand, .mood, .time, .proof, .covenant, .paywall, .deviceGuard: true
        case .name: !draft.name.trimmingCharacters(in: .whitespaces).isEmpty
        case .reasons: !draft.reasons.isEmpty
        case .causes: !draft.causes.isEmpty
        case .apps: !draft.guardedAppIDs.isEmpty
        }
    }

    private func retreat() {
        Haptics.tap()
        nameFocused = false
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            stepIndex = max(stepIndex - 1, 0)
        }
    }

    private func advance() {
        nameFocused = false
        guard stepIndex < steps.count - 1 else {
            finish()
            return
        }
        Haptics.tap()
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            stepIndex += 1
        }
    }

    private func finish() {
        let parts = Calendar.current.dateComponents([.hour, .minute], from: time)
        draft.dailyTimeMinutes = (parts.hour ?? 7) * 60 + (parts.minute ?? 0)
        draft.name = draft.name.trimmingCharacters(in: .whitespaces)
        Haptics.success()

        let enabled = wantsReminders
        store.updateGuardPreferences { $0.remindersEnabled = enabled }

        withAnimation(.easeInOut(duration: 0.4)) {
            store.saveProfile(draft)
        }

        guard enabled else { return }
        Task {
            await reminders.requestPermission()
            reminders.refresh(
                preferences: store.guardPreferences,
                dailyMinutes: store.profile.dailyTimeMinutes,
                verseLine: nil,
                verseReference: nil,
                name: store.profile.name,
                isArmourOn: store.isArmourComplete,
                streak: store.streak,
                missedYesterday: false
            )
        }
    }

    private func multiSelect<T: Identifiable & CaseIterable>(
        _ options: [T],
        selected: Set<T>,
        toggle: @escaping (T) -> Void
    ) -> some View where T: Hashable, T: OnboardingOption {
        VStack(spacing: RegaliaLayout.rowStack) {
            ForEach(options) { option in
                RegaliaSelectRow(
                    title: option.title,
                    systemImage: option.symbol,
                    isSelected: selected.contains(option)
                ) {
                    toggle(option)
                }
            }
        }
    }

    private func toggle<T: Hashable>(_ value: T, in keyPath: WritableKeyPath<OnboardingProfile, Set<T>>) {
        if draft[keyPath: keyPath].contains(value) {
            draft[keyPath: keyPath].remove(value)
        } else {
            draft[keyPath: keyPath].insert(value)
        }
    }
}

/// Shared shape for the selectable onboarding option enums.
nonisolated protocol OnboardingOption {
    var title: String { get }
    var symbol: String { get }
}

extension SeekingReason: OnboardingOption {}
extension DistractionCause: OnboardingOption {}

/// The two welcome promises (Romans 12:2, 1 Corinthians 10:13) cycling in a
/// gentle vertical ticker — each quote slides up and away as the next rises in.
private struct WelcomeVerseTicker: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var index: Int = 0

    private let quotes: [(text: String, reference: String)] = [
        (
            "Do not conform to the pattern of this world, but be transformed by the renewing of your mind. Then you will be able to test and approve what God\u{2019}s will is\u{2014}his good, pleasing and perfect will.",
            "Romans 12:2"
        ),
        (
            "God is faithful; he will not let you be tempted beyond what you can bear. But when you are tempted, he will also provide a way out.",
            "1 Corinthians 10:13"
        )
    ]

    var body: some View {
        ZStack {
            quoteView
                .id(index)
                .transition(transition)
        }
        .frame(height: 128)
        .animation(.easeInOut(duration: reduceMotion ? 0.6 : 0.9), value: index)
        .task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(7))
                guard !Task.isCancelled else { break }
                index = (index + 1) % quotes.count
            }
        }
    }

    private var transition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .offset(y: 30).combined(with: .opacity),
                removal: .offset(y: -30).combined(with: .opacity)
            )
    }

    private var quoteView: some View {
        let quote = quotes[index]
        return VStack(spacing: 10) {
            Text("\u{201C}\(quote.text)\u{201D}")
                .font(.system(size: 15, weight: .medium).italic())
                .foregroundStyle(RegaliaTheme.bone.opacity(0.92))
                .lineSpacing(3)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text(quote.reference)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .kerning(3)
                .textCase(.uppercase)
                .foregroundStyle(RegaliaTheme.gold)
        }
        .padding(.horizontal, 6)
    }
}

/// The proof screen's rising curve: a gold discipline line that draws itself on
/// across 30 days, glow pooling beneath it, pulsing at the Day-30 peak. Reduced
/// Motion shows the finished graph with no drawing or pulse.
private struct DisciplineCurve: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var progress: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        GeometryReader { proxy in
            let rect = CGRect(origin: .zero, size: proxy.size)
            let start = DisciplineCurveMath.point(x: 0.02, in: rect)
            let end = DisciplineCurveMath.point(x: 1, in: rect)

            ZStack(alignment: .topLeading) {
                DisciplineFill()
                    .fill(
                        LinearGradient(
                            colors: [
                                RegaliaTheme.gold.opacity(0.28),
                                RegaliaTheme.gold.opacity(0.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .opacity(progress)

                Rectangle()
                    .fill(RegaliaTheme.steel.opacity(0.16))
                    .frame(height: 1)
                    .frame(maxHeight: .infinity, alignment: .bottom)

                DisciplineLine()
                    .trim(from: 0, to: progress)
                    .stroke(
                        RegaliaTheme.gold,
                        style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                    )
                    .shadow(color: RegaliaTheme.gold.opacity(0.5), radius: 6)

                // Where most people start — a quiet steel dot on the flat early days.
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(RegaliaTheme.steel)
                    .position(start)
                    .opacity(progress >= 1 ? 1 : 0)

                // The peak — a bright gold point the ring pings out from.
                Circle()
                    .frame(width: 9, height: 9)
                    .foregroundStyle(RegaliaTheme.gold)
                    .shadow(color: RegaliaTheme.gold.opacity(0.8), radius: 5)
                    .position(end)
                    .opacity(progress >= 1 ? 1 : 0)

                Circle()
                    .stroke(RegaliaTheme.gold.opacity(pulse ? 0 : 0.7), lineWidth: 1.5)
                    .frame(width: 10, height: 10)
                    .scaleEffect(pulse ? 2.8 : 1)
                    .position(end)
                    .opacity(progress >= 1 ? 1 : 0)

                HStack {
                    Text("DAY 1")
                    Spacer(minLength: 0)
                    Text("DAY 30")
                }
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .kerning(2)
                .foregroundStyle(RegaliaTheme.steel)
                .frame(maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, 8)
            }
        }
        .frame(height: 218)
        .onAppear {
            guard progress == 0 else { return }
            if reduceMotion {
                progress = 1
            } else {
                withAnimation(.easeInOut(duration: 2.0)) {
                    progress = 1
                }
            }
        }
        .task {
            guard !reduceMotion else { return }
            try? await Task.sleep(for: .seconds(2.15))
            withAnimation(.easeOut(duration: 1.5).repeatForever(autoreverses: false)) {
                pulse = true
            }
        }
    }
}

/// Curve math shared by the line, the fill, and marker placement — a flat,
/// distracted start easing into a strong finish across the first 30 days.
private nonisolated enum DisciplineCurveMath {
    static func discipline(_ x: CGFloat) -> CGFloat {
        let s = x * x * (3 - 2 * x)
        return min(max(0.14 + 0.80 * pow(s, 1.35) + 0.02 * sin(x * 9.2), 0), 1)
    }

    static func point(x: CGFloat, in rect: CGRect) -> CGPoint {
        let top: CGFloat = 16
        let bottom: CGFloat = 38
        let drawable = rect.height - top - bottom
        return CGPoint(x: rect.width * x, y: top + (1 - discipline(x)) * drawable)
    }
}

private struct DisciplineLine: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = Path()
        let samples = 72
        for index in 0...samples {
            let x = CGFloat(index) / CGFloat(samples)
            let point = DisciplineCurveMath.point(x: x, in: rect)
            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        return path
    }
}

/// The same curve closed to the baseline, so the glow pools beneath the line.
private struct DisciplineFill: Shape {
    nonisolated func path(in rect: CGRect) -> Path {
        var path = DisciplineLine().path(in: rect)
        path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        path.addLine(to: CGPoint(x: 0, y: rect.height))
        path.closeSubpath()
        return path
    }
}

nonisolated enum OnboardingStep: Int, CaseIterable, Hashable, Sendable {
    case welcome, battle, armour, stand, name, reasons, mood, causes, apps, time, proof, covenant, paywall, deviceGuard

    var title: String {
        switch self {
        case .welcome: "Put the armour on before the world gets your attention."
        case .battle: "There is a real fight for your morning."
        case .armour: "God already handed you the armour."
        case .stand: "This is what a daily stand looks like."
        case .name: "A little about you."
        case .reasons: "Why are you seeking this?"
        case .mood: "How do you feel most mornings?"
        case .causes: "What pulls your spirit away?"
        case .apps: "Which apps stop you?"
        case .time: "When is your Regalia?"
        case .proof: "The #1 app for Christians renewing their mind."
        case .covenant: "This is what you're agreeing to."
        case .paywall: "Regalia"
        case .deviceGuard: "Do you want the lock to be real?"
        }
    }

    var subtitle: String? {
        switch self {
        case .welcome: "A daily eight-minute stand, rooted in Ephesians 6."
        case .battle: "Scripture names it — and arms you for it."
        case .armour: "Seven pieces. Ephesians 6:13-18."
        case .stand: "Eight minutes. Seven pieces. One verse and one prayer, kept."
        case .name: "This shapes how Regalia greets and prays with you. All of it is optional."
        case .reasons: "Pick everything that's true. The first one shows up on your lock gate."
        case .mood: "This chooses the Scripture you'll be handed each day."
        case .causes: "Naming it is the first act of the belt of truth."
        case .apps: "These stay guarded until today's Regalia is finished."
        case .time: "We'll shape the day's rhythm around it."
        case .proof: "Rooted in Biblical truth. Built for spiritual discipline in a world of distraction."
        case .covenant: nil
        case .paywall: nil
        case .deviceGuard: "Regalia can shut these apps at the iPhone level, not just inside the app."
        }
    }

    var actionTitle: String {
        switch self {
        case .welcome: "Begin"
        case .armour: "Show me the daily stand"
        case .stand: "I'm in"
        case .covenant: "Continue"
        case .deviceGuard: "Put on the armour"
        default: "Continue"
        }
    }

    var isSkippable: Bool { self == .name }

    /// Short screens sit a little lower so they don't float against the progress bar.
    var needsBreathingRoom: Bool {
        switch self {
        case .time: true
        default: false
        }
    }
}

/// A left-aligned wrapping flow used for the About-you chip rows.
nonisolated struct RegaliaFlowLayout: Layout {
    var spacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        let width = proposal.width ?? (x - spacing)
        return CGSize(width: max(0, width), height: max(0, y + rowHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
