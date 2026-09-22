//
//  ContentView.swift
//  Regalia
//

import SwiftUI

/// Root surface: onboarding until the covenant is signed, then the four tabs —
/// with the paywall standing in front of the app for anyone without a subscription.
struct ContentView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ScreenTimeGuard.self) private var screenTime
    @Environment(ReminderScheduler.self) private var reminders
    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var selection: Int = 0
    @State private var showSession = false
    /// Each tab remembers its own collapsed state, so switching tabs never
    /// collapses a screen that is sitting at its top.
    @State private var collapsedTabs: [Int: Bool] = [:]
    /// The turning point of the current scroll direction, per tab: the lowest
    /// offset seen while expanded, or the deepest while collapsed.
    @State private var scrollAnchors: [Int: CGFloat] = [:]
    /// Tabs whose content is being dragged or is gliding from a flick right now.
    @State private var activelyScrollingTabs: Set<Int> = []
    /// The title screen plays only before onboarding begins, on first run.
    @State private var showTitle = true
    /// The welcome-back note asking whether to re-arm the guard after a lapse.
    @State private var showGuardRestore = false

    var body: some View {
        Group {
            if store.isOnboarded {
                if subscriptions.hasAccess {
                    tabs
                        .transition(.opacity.combined(with: .scale(scale: 1.02)))
                } else {
                    PaywallView(context: .gate, name: store.profile.name)
                        .transition(.opacity)
                }
            } else if showTitle {
                TitleScreenView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showTitle = false
                    }
                }
                .transition(.opacity)
            } else {
                OnboardingView()
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .tint(RegaliaTheme.gold)
        .animation(.easeInOut(duration: 0.45), value: store.isOnboarded)
        .animation(.easeInOut(duration: 0.45), value: subscriptions.hasAccess)
        .task {
            await reminders.refreshPermission()
            reconcile()
        }
        .task {
            await subscriptions.start()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            store.refreshForNewDayIfNeeded()
            store.syncPassesFromGuard()
            screenTime.refreshMode()
            reconcile()
            Task { await subscriptions.refreshStatus() }
        }
        .onChange(of: store.isArmourComplete) { _, _ in
            reconcile()
        }
        .onChange(of: subscriptions.hasAccess) { _, hasAccess in
            guard store.isOnboarded else { return }
            if hasAccess {
                // Back after a lapse: ask before re-arming the guard they left behind.
                if screenTime.isLapsePaused {
                    showGuardRestore = true
                }
            } else {
                // Never hold the phone hostage: the moment the subscription is
                // gone, every shield lifts and nothing re-applies it.
                screenTime.pauseForLapse()
            }
            reconcile()
        }
        .onReceive(NotificationCenter.default.publisher(for: ReminderScheduler.openSessionSignal)) { _ in
            openSessionFromNotification()
        }
        .alert("Welcome back", isPresented: $showGuardRestore) {
            Button("Turn the guard back on") {
                screenTime.resumeAfterLapse(restoreGuard: true)
                reconcile()
            }
            Button("Not now", role: .cancel) {
                screenTime.resumeAfterLapse(restoreGuard: false)
                reconcile()
            }
        } message: {
            Text("Your guard has been paused since your subscription ended. Your app list is exactly as you left it.")
        }
    }

    /// The four tab pages stay alive in a stack so their scroll positions and
    /// sheets survive switching; the glass bar floats beneath them.
    private var tabs: some View {
        ZStack {
            tabPage(0) {
                TodayView(onOpenSession: openSession)
            }
            tabPage(1) {
                ArchiveView()
            }
            tabPage(2) {
                GuardView()
            }
            tabPage(3) {
                SettingsView(selection: $selection)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            RegaliaGlassTabBar(
                tabs: barTabs,
                selection: $selection,
                isCollapsed: collapsedTabs[selection] ?? false,
                isActionHidden: selection == 3,
                isArmourComplete: store.isArmourComplete,
                onAction: openSession
            )
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .fullScreenCover(isPresented: $showSession) {
            SessionView()
        }
    }

    private var barTabs: [RegaliaTab] {
        [
            RegaliaTab(id: 0, title: "Today", symbol: "sun.max.fill"),
            RegaliaTab(id: 1, title: "Archive", symbol: "book.fill"),
            RegaliaTab(id: 2, title: "The Guard", symbol: screenTime.isLive ? "lock.shield.fill" : "lock.shield"),
            RegaliaTab(id: 3, title: "Settings", symbol: "gearshape.fill"),
        ]
    }

    @ViewBuilder
    private func tabPage<Content: View>(_ id: Int, @ViewBuilder content: () -> Content) -> some View {
        let isActive = selection == id
        content()
            .regaliaScrollOffsetReporting { offset in
                handleScrollOffset(offset, tab: id)
            } onActive: { isActive in
                if isActive {
                    activelyScrollingTabs.insert(id)
                } else {
                    activelyScrollingTabs.remove(id)
                }
            }
            .opacity(isActive ? 1 : 0)
            .allowsHitTesting(isActive)
            .accessibilityHidden(!isActive)
    }

    /// Collapses the bar after a clear downward scroll past the headline, and
    /// expands again after a deliberate upward scroll or on returning to the top.
    /// Offsets arrive already clamped, so overscroll bounce never reaches here;
    /// direction only counts while the person is actually scrolling, and each
    /// flip needs real travel from the turning point so small wobbles can't toggle it.
    private func handleScrollOffset(_ offset: CGFloat, tab: Int) {
        guard tab == selection else { return }
        let wasCollapsed = collapsedTabs[tab] ?? false
        var anchor = scrollAnchors[tab] ?? offset
        var collapsed = wasCollapsed

        if offset <= 4 {
            collapsed = false
        } else if activelyScrollingTabs.contains(tab) {
            if wasCollapsed {
                anchor = max(anchor, offset)
                if anchor - offset >= 24 { collapsed = false }
            } else {
                anchor = min(anchor, offset)
                if offset > 56, offset - anchor >= 12 { collapsed = true }
            }
        } else {
            // Idle movement (layout changes, content loading) just re-bases.
            anchor = offset
        }

        let nextAnchor = collapsed == wasCollapsed ? anchor : offset
        if scrollAnchors[tab] != nextAnchor {
            scrollAnchors[tab] = nextAnchor
        }

        guard collapsed != wasCollapsed else { return }
        if reduceMotion {
            collapsedTabs[tab] = collapsed
        } else {
            withAnimation(.spring(response: 0.42, dampingFraction: 0.85)) {
                collapsedTabs[tab] = collapsed
            }
        }
    }

    /// The single way into today's session, from Today, the lock gate,
    /// onboarding momentum, or the gold circle in the tab bar.
    private func openSession() {
        store.prepareSessionContent()
        showSession = true
    }

    /// A tapped reminder — body or "Stand now" — lands here. It only opens the
    /// session when the app is in a state that can host one.
    private func openSessionFromNotification() {
        guard store.isOnboarded, subscriptions.hasAccess, !showSession else { return }
        openSession()
    }

    /// Keeps the OS shield and the pending reminders in step with today's state.
    private func reconcile() {
        guard store.isOnboarded else { return }
        store.mirrorGuardState()
        screenTime.reconcile(
            isArmourOn: store.isArmourComplete || store.isTemporarilyUnlocked,
            bedtimeMinutes: store.guardPreferences.bedtimeMinutes
        )
        reminders.refresh(
            preferences: store.guardPreferences,
            dailyMinutes: store.profile.dailyTimeMinutes,
            verseLine: store.today.dailyVerse?.text,
            verseReference: store.today.dailyVerse?.creditedReference,
            name: store.profile.name,
            isArmourOn: store.isArmourComplete,
            streak: store.streak,
            missedYesterday: store.missedYesterday
        )
    }
}

#Preview {
    ContentView()
        .environment(RegaliaStore())
        .environment(ScreenTimeGuard())
        .environment(ReminderScheduler())
        .environment(SubscriptionStore())
}
