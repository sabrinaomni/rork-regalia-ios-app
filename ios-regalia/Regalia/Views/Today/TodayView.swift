import FamilyControls
import SwiftUI

/// The Today tab: mascot greeting, mood check-in, today's Scripture, armour progress.
struct TodayView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ScreenTimeGuard.self) private var screenTime

    /// Opens the session from the root cover, shared with the tab bar's gold circle.
    let onOpenSession: () -> Void

    @State private var lockedTarget: LockTarget?
    @State private var pendingSessionFromLock = false
    @State private var greetingAppeared = false
    /// True while a finger is on the screen or the scroll is settling. The ambient
    /// animations hold still during that window so they can't judder the bounce.
    @State private var isScrolling = false

    var body: some View {
        ZStack {
            RegaliaBackground(paused: isScrolling)

            ScrollView {
                VStack(alignment: .leading, spacing: RegaliaLayout.sectionStack) {
                    header
                    mascotPanel
                    moodSection
                    verseSection
                    armourSection
                    guardedSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, RegaliaLayout.tabbedScrollBottom)
            }
            .scrollIndicators(.hidden)
            .onScrollPhaseChange { _, newPhase in
                let scrolling = newPhase.isScrolling
                guard scrolling != isScrolling else { return }
                isScrolling = scrolling
            }
        }
        .fullScreenCover(item: $lockedTarget, onDismiss: {
            guard pendingSessionFromLock else { return }
            pendingSessionFromLock = false
            onOpenSession()
        }) { target in
            LockGateView(target: target) {
                pendingSessionFromLock = true
                lockedTarget = nil
            } onClose: {
                lockedTarget = nil
            }
        }
        .onAppear {
            store.refreshForNewDayIfNeeded()
            guard !greetingAppeared else { return }
            withAnimation(.easeOut(duration: 0.6)) { greetingAppeared = true }
        }
        .task {
            await launchSessionAfterOnboardingIfNeeded()
        }
    }

    /// Carries the momentum of onboarding straight into the first equipping.
    /// Consumes the flag immediately so the cover can never re-open on dismissal.
    private func launchSessionAfterOnboardingIfNeeded() async {
        guard store.wantsSessionAfterOnboarding else { return }
        store.wantsSessionAfterOnboarding = false
        try? await Task.sleep(for: .milliseconds(520))
        guard lockedTarget == nil else { return }
        onOpenSession()
    }

    /// What the guarded row shows. Once someone has picked real apps in Screen
    /// Time, those are the truth of what's blocked — and only the system can draw
    /// their icons. The curated tiles stand in until then.
    private var lockTargets: [LockTarget] {
        let tokens = screenTime.selection.applicationTokens
        guard tokens.isEmpty else {
            return tokens.map { LockTarget(token: $0) }
        }
        return store.profile.guardedApps.map { LockTarget(app: $0) }
    }

    /// Whether a real, Screen Time-chosen app is shut right now.
    private var isRealAppLocked: Bool {
        !store.isArmourComplete && !store.isTemporarilyUnlocked
    }

    private func isLocked(_ target: LockTarget) -> Bool {
        switch target.source {
        case .screenTime: isRealAppLocked
        case .preview(let app): store.isGuarded(app)
        }
    }

    // MARK: - Sections

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(greeting)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(RegaliaTheme.bone)
                .lineSpacing(2)
                .minimumScaleFactor(0.7)
                .lineLimit(2)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(greetingAppeared ? 1 : 0)
        .offset(y: greetingAppeared ? 0 : 10)
    }

    private var mascotPanel: some View {
        MascotView(
            stage: MascotStage.stage(forEquippedCount: store.today.equippedCount),
            paused: isScrolling
        )
            .mascotStage(height: RegaliaLayout.heroArt)
            .animation(.spring(response: 0.6, dampingFraction: 0.7), value: store.today.equippedCount)
    }

    private var moodSection: some View {
        VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
            Text(store.today.mood == nil ? "How are you feeling this morning?" : (store.today.mood?.response ?? ""))
                .font(.subheadline)
                .foregroundStyle(RegaliaTheme.steelBright)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentTransition(.opacity)
                .animation(.easeInOut(duration: 0.3), value: store.today.mood)

            ScrollView(.horizontal) {
                HStack(spacing: RegaliaLayout.rowStack) {
                    ForEach(Mood.allCases) { mood in
                        RegaliaChip(
                            title: mood.label,
                            systemImage: mood.symbol,
                            isSelected: store.today.mood == mood
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                store.setMood(mood)
                            }
                        }
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
            .contentMargins(.horizontal, 0, for: .scrollContent)
        }
    }

    @ViewBuilder
    private var verseSection: some View {
        if let verse = store.today.moodVerse {
            VerseCard(verse: verse)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var armourSection: some View {
        VStack(alignment: .leading, spacing: RegaliaLayout.cardStack + 2) {
            HStack {
                Label {
                    Text("Armour of God")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(RegaliaTheme.bone)
                } icon: {
                    Image(systemName: "shield.lefthalf.filled")
                        .foregroundStyle(RegaliaTheme.gold)
                }

                Spacer()

                Text("\(store.today.equippedCount) of 7 equipped")
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(RegaliaTheme.gold.opacity(0.9))
            }

            ArmourTrack(
                equipped: store.today.equippedPieces,
                shimmerTrigger: store.today.equippedPieces.count
            )

            Divider().overlay(RegaliaTheme.hairline)

            HStack(spacing: 8) {
                Image(systemName: store.isArmourComplete ? "checkmark.seal.fill" : "clock")
                    .font(.footnote)
                    .foregroundStyle(store.isArmourComplete ? RegaliaTheme.gold : RegaliaTheme.steel)
                Text(store.isArmourComplete
                     ? "Armour complete · apps released for today"
                     : "Session · \(RegaliaStore.sessionMinutes) min")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steel)
                Spacer()
            }
        }
        .padding(18)
        .regaliaCard()
    }

    @ViewBuilder
    private var guardedSection: some View {
        let targets = lockTargets
        if !targets.isEmpty {
            VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
                HStack {
                    Text("Guarded until you're armoured")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer()
                    Image(systemName: store.isArmourComplete ? "lock.open.fill" : "lock.fill")
                        .font(.footnote)
                        .foregroundStyle(store.isArmourComplete ? RegaliaTheme.gold : RegaliaTheme.crimson)
                }

                guardStateRow

                ScrollView(.horizontal) {
                    HStack(spacing: 12) {
                        ForEach(targets) { target in
                            Button {
                                Haptics.tap()
                                guard isLocked(target) else { return }
                                Haptics.warn()
                                lockedTarget = target
                            } label: {
                                GuardedAppTile(target: target, isLocked: isLocked(target))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollIndicators(.hidden)

                Text(store.isArmourComplete
                     ? "You finished today's Regalia. These are yours again."
                     : "Tap one to see what stands in the way.")
                    .font(.caption)
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .fixedSize(horizontal: false, vertical: true)

                if screenTime.isLive {
                    Text("\(screenTime.selectionCount) item\(screenTime.selectionCount == 1 ? "" : "s") are also shut at the iPhone level.")
                        .font(.caption)
                        .foregroundStyle(RegaliaTheme.gold.opacity(0.85))
                }
            }
            .padding(18)
            .regaliaCard()
        }
    }

    /// Live state line: on a pass with a countdown, released for today, or locked.
    @ViewBuilder
    private var guardStateRow: some View {
        HStack(spacing: 8) {
            if store.isTemporarilyUnlocked, let until = store.activeUnlockUntil {
                Image(systemName: "hourglass")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.gold)
                Text("On a pass ·")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steel)
                Text(timerInterval: Date()...until, countsDown: true)
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(RegaliaTheme.gold)
            } else if store.isArmourComplete {
                Image(systemName: "checkmark.seal.fill")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.gold)
                Text("Released for today")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steel)
            } else {
                Image(systemName: screenTime.isLive ? "lock.shield.fill" : "eye.fill")
                    .font(.footnote)
                    .foregroundStyle(screenTime.isLive ? RegaliaTheme.crimson : RegaliaTheme.steel)
                Text(screenTime.isLive ? "Locked on this iPhone" : "Guarded inside Regalia")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steel)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: - Copy

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let part = switch hour {
        case 4..<12: "Good morning"
        case 12..<17: "Good afternoon"
        default: "Good evening"
        }
        let name = store.profile.name.trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? part : "\(part), \(name)"
    }

    private var subtitle: String {
        let day = "Day \(store.dayNumber)"
        if store.isArmourComplete {
            return "\(day) · Full armour equipped"
        }
        if let last = store.today.equippedPieces.last {
            return "\(day) · \(last.title) equipped"
        }
        return "\(day) · The armour is waiting"
    }
}

/// A guarded app shown as a locked or released tile.
///
/// A real Screen Time app draws its own icon and name through `Label(token)` —
/// that artwork belongs to the app it came from and can't be bundled here, so the
/// system renders it. Regalia's curated tiles fall back to an SF Symbol.
private struct GuardedAppTile: View {
    let target: LockTarget
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(target.tint.opacity(isLocked ? 0.16 : 0.24))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(target.tint.opacity(isLocked ? 0.4 : 0.7), lineWidth: 1)
                    )

                mark

                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(RegaliaTheme.bone)
                        .padding(4)
                        .background(Circle().fill(RegaliaTheme.crimson))
                        .offset(x: 22, y: -22)
                }
            }
            .saturation(isLocked ? 0.5 : 1)

            name
        }
        .frame(width: 68)
    }

    @ViewBuilder
    private var mark: some View {
        switch target.source {
        case .screenTime(let token):
            Label(token)
                .labelStyle(.iconOnly)
                .scaleEffect(1.5)
                .clipShape(.rect(cornerRadius: 12, style: .continuous))
                .opacity(isLocked ? 0.75 : 1)
        case .preview(let app):
            Image(systemName: app.symbol)
                .font(.system(size: 22, weight: .medium))
                .foregroundStyle(app.tint.opacity(isLocked ? 0.55 : 1))
        }
    }

    @ViewBuilder
    private var name: some View {
        switch target.source {
        case .screenTime(let token):
            Label(token)
                .labelStyle(.titleOnly)
                .font(.caption2)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineLimit(1)
        case .preview(let app):
            Text(app.name)
                .font(.caption2)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineLimit(1)
        }
    }
}
