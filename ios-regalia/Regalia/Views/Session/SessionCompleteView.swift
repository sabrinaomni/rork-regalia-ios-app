import SwiftUI

/// The closing moment of the session: full armour, streak, and released apps.
struct SessionCompleteView: View {
    @Environment(RegaliaStore.self) private var store

    let onDone: () -> Void

    @State private var appeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)

            MascotView(stage: .radiant, intensity: 1.3)
                .mascotStage(height: RegaliaLayout.celebrationArt)
                .scaleEffect(appeared ? 1 : 0.86)
                .opacity(appeared ? 1 : 0)

            VStack(spacing: RegaliaLayout.rowStack) {
                Text("Full armour equipped")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(RegaliaTheme.bone)
                    .multilineTextAlignment(.center)

                Text("“Well done, good and faithful servant.”")
                    .font(.system(size: 17, design: .serif))
                    .italic()
                    .foregroundStyle(RegaliaTheme.gold.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 28)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 14)

            HStack(spacing: RegaliaLayout.cardStack - 2) {
                StatTile(value: "\(store.streak)", label: "Day streak")
                StatTile(value: "7", label: "Pieces on")
                StatTile(value: "\(store.profile.guardedApps.count)", label: "Apps released")
            }
            .padding(.horizontal, 20)
            .padding(.top, 22)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)

            Spacer(minLength: 12)

            RegaliaPrimaryButton(title: "Go live it out", systemImage: "sun.max.fill", showsChevron: false) {
                onDone()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 18)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) { appeared = true }
        }
    }
}

/// A compact gold statistic tile.
struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(RegaliaTheme.gold)
            Text(label)
                .font(.caption)
                .foregroundStyle(RegaliaTheme.steelBright)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .regaliaCard(cornerRadius: 18)
    }
}
