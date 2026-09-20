import FamilyControls
import SwiftUI

/// The gate shown when a guarded app is opened before the armour is on.
struct LockGateView: View {
    @Environment(RegaliaStore.self) private var store
    @Environment(ScreenTimeGuard.self) private var screenTime
    @Environment(ReminderScheduler.self) private var reminders

    let target: LockTarget
    let onBeginSession: () -> Void
    /// Closing is handed back to whoever presented the cover.
    ///
    /// `@Environment(\.dismiss)` is unreliable here: this view is presented as a
    /// `fullScreenCover(item:)` from two different screens, and clearing the item
    /// binding at the source is the only dismissal that holds on device.
    let onClose: () -> Void

    @State private var appeared = false

    var body: some View {
        ZStack {
            RegaliaBackground(tint: RegaliaTheme.crimson, bloomStrength: 0.20)

            ScrollView {
                VStack(spacing: RegaliaLayout.artToCopy) {
                    mascotGate
                        .padding(.top, 8)

                    VStack(spacing: 8) {
                        Text(target.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(RegaliaTheme.bone)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.7)
                            .lineLimit(2)

                        // Only the system can name a real app, so its own label
                        // carries the name here.
                        if let token = target.token {
                            Label(token)
                                .labelStyle(.titleOnly)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(RegaliaTheme.gold)
                        }
                    }

                    if let verse = store.today.temptationVerse ?? ScriptureLibrary.temptation.first {
                        VerseCard(verse: verse)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("You said you're here to")
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steelBright)
                        Text(store.profile.primaryReason)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(RegaliaTheme.bone)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .regaliaCard()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, RegaliaLayout.scrollBottom + 16)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 16)
            }
            .scrollIndicators(.hidden)

            VStack {
                HStack {
                    Button {
                        Haptics.tap()
                        onClose()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(RegaliaTheme.bone.opacity(0.9))
                            .frame(width: 36, height: 36)
                            .regaliaGlass(in: Circle())
                            // The glass circle stays 36pt, but the tap target
                            // reaches Apple's 44pt minimum.
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Back")
                    Spacer()
                }
                .padding(.horizontal, 20)
                Spacer()
            }
        }
        .safeAreaInset(edge: .bottom) {
            actions
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) { appeared = true }
        }
    }

    private var mascotGate: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 44, style: .continuous)
                .fill(target.tint.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 44, style: .continuous)
                        .stroke(target.tint.opacity(0.35), lineWidth: 1)
                )
                .frame(width: 200, height: 240)
                .overlay {
                    plateMark
                        .allowsHitTesting(false)
                }
                .blur(radius: 1.5)

            MascotView(
                stage: MascotStage.stage(forEquippedCount: store.today.equippedCount),
                glow: RegaliaTheme.crimson,
                showEmbers: false,
                intensity: 0.9
            )
            .mascotStage(height: RegaliaLayout.lockArt)
        }
        .frame(height: RegaliaLayout.lockArt)
    }

    /// The real app's own icon when Screen Time can draw it, the curated symbol otherwise.
    @ViewBuilder
    private var plateMark: some View {
        if let token = target.token {
            Label(token)
                .labelStyle(.iconOnly)
                .scaleEffect(2.6)
                .opacity(0.5)
        } else {
            Image(systemName: target.symbol)
                .font(.system(size: 96, weight: .medium))
                .foregroundStyle(target.tint.opacity(0.35))
        }
    }

    private var actions: some View {
        VStack(spacing: 12) {
            RegaliaPrimaryButton(
                title: "Put on the armour · \(RegaliaStore.sessionMinutes) min",
                systemImage: "shield.fill"
            ) {
                onBeginSession()
            }

            Button {
                Haptics.warn()
                guard store.spendUnlockPass() else { return }
                screenTime.releaseForPass()
                reminders.schedulePassEndNote(in: GuardBridge.passMinutes)
                onClose()
            } label: {
                Text(unlockLabel)
                    .font(.footnote)
                    .foregroundStyle(store.unlocksLeftThisWeek > 0 ? RegaliaTheme.steel : RegaliaTheme.steel.opacity(0.5))
            }
            .buttonStyle(.plain)
            .disabled(store.unlocksLeftThisWeek == 0)
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

    private var unlockLabel: String {
        let left = store.unlocksLeftThisWeek
        guard left > 0 else { return "No unlock passes left this week" }
        return "Unlock for 5 minutes (\(left) left this week)"
    }
}
