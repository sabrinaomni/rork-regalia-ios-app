import SwiftUI

/// Settings tab: name, daily time, reminders, and account maintenance.
/// The blocking controls live on their own Guard tab; a link row jumps there.
struct SettingsView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ScreenTimeGuard.self) private var screenTime
    @Environment(ReminderScheduler.self) private var reminders
    @Environment(SubscriptionStore.self) private var subscriptions

    /// Binding to the root tab selection, so the Guard link row can switch tabs.
    @Binding var selection: Int

    @State private var name: String = ""
    @State private var dailyTime: Date = Date()
    @State private var showReasons = false
    @State private var showReset = false
    @State private var showPaywall = false
    @State private var showManageSubscription = false

    var body: some View {
        ZStack {
            RegaliaBackground(bloomStrength: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Settings")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(RegaliaTheme.bone)

                    walkCard
                    subscriptionCard
                    rhythmCard
                    guardLinkRow
                    remindersCard
                    aboutCard
                    dangerCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 110)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showReasons) {
            ReasonsEditor()
        }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallView(context: .settings, name: store.profile.name)
        }
        .sheet(isPresented: $showManageSubscription, onDismiss: {
            // A cancellation or plan change made in there should show here at once.
            Task { await subscriptions.refreshStatus() }
        }) {
            ManageSubscriptionView()
        }
        .alert("Start over?", isPresented: $showReset) {
            Button("Erase everything", role: .destructive) {
                screenTime.forget()
                reminders.cancelAll()
                store.eraseEverything()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This clears your profile, streak, and the whole archive from this device.")
        }
        .onAppear {
            name = store.profile.name
            dailyTime = store.profile.dailyTime
            screenTime.refreshMode()
        }
        .task {
            await reminders.refreshPermission()
        }
    }

    // MARK: - Cards

    private var walkCard: some View {
        SettingsCard(title: "Your walk") {
            VStack(spacing: 14) {
                HStack {
                    Text("Name")
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer()
                    TextField("Your name", text: $name)
                        .multilineTextAlignment(.trailing)
                        .foregroundStyle(RegaliaTheme.gold)
                        .tint(RegaliaTheme.gold)
                        .textInputAutocapitalization(.words)
                        .onSubmit { commitName() }
                        .onChange(of: name) { _, _ in commitName() }
                }

                Divider().overlay(RegaliaTheme.hairline)

                HStack {
                    Text("Day")
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer()
                    Text("\(store.dayNumber)")
                        .monospacedDigit()
                        .foregroundStyle(RegaliaTheme.gold)
                }

                Divider().overlay(RegaliaTheme.hairline)

                HStack {
                    Text("Streak")
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer()
                    Text("\(store.streak) day\(store.streak == 1 ? "" : "s")")
                        .monospacedDigit()
                        .foregroundStyle(RegaliaTheme.gold)
                }

                if let aboutYou = store.profile.aboutYouLine {
                    Divider().overlay(RegaliaTheme.hairline)

                    HStack(alignment: .firstTextBaseline) {
                        Text("About you")
                            .foregroundStyle(RegaliaTheme.bone)
                        Spacer(minLength: 10)
                        Text(aboutYou)
                            .foregroundStyle(RegaliaTheme.gold)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Divider().overlay(RegaliaTheme.hairline)

                Button {
                    Haptics.tap()
                    showReasons = true
                } label: {
                    settingsRow("Why you're here", value: store.profile.primaryReason, truncate: true)
                }
                .buttonStyle(.plain)
            }
            .font(.system(size: 16))
        }
    }

    /// Subscription state, and a way back to the plans for anyone not subscribed.
    private var subscriptionCard: some View {
        SettingsCard(title: "Subscription") {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(subscriptions.isSubscribed ? "Plan" : "Status")
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer(minLength: 10)
                    Text(subscriptions.statusLine)
                        .foregroundStyle(subscriptions.isSubscribed ? RegaliaTheme.gold : RegaliaTheme.steel)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if subscriptions.isSubscribed {
                    Divider().overlay(RegaliaTheme.hairline)

                    Button {
                        Haptics.tap()
                        showManageSubscription = true
                    } label: {
                        HStack(spacing: 10) {
                            Text("Manage subscription")
                                .foregroundStyle(RegaliaTheme.gold)
                            Spacer(minLength: 8)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(RegaliaTheme.gold.opacity(0.7))
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)

                    Text("Change your plan, cancel, request a refund, or reach us for help.")
                        .font(.footnote)
                        .foregroundStyle(RegaliaTheme.steel)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Divider().overlay(RegaliaTheme.hairline)

                    Button {
                        Haptics.tap()
                        showPaywall = true
                    } label: {
                        settingsRow("See the plans", value: "Monthly · Yearly")
                    }
                    .buttonStyle(.plain)

                    Button {
                        Haptics.tap()
                        Task { await subscriptions.restore() }
                    } label: {
                        HStack(spacing: 8) {
                            if subscriptions.isRestoring {
                                ProgressView()
                                    .controlSize(.small)
                                    .tint(RegaliaTheme.gold)
                            }
                            Text("Restore purchases")
                                .foregroundStyle(RegaliaTheme.gold)
                            Spacer(minLength: 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .disabled(subscriptions.isRestoring)
                }
            }
            .font(.system(size: 16))
        }
    }

    private var rhythmCard: some View {
        SettingsCard(title: "Daily rhythm") {
            VStack(spacing: 14) {
                DatePicker(
                    "Regalia time",
                    selection: $dailyTime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .tint(RegaliaTheme.gold)
                .foregroundStyle(RegaliaTheme.bone)
                .onChange(of: dailyTime) { _, newValue in
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    store.updateProfile { profile in
                        profile.dailyTimeMinutes = (parts.hour ?? 7) * 60 + (parts.minute ?? 0)
                    }
                    refreshReminders()
                }

                Divider().overlay(RegaliaTheme.hairline)

                HStack {
                    Text("Session length")
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer()
                    Text("\(RegaliaStore.sessionMinutes) min · 9 steps")
                        .foregroundStyle(RegaliaTheme.steel)
                }

            }
            .font(.system(size: 16))
        }
    }

    /// One-tap jump to the Guard tab, with a live summary of what's blocked.
    private var guardLinkRow: some View {
        SettingsCard(title: "The guard") {
            Button {
                Haptics.tap()
                selection = 2
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: screenTime.isLive ? "lock.shield.fill" : "lock.shield")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(screenTime.isLive ? RegaliaTheme.gold : RegaliaTheme.steel)
                        .frame(width: 32, height: 32)
                        .background { Circle().fill((screenTime.isLive ? RegaliaTheme.gold : RegaliaTheme.steel).opacity(0.14)) }

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Blocked apps & passes")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(RegaliaTheme.bone)
                        Text(guardSummary)
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steel)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(RegaliaTheme.steel.opacity(0.7))
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the Guard tab")
        }
    }

    private var guardSummary: String {
        let count = screenTime.selectionCount
        let relock = store.guardPreferences.bedtimeDate.formatted(date: .omitted, time: .shortened)
        if count == 0 { return "Nothing blocked yet — choose your apps" }
        let passes = "\(store.unlocksLeftThisWeek) pass\(store.unlocksLeftThisWeek == 1 ? "" : "es") left"
        return "\(count) blocked · re-locks at \(relock) · \(passes)"
    }

    private var remindersCard: some View {
        SettingsCard(title: "Reminders") {
            VStack(alignment: .leading, spacing: 14) {
                Toggle("Send me reminders", isOn: reminderBinding(\.remindersEnabled))
                    .tint(RegaliaTheme.gold)
                    .foregroundStyle(RegaliaTheme.bone)

                if store.guardPreferences.remindersEnabled {
                    Divider().overlay(RegaliaTheme.hairline)

                    HStack {
                        Text("Daily verse nudge")
                            .foregroundStyle(RegaliaTheme.bone)
                        Spacer()
                        Text(store.profile.dailyTime.formatted(date: .omitted, time: .shortened))
                            .foregroundStyle(RegaliaTheme.gold)
                    }

                    Divider().overlay(RegaliaTheme.hairline)

                    Toggle("Evening nudge if the armour isn't on", isOn: reminderBinding(\.eveningNudge))
                        .tint(RegaliaTheme.gold)
                        .foregroundStyle(RegaliaTheme.bone)

                    Toggle("Warn me when a streak is at risk", isOn: reminderBinding(\.streakWarning))
                        .tint(RegaliaTheme.gold)
                        .foregroundStyle(RegaliaTheme.bone)

                    Toggle("Tell me when an unlock pass ends", isOn: reminderBinding(\.passExpiryNote))
                        .tint(RegaliaTheme.gold)
                        .foregroundStyle(RegaliaTheme.bone)
                }

                if reminders.permission == .denied {
                    Text("Notifications are off for Regalia in iOS Settings, so nothing can be delivered.")
                        .font(.caption)
                        .foregroundStyle(RegaliaTheme.crimson.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .font(.system(size: 16))
        }
    }

    /// Toggle binding that persists the preference and rebuilds the pending reminders.
    private func reminderBinding(_ keyPath: WritableKeyPath<GuardPreferences, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.guardPreferences[keyPath: keyPath] },
            set: { newValue in
                store.updateGuardPreferences { $0[keyPath: keyPath] = newValue }
                Task {
                    if newValue, reminders.permission != .granted {
                        await reminders.requestPermission()
                    }
                    refreshReminders()
                }
            }
        )
    }

    private func refreshReminders() {
        reminders.refresh(
            preferences: store.guardPreferences,
            dailyMinutes: store.profile.dailyTimeMinutes,
            verseLine: store.today.dailyVerse?.text,
            verseReference: store.today.dailyVerse?.reference,
            name: store.profile.name,
            isArmourOn: store.isArmourComplete,
            streak: store.streak,
            missedYesterday: store.missedYesterday
        )
    }

    private var aboutCard: some View {
        SettingsCard(title: "The armour") {
            VStack(alignment: .leading, spacing: 10) {
                Text("Every session walks Ephesians 6:10-18 in full, renews the mind with Romans 12:2, and stands against temptation with 1 Corinthians 10:13.")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steel)
                    .fixedSize(horizontal: false, vertical: true)

                ArmourTrack(equipped: ArmourPiece.allCases)
                    .padding(.top, 4)
            }
        }
    }

    private var dangerCard: some View {
        VStack(spacing: 12) {
            Button {
                Haptics.tap()
                store.resetToday()
            } label: {
                Text("Reset today's session")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RegaliaTheme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .regaliaCard(cornerRadius: 18)
            }
            .buttonStyle(.plain)

            Button {
                Haptics.warn()
                showReset = true
            } label: {
                Text("Erase everything")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RegaliaTheme.crimson)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .regaliaCard(cornerRadius: 18)
            }
            .buttonStyle(.plain)
        }
    }

    private func settingsRow(_ title: String, value: String, truncate: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(RegaliaTheme.bone)
            Spacer(minLength: 8)
            Text(value)
                .foregroundStyle(RegaliaTheme.steel)
                .lineLimit(truncate ? 1 : nil)
                .truncationMode(.tail)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RegaliaTheme.steel.opacity(0.7))
        }
        .contentShape(.rect)
    }

    private func commitName() {
        store.updateProfile { $0.name = name }
    }
}

/// A titled settings panel, shared by Settings and the Guard tab.
struct SettingsCard<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .kerning(1.4)
                .foregroundStyle(RegaliaTheme.gold.opacity(0.8))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .regaliaCard()
    }
}

/// Sheet for editing why the user is here.
private struct ReasonsEditor: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RegaliaBackground(bloomStrength: 0.1)

                ScrollView {
                    VStack(spacing: 10) {
                        Text("The first one you choose is what the lock gate reminds you of.")
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steel)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.bottom, 4)

                        ForEach(SeekingReason.allCases) { reason in
                            RegaliaSelectRow(
                                title: reason.title,
                                systemImage: reason.symbol,
                                isSelected: store.profile.reasons.contains(reason)
                            ) {
                                store.updateProfile { profile in
                                    if profile.reasons.contains(reason) {
                                        profile.reasons.remove(reason)
                                    } else {
                                        profile.reasons.insert(reason)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Why you're here")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }.tint(RegaliaTheme.gold)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
