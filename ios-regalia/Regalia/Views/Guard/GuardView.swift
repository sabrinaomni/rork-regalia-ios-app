import SwiftUI

/// The Guard tab: Screen Time status, the blocked-apps picker, the nightly
/// re-lock, unlock passes, and the in-app preview tiles.
struct GuardView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ScreenTimeGuard.self) private var screenTime
    @Environment(ReminderScheduler.self) private var reminders

    @State private var bedtime: Date = Date()
    @State private var showApps = false
    @State private var previewApp: GuardedApp?

    var body: some View {
        ZStack {
            RegaliaBackground(bloomStrength: 0.12)

            ScrollView {
                VStack(alignment: .leading, spacing: RegaliaLayout.sectionStack) {
                    Text("The Guard")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(RegaliaTheme.bone)

                    guardCard
                    previewCard
                }
                .padding(.horizontal, 20)
                .padding(.bottom, RegaliaLayout.tabbedScrollBottom)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(isPresented: $showApps) {
            GuardedAppsEditor()
        }
        .fullScreenCover(item: $previewApp) { app in
            LockGateView(app: app) { previewApp = nil }
        }
        .onAppear {
            bedtime = store.guardPreferences.bedtimeDate
            screenTime.refreshMode()
        }
    }

    // MARK: - Cards

    private var guardCard: some View {
        SettingsCard(title: "The guard") {
            VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
                GuardSetupPanel()

                Divider().overlay(RegaliaTheme.hairline)

                DatePicker(
                    "Re-lock at night",
                    selection: $bedtime,
                    displayedComponents: .hourAndMinute
                )
                .datePickerStyle(.compact)
                .tint(RegaliaTheme.gold)
                .foregroundStyle(RegaliaTheme.bone)
                .onChange(of: bedtime) { _, newValue in
                    let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    let minutes = (parts.hour ?? 22) * 60 + (parts.minute ?? 0)
                    store.updateGuardPreferences { $0.bedtimeMinutes = minutes }
                    screenTime.scheduleBedtimeRelock(bedtimeMinutes: minutes)
                }

                Text("Finishing the session releases everything for the rest of the day. The guard closes again at this hour.")
                    .font(.caption)
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .fixedSize(horizontal: false, vertical: true)

                Divider().overlay(RegaliaTheme.hairline)

                HStack {
                    Text("Unlock passes left")
                        .foregroundStyle(RegaliaTheme.bone)
                    Spacer()
                    Text("\(store.unlocksLeftThisWeek) of \(RegaliaStore.weeklyUnlockAllowance)")
                        .monospacedDigit()
                        .foregroundStyle(store.unlocksLeftThisWeek > 0 ? RegaliaTheme.gold : RegaliaTheme.crimson)
                }
            }
            .font(.system(size: 16))
        }
    }

    private var previewCard: some View {
        SettingsCard(title: "In-app preview") {
            VStack(alignment: .leading, spacing: RegaliaLayout.cardStack) {
                if store.profile.guardedApps.isEmpty {
                    Text("Nothing is guarded yet.")
                        .font(.footnote)
                        .foregroundStyle(RegaliaTheme.steelBright)
                } else {
                    ScrollView(.horizontal) {
                        HStack(spacing: RegaliaLayout.rowStack) {
                            ForEach(store.profile.guardedApps) { app in
                                Label(app.name, systemImage: app.symbol)
                                    .font(.caption)
                                    .foregroundStyle(app.tint)
                                    .padding(.vertical, 7)
                                    .padding(.horizontal, 12)
                                    .background(Capsule().fill(app.tint.opacity(0.14)))
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                Button {
                    Haptics.tap()
                    showApps = true
                } label: {
                    guardRow("Edit the demo tiles", value: "\(store.profile.guardedApps.count)")
                }
                .buttonStyle(.plain)

                if let first = store.profile.guardedApps.first {
                    Divider().overlay(RegaliaTheme.hairline)
                    Button {
                        Haptics.tap()
                        previewApp = first
                    } label: {
                        guardRow("Preview the lock gate", value: "")
                    }
                    .buttonStyle(.plain)
                }

                Text("These tiles let you walk the whole flow on any device, including the simulator, while the real Screen Time block waits on Apple's approval.")
                    .font(.caption)
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(size: 16))
        }
    }

    private func guardRow(_ title: String, value: String, truncate: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(RegaliaTheme.bone)
            Spacer(minLength: 8)
            Text(value)
                .foregroundStyle(RegaliaTheme.steelBright)
                .lineLimit(truncate ? 1 : nil)
                .truncationMode(.tail)
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RegaliaTheme.steel.opacity(0.7))
        }
        .contentShape(.rect)
    }
}

/// Sheet for editing which apps Regalia guards in the preview flow.
private struct GuardedAppsEditor: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                RegaliaBackground(bloomStrength: 0.1)

                ScrollView {
                    VStack(spacing: RegaliaLayout.rowStack) {
                        ForEach(GuardedApp.catalog) { app in
                            RegaliaSelectRow(
                                title: app.name,
                                systemImage: app.symbol,
                                tint: app.tint,
                                isSelected: store.profile.guardedAppIDs.contains(app.id)
                            ) {
                                store.updateProfile { profile in
                                    if profile.guardedAppIDs.contains(app.id) {
                                        profile.guardedAppIDs.remove(app.id)
                                    } else {
                                        profile.guardedAppIDs.insert(app.id)
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("Guarded apps")
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
