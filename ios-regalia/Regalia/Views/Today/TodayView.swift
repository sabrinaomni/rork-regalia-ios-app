import SwiftUI

/// The Today tab: mascot greeting, mood check-in, today's Scripture, armour progress.
struct TodayView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ScreenTimeGuard.self) private var screenTime

    /// Opens the session from the root cover, shared with the tab bar's gold circle.
    let onOpenSession: () -> Void

    @State private var lockedApp: GuardedApp?
    @State private var pendingSessionFromLock = false
    @State private var greetingAppeared = false

    var body: some View {
        ZStack {
            RegaliaBackground()

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
        }
        .fullScreenCover(item: $lockedApp, onDismiss: {
            guard pendingSessionFromLock else { return }
            pendingSessionFromLock = false
            onOpenSession()
        }) { app in
            LockGateView(app: app) {
                pendingSessionFromLock = true
                lockedApp = nil
            }
        }
        .onAppear {
            store.refreshForNewDayIfNeeded()
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
        guard lockedApp == nil else { return }
        onOpenSession()
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
        MascotView(stage: MascotStage.stage(forEquippedCount: store.today.equippedCount))
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
        let apps = store.profile.guardedApps
        if !apps.isEmpty {
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
                        ForEach(apps) { app in
                            Button {
                                Haptics.tap()
                                if store.isGuarded(app) {
                                    Haptics.warn()
                                    lockedApp = app
                                }
                            } label: {
                                GuardedAppTile(app: app, isLocked: store.isGuarded(app))
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
private struct GuardedAppTile: View {
    let app: GuardedApp
    let isLocked: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(app.tint.opacity(isLocked ? 0.16 : 0.24))
                    .frame(width: 56, height: 56)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(app.tint.opacity(isLocked ? 0.4 : 0.7), lineWidth: 1)
                    )

                Image(systemName: app.symbol)
                    .font(.system(size: 22, weight: .medium))
                    .foregroundStyle(app.tint.opacity(isLocked ? 0.55 : 1))

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

            Text(app.name)
                .font(.caption2)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineLimit(1)
        }
        .frame(width: 68)
    }
}
