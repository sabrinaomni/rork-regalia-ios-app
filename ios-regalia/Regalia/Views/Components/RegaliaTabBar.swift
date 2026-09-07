import SwiftUI

// MARK: - Model

/// One destination in the floating glass tab bar.
struct RegaliaTab: Identifiable {
    let id: Int
    let title: String
    let symbol: String
}

// MARK: - Scroll reporting

extension View {
    /// Reports how far a scroll view has travelled beneath its top edge (≥ 0),
    /// so the glass tab bar can collapse while reading and expand again on the way back up.
    func regaliaScrollOffsetReporting(_ action: @escaping (CGFloat) -> Void) -> some View {
        onScrollGeometryChange(for: CGFloat.self) { geometry in
            max(0, geometry.contentOffset.y)
        } action: { _, offset in
            action(offset)
        }
    }
}

// MARK: - Bar

/// The floating midnight-glass tab bar with the raised gold Regalia circle at its
/// centre. At rest every tab shows its icon and name; as a tab scrolls down the
/// bar tightens to icons only, and any scroll upward — or reaching the top —
/// brings the names back.
struct RegaliaGlassTabBar: View {
    let tabs: [RegaliaTab]
    @Binding var selection: Int
    let isCollapsed: Bool
    let isActionHidden: Bool
    let isArmourComplete: Bool
    let onAction: () -> Void

    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var barHeight: CGFloat { isCollapsed ? 50 : 64 }
    private var circleSize: CGFloat { isCollapsed ? 46 : 58 }
    /// How far the circle rides above its icon row so the "Regalia" name below
    /// it stays clear; a little less lift once the bar collapses.
    private var actionLift: CGFloat { isCollapsed ? -12.5 : -16 }
    private var leadingTabs: [RegaliaTab] { Array(tabs.prefix(2)) }
    private var trailingTabs: [RegaliaTab] { Array(tabs.suffix(2)) }

    var body: some View {
        HStack(spacing: 0) {
            if isActionHidden {
                ForEach(tabs) { tab in
                    tabButton(tab)
                }
            } else {
                ForEach(leadingTabs) { tab in
                    tabButton(tab)
                }
                centreSlot
                ForEach(trailingTabs) { tab in
                    tabButton(tab)
                }
            }
        }
        .padding(.horizontal, 10)
        .frame(height: barHeight)
        .background { barChrome }
    }

    // MARK: Tabs

    private func tabButton(_ tab: RegaliaTab) -> some View {
        let isSelected = selection == tab.id
        return Button {
            guard selection != tab.id else { return }
            Haptics.tap()
            if reduceMotion {
                selection = tab.id
            } else {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                    selection = tab.id
                }
            }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.symbol)
                    .font(.system(size: 18, weight: .semibold))
                    .frame(height: 22)
                    .scaleEffect(isSelected ? 1.06 : 1)

                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .opacity(isCollapsed ? 0 : 1)
                    .frame(height: isCollapsed ? 0 : 13, alignment: .top)
                    .clipped()
            }
            .foregroundStyle(isSelected ? RegaliaTheme.gold : RegaliaTheme.steel)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
            .accessibilityLabel(tab.title)
            .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        }
        .buttonStyle(.plain)
    }

    /// The raised gold Regalia circle, sitting between Archive and The Guard,
    /// with its name on the same label line as the other tabs.
    private var centreSlot: some View {
        VStack(spacing: 3) {
            actionButton
                .frame(height: 22)
                .offset(y: actionLift)

            Text("Regalia")
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundStyle(RegaliaTheme.gold)
                .opacity(isCollapsed ? 0 : 1)
                .frame(height: isCollapsed ? 0 : 13, alignment: .top)
                .clipped()
        }
        .frame(width: 78)
    }

    private var actionButton: some View {
        Button {
            Haptics.tap()
            onAction()
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [RegaliaTheme.gold, RegaliaTheme.goldDeep],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(Circle().stroke(Color.white.opacity(0.25), lineWidth: 1))

                actionIcon
            }
            .frame(width: circleSize, height: circleSize)
            .shadow(color: RegaliaTheme.gold.opacity(0.4), radius: pressed ? 8 : 18, y: 4)
            .scaleEffect(pressed ? 0.92 : 1)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { pressed = true }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) { pressed = false }
                }
        )
    }

    /// Flame before the day has been stood; a crown once the full armour is on.
    /// Cross-fades with a small settle rather than hard-swapping.
    private var actionIcon: some View {
        ZStack {
            Image(systemName: "flame.fill")
                .opacity(isArmourComplete ? 0 : 1)
                .scaleEffect(isArmourComplete ? 0.55 : 1)

            Image(systemName: "crown.fill")
                .opacity(isArmourComplete ? 1 : 0)
                .scaleEffect(isArmourComplete ? 1 : 0.55)
        }
        .font(.system(size: circleSize * 0.38, weight: .bold))
        .foregroundStyle(RegaliaTheme.canvasBottom.opacity(0.9))
        .animation(
            reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.7),
            value: isArmourComplete
        )
    }

    // MARK: Chrome

    @ViewBuilder
    private var barChrome: some View {
        let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
        if #available(iOS 26.0, *) {
            shape
                .fill(Color.clear)
                .glassEffect(.regular.tint(RegaliaTheme.surface.opacity(0.35)), in: shape)
                .overlay(shape.stroke(RegaliaTheme.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        } else {
            shape
                .fill(.ultraThinMaterial)
                .overlay(shape.stroke(RegaliaTheme.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 16, y: 8)
        }
    }
}
