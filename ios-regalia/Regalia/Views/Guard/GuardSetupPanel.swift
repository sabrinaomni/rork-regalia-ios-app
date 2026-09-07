import FamilyControls
import SwiftUI

/// The Screen Time control surface, shared by the last onboarding step and Settings.
struct GuardSetupPanel: View {
    @Environment(ScreenTimeGuard.self) private var screenTime

    /// Settings shows the explanatory footnote; onboarding shows its own copy.
    var showsFootnote: Bool = true

    @State private var showPicker = false
    @State private var isRequesting = false

    var body: some View {
        @Bindable var screenTime = screenTime

        VStack(alignment: .leading, spacing: 14) {
            statusRow

            if screenTime.isAuthorized {
                Button {
                    Haptics.tap()
                    showPicker = true
                } label: {
                    actionRow(
                        title: screenTime.selectionCount == 0 ? "Choose apps to block" : "Edit what's blocked",
                        value: screenTime.selectionCount == 0 ? "" : "\(screenTime.selectionCount)",
                        systemImage: "square.grid.2x2.fill"
                    )
                }
                .buttonStyle(.plain)
            } else {
                Button {
                    Haptics.tap()
                    isRequesting = true
                    Task {
                        let granted = await screenTime.requestAuthorization()
                        isRequesting = false
                        if granted {
                            Haptics.success()
                            showPicker = true
                        } else {
                            Haptics.warn()
                        }
                    }
                } label: {
                    actionRow(
                        title: isRequesting ? "Asking iOS…" : "Turn on real blocking",
                        value: "",
                        systemImage: "lock.iphone"
                    )
                }
                .buttonStyle(.plain)
                .disabled(isRequesting)
            }

            if showsFootnote {
                Text("Real blocking uses Apple's Screen Time. Apple has to approve app blocking for your developer account before it works on a physical iPhone — until then Regalia guards inside the app.")
                    .font(.caption)
                    .foregroundStyle(RegaliaTheme.steel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .familyActivityPicker(isPresented: $showPicker, selection: $screenTime.selection)
        .onChange(of: showPicker) { _, isShowing in
            guard !isShowing else { return }
            screenTime.refreshMode()
        }
    }

    private var statusRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: statusSymbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(statusColor)
                .frame(width: 32, height: 32)
                .background { Circle().fill(statusColor.opacity(0.14)) }

            VStack(alignment: .leading, spacing: 3) {
                Text(screenTime.statusTitle)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(RegaliaTheme.bone)
                Text(screenTime.statusDetail)
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steel)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }

    private func actionRow(title: String, value: String, systemImage: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(RegaliaTheme.gold)
            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(RegaliaTheme.bone)
            Spacer(minLength: 8)
            if !value.isEmpty {
                Text(value)
                    .monospacedDigit()
                    .font(.system(size: 16))
                    .foregroundStyle(RegaliaTheme.steel)
            }
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RegaliaTheme.steel.opacity(0.7))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .contentShape(.rect)
        .regaliaCard(cornerRadius: 16, highlighted: screenTime.isLive)
    }

    private var statusSymbol: String {
        switch screenTime.mode {
        case .live: "lock.shield.fill"
        case .idle: "shield.lefthalf.filled"
        case .denied: "exclamationmark.shield.fill"
        case .preview: "eye.fill"
        }
    }

    private var statusColor: Color {
        switch screenTime.mode {
        case .live: RegaliaTheme.gold
        case .idle: RegaliaTheme.steel
        case .denied: RegaliaTheme.crimson
        case .preview: RegaliaTheme.steel
        }
    }
}
