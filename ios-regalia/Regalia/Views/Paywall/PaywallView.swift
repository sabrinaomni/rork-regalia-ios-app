import SwiftUI

/// Where the paywall is being shown from — it changes the wording, the way out,
/// and what happens once a subscription is active.
nonisolated enum PaywallContext: Sendable {
    /// Straight after the covenant, mid-onboarding.
    case onboarding
    /// Standing in front of the app for someone without a subscription.
    case gate
    /// Opened deliberately from the Settings tab.
    case settings
}

/// The full-bleed armoured lion with REGALIA over it, the two plans, and the
/// commit button. Prices, currency and the saving badge all come from RevenueCat.
struct PaywallView: View {
    let context: PaywallContext
    /// Called once a subscription is active (onboarding hands back to the flow).
    var onSubscribed: (() -> Void)?
    /// Called when someone steps back out of the paywall during onboarding.
    var onBack: (() -> Void)?
    /// The name they gave in onboarding, for the personalized headline.
    var name: String = ""

    @Environment(SubscriptionStore.self) private var subscriptions
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL

    @State private var contentAppeared = false
    @State private var bubblesAppeared = false
    @State private var showRemotePaywall = false

    var body: some View {
        ZStack {
            artwork

            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        Spacer(minLength: proxy.size.height * 0.12)
                        titleBlock
                        Spacer(minLength: 26)
                        battlePoints
                        Spacer(minLength: 26)
                        testimonials
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .safeAreaInset(edge: .top) { topBar }
        // The plans and the commit button stay pinned while the story scrolls
        // above — the buy button never leaves the thumb.
        .safeAreaInset(edge: .bottom, spacing: 0) { fixedCommit }
        .preferredColorScheme(.dark)
        .alert(
            "Something went wrong",
            isPresented: Binding(
                get: { subscriptions.errorMessage != nil },
                set: { if !$0 { subscriptions.errorMessage = nil } }
            )
        ) {
            Button("OK") { subscriptions.errorMessage = nil }
        } message: {
            Text(subscriptions.errorMessage ?? "")
        }
        .fullScreenCover(isPresented: $showRemotePaywall) {
            RemotePaywallView()
        }
        .task {
            await subscriptions.start()
            withAnimation(.easeOut(duration: 0.6)) { contentAppeared = true }
            try? await Task.sleep(for: .seconds(0.45))
            guard !Task.isCancelled else { return }
            bubblesAppeared = true
        }
        .onChange(of: subscriptions.isSubscribed) { _, isSubscribed in
            guard isSubscribed else { return }
            Haptics.success()
            switch context {
            case .onboarding: onSubscribed?()
            case .settings: dismiss()
            case .gate: break
            }
        }
    }

    // MARK: - Art

    /// A clean midnight canvas — gold hearth behind the title, deeper edges, no
    /// artwork competing with the words.
    private var artwork: some View {
        RegaliaTheme.canvas
            .overlay {
                RadialGradient(
                    colors: [RegaliaTheme.gold.opacity(0.20), .clear],
                    center: .init(x: 0.5, y: 0.08),
                    startRadius: 10,
                    endRadius: 330
                )
                .blendMode(.screen)
            }
            .overlay { vignette }
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    /// A faint edge-deepening wash so the glowing title and gold button pop.
    private var vignette: some View {
        LinearGradient(
            stops: [
                .init(color: RegaliaTheme.canvasBottom.opacity(0.30), location: 0),
                .init(color: .clear, location: 0.3),
                .init(color: RegaliaTheme.canvasBottom.opacity(0.42), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    // MARK: - Chrome

    @ViewBuilder
    private var topBar: some View {
        HStack {
            switch context {
            case .onboarding:
                circleButton("chevron.left", label: "Back") {
                    onBack?()
                }
            case .settings:
                circleButton("xmark", label: "Close") {
                    dismiss()
                }
            case .gate:
                EmptyView()
            }

            Spacer(minLength: 0)

            Button {
                Haptics.tap()
                Task { await subscriptions.restore() }
            } label: {
                Group {
                    if subscriptions.isRestoring {
                        ProgressView()
                            .controlSize(.small)
                            .tint(RegaliaTheme.bone)
                    } else {
                        Text("Restore")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundStyle(RegaliaTheme.bone.opacity(0.9))
                .frame(height: 34)
                .padding(.horizontal, 14)
                .regaliaGlass(in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(subscriptions.isRestoring)
            .accessibilityLabel("Restore purchases")
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func circleButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(RegaliaTheme.bone.opacity(0.9))
                .frame(width: 34, height: 34)
                .regaliaGlass(in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Copy

    private var titleBlock: some View {
        Text(headline)
            .font(.system(size: 25, weight: .bold, design: .serif))
            .foregroundStyle(RegaliaTheme.gold)
            .shadow(color: RegaliaTheme.canvasBottom.opacity(0.8), radius: 10, y: 3)
            .multilineTextAlignment(.center)
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
            .opacity(contentAppeared ? 1 : 0)
            .offset(y: contentAppeared ? 0 : 10)
    }

    /// Greets them by name when we have one; otherwise the plain tagline.
    private var headline: String {
        let givenName = name.trimmingCharacters(in: .whitespaces)
        guard !givenName.isEmpty else {
            return "Fight Temptation. Renew Your Mind. Embrace Your Identity."
        }
        return "\(givenName), here's how you fight temptation, renew your mind, and embrace your identity."
    }

    // MARK: - Battle points

    private static let battlePoints: [(icon: String, title: String, detail: String)] = [
        ("shield.fill", "Wear the armour", "The full armour every morning, a guided session."),
        ("brain.head.profile", "Renew your mind", "A prayer written for the day you're in."),
        ("lock.shield.fill", "Stand your ground", "The guard holds your apps shut until you've stood.")
    ]

    private var battlePoints: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(Self.battlePoints.enumerated()), id: \.offset) { index, point in
                HStack(spacing: 14) {
                    Image(systemName: point.icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(RegaliaTheme.gold)
                        .frame(width: 38, height: 38)
                        .regaliaGlass(in: Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(point.title)
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundStyle(RegaliaTheme.bone)
                        Text(point.detail)
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steelBright)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(contentAppeared ? 1 : 0)
                .offset(y: contentAppeared ? 0 : 14)
                .animation(
                    reduceMotion
                        ? .easeOut(duration: 0.3)
                        : .spring(response: 0.55, dampingFraction: 0.82).delay(0.1 + 0.08 * Double(index)),
                    value: contentAppeared
                )
            }
        }
    }

    // MARK: - Testimonials

    fileprivate struct Testimonial {
        let quote: String
        let author: String
    }

    private static let testimonials: [Testimonial] = [
        .init(quote: "The morning armour changed how my days start. I open Regalia before I open anything else.", author: "Sarah"),
        .init(quote: "The guard holds my apps shut until I've stood. First thing that's ever kept me honest.", author: "Marcus"),
        .init(quote: "The prayer speaks to exactly what I'm walking through that day. It feels written for me.", author: "Grace"),
        .init(quote: "My mind feels renewed instead of pulled apart. This is part of my walk now.", author: "David")
    ]

    private var testimonials: some View {
        VStack(spacing: 14) {
            Text("STORIES FROM THE WALK")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .kerning(3)
                .foregroundStyle(RegaliaTheme.steel)
                .frame(maxWidth: .infinity)

            if reduceMotion {
                // A calm static column when motion is reduced.
                VStack(spacing: 12) {
                    ForEach(Array(Self.testimonials.enumerated()), id: \.offset) { index, testimonial in
                        TestimonialBubble(
                            testimonial: testimonial,
                            appeared: bubblesAppeared,
                            delay: 0.16 * Double(index)
                        )
                    }
                }
            } else {
                TestimonialMarquee(testimonials: Self.testimonials)
                    .opacity(contentAppeared ? 1 : 0)
            }
        }
    }

    // MARK: - Fixed commit

    private var fixedCommit: some View {
        VStack(spacing: 0) {
            plans
                .padding(.bottom, 16)
            callToAction
            smallPrint
                .padding(.top, 14)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(commitScrim)
        .opacity(contentAppeared ? 1 : 0)
        .offset(y: contentAppeared ? 0 : 24)
        .animation(
            reduceMotion ? .easeOut(duration: 0.3) : .spring(response: 0.6, dampingFraction: 0.85),
            value: contentAppeared
        )
    }

    /// A fade from clear to the canvas colour so the pinned plans melt into the
    /// artwork instead of sitting on a hard band.
    private var commitScrim: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [RegaliaTheme.canvasBottom.opacity(0), RegaliaTheme.canvasBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 44)

            Rectangle()
                .fill(RegaliaTheme.canvasBottom)
        }
        .allowsHitTesting(false)
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Plans

    @ViewBuilder
    private var plans: some View {
        if let failure = subscriptions.loadFailure {
            failureBlock(failure)
        } else if subscriptions.isLoadingPlans || subscriptions.planOptions.isEmpty {
            VStack(spacing: 10) {
                ShimmerPlanCard()
                ShimmerPlanCard()
            }
        } else {
            VStack(spacing: 10) {
                ForEach(Array(subscriptions.planOptions.enumerated()), id: \.element.id) { index, option in
                    PlanCard(
                        option: option,
                        isSelected: subscriptions.selectedPlan == option.plan
                    ) {
                        withAnimation(.spring(response: 0.34, dampingFraction: 0.78)) {
                            subscriptions.selectedPlan = option.plan
                        }
                    }
                    .opacity(contentAppeared ? 1 : 0)
                    .offset(y: contentAppeared ? 0 : 18)
                    .animation(
                        reduceMotion
                            ? .easeOut(duration: 0.3)
                            : .spring(response: 0.55, dampingFraction: 0.82).delay(0.08 * Double(index)),
                        value: contentAppeared
                    )
                }
            }
        }
    }

    /// Shown when the store genuinely can't be reached — plain words, a retry, and
    /// a way through so our own failure never locks someone out of the app.
    private func failureBlock(_ message: String) -> some View {
        VStack(spacing: 14) {
            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(RegaliaTheme.bone.opacity(0.92))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                Haptics.tap()
                Task { await subscriptions.refreshOfferings() }
            } label: {
                Text("Try again")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(RegaliaTheme.gold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .regaliaGlass(in: Capsule(), tint: RegaliaTheme.gold)
            }
            .buttonStyle(.plain)

            // Backup route: RevenueCat draws its own paywall and fetches its own
            // prices, so it can still sell when our offering lookup failed.
            Button {
                Haptics.tap()
                showRemotePaywall = true
            } label: {
                Text("See the plans another way")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(RegaliaTheme.bone.opacity(0.92))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .regaliaGlass(in: Capsule())
            }
            .buttonStyle(.plain)

            Button("Continue without subscribing") {
                Haptics.tap()
                subscriptions.grantTemporaryAccess()
                switch context {
                case .onboarding: onSubscribed?()
                case .settings: dismiss()
                case .gate: break
                }
            }
            .font(.footnote)
            .foregroundStyle(RegaliaTheme.steelBright)
            .buttonStyle(.plain)
        }
        .padding(18)
        .regaliaCard()
    }

    // MARK: - Commit

    private var callToAction: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.tap()
                Task { await subscriptions.purchase() }
            } label: {
                HStack(spacing: 10) {
                    if subscriptions.isPurchasing {
                        ProgressView()
                            .controlSize(.small)
                            .tint(RegaliaTheme.canvasBottom)
                    }
                    Text(actionTitle)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }
                .foregroundStyle(RegaliaTheme.canvasBottom)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background {
                    Capsule()
                        .fill(RegaliaTheme.goldSheen)
                        .shadow(color: RegaliaTheme.gold.opacity(0.45), radius: 18, y: 6)
                }
                .clipShape(.capsule)
            }
            .buttonStyle(.plain)
            .disabled(!canPurchase)
            .opacity(canPurchase ? 1 : 0.45)
            .animation(.easeInOut(duration: 0.2), value: canPurchase)

            Text("Renews automatically until cancelled. Cancel anytime in the App Store.")
                .font(.caption2)
                .foregroundStyle(RegaliaTheme.steel)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(contentAppeared ? 1 : 0)
    }

    private var canPurchase: Bool {
        !subscriptions.isPurchasing
            && subscriptions.loadFailure == nil
            && !subscriptions.planOptions.isEmpty
    }

    private var actionTitle: String {
        if subscriptions.isPurchasing { return "One moment…" }
        switch context {
        case .onboarding: return "Start my walk"
        case .gate, .settings: return "Unlock Regalia"
        }
    }

    private var smallPrint: some View {
        HStack(spacing: 6) {
            legalLink("Terms", urlString: SubscriptionLinks.terms)
            Text("·")
                .foregroundStyle(RegaliaTheme.steel.opacity(0.6))
            legalLink("Privacy", urlString: SubscriptionLinks.privacy)
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func legalLink(_ title: String, urlString: String) -> some View {
        if let url = URL(string: urlString) {
            Button(title) {
                openURL(url)
            }
            .buttonStyle(.plain)
            .foregroundStyle(RegaliaTheme.steelBright)
        }
    }
}

// MARK: - Testimonial marquee

/// An endless horizontal drift of story bubbles: two copies of the row glide
/// left in lockstep and the offset wraps after one row's width, so the loop
/// has no visible seam. Deterministic card widths keep the loop length exact.
private struct TestimonialMarquee: View {
    let testimonials: [PaywallView.Testimonial]

    @State private var drift: CGFloat = 0

    private let cardWidth: CGFloat = 264
    private let spacing: CGFloat = 12

    /// Slow drift — roughly one card every five seconds.
    private var loopWidth: CGFloat {
        (cardWidth + spacing) * CGFloat(testimonials.count)
    }

    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: spacing) {
                row
                row
            }
            .offset(x: drift)
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .leading)
            .clipped()
        }
        .frame(height: 164)
        .onAppear {
            guard !testimonials.isEmpty else { return }
            withAnimation(.linear(duration: loopWidth / 26).repeatForever(autoreverses: false)) {
                drift = -loopWidth
            }
        }
    }

    private var row: some View {
        HStack(spacing: spacing) {
            ForEach(Array(testimonials.enumerated()), id: \.offset) { _, testimonial in
                TestimonialBubble(
                    testimonial: testimonial,
                    appeared: true,
                    delay: 0
                )
                .frame(width: cardWidth)
            }
        }
    }
}

// MARK: - Testimonial bubble

/// A customer review styled as a chat bubble with five gold stars, popping in
/// with a spring once its turn comes.
private struct TestimonialBubble: View {
    let testimonial: PaywallView.Testimonial
    let appeared: Bool
    let delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 3) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(RegaliaTheme.gold)
                }
            }

            Text(testimonial.quote)
                .font(.system(size: 14))
                .foregroundStyle(RegaliaTheme.bone.opacity(0.94))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(String(testimonial.author.prefix(1)))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(RegaliaTheme.canvasBottom)
                    .frame(width: 22, height: 22)
                    .background { Circle().fill(RegaliaTheme.goldSheen) }

                Text(testimonial.author)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(RegaliaTheme.steelBright)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(RegaliaTheme.surface.opacity(0.5))
        }
        .regaliaGlass(in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(RegaliaTheme.hairline, lineWidth: 1)
        }
        .scaleEffect(reduceMotion ? 1 : (appeared ? 1 : 0.7))
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 16)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.35)
                : .spring(response: 0.5, dampingFraction: 0.72).delay(appeared ? delay : 0),
            value: appeared
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("5 stars. \(testimonial.quote) \(testimonial.author)")
    }
}

// MARK: - Plan card

/// One selectable plan. The selected card carries the gold border and glow.
private struct PlanCard: View {
    let option: PlanOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21))
                    .foregroundStyle(isSelected ? RegaliaTheme.gold : RegaliaTheme.steel.opacity(0.45))

                VStack(alignment: .leading, spacing: 3) {
                    Text(option.title)
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundStyle(RegaliaTheme.bone)
                    Text(option.cadence)
                        .font(.caption)
                        .foregroundStyle(RegaliaTheme.steelBright)
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 3) {
                    Text(option.priceText)
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .foregroundStyle(isSelected ? RegaliaTheme.gold : RegaliaTheme.bone)
                    if let footnote = option.footnote {
                        Text(footnote)
                            .font(.caption2)
                            .foregroundStyle(RegaliaTheme.steel)
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(RegaliaTheme.surface.opacity(isSelected ? 0.72 : 0.42))
            }
            .regaliaGlass(
                in: RoundedRectangle(cornerRadius: 20, style: .continuous),
                tint: isSelected ? RegaliaTheme.gold : nil
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        isSelected ? RegaliaTheme.gold.opacity(0.85) : RegaliaTheme.hairline,
                        lineWidth: isSelected ? 1.4 : 1
                    )
            }
            .shadow(color: RegaliaTheme.gold.opacity(isSelected ? 0.28 : 0), radius: 16, y: 5)
            .overlay(alignment: .topTrailing) {
                if let badge = option.badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .kerning(0.4)
                        .foregroundStyle(RegaliaTheme.canvasBottom)
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background { Capsule().fill(RegaliaTheme.goldSheen) }
                        .offset(x: -14, y: -9)
                }
            }
            .scaleEffect(isSelected ? 1 : 0.985)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title), \(option.priceText), \(option.cadence)")
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
    }
}

// MARK: - Loading placeholder

/// A plan-shaped card with a slow band of light crossing it while prices load.
private struct ShimmerPlanCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shift: CGFloat = -0.6

    var body: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .fill(RegaliaTheme.surface.opacity(0.45))
            .frame(height: 80)
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [.clear, RegaliaTheme.bone.opacity(0.14), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: proxy.size.width * 0.4)
                    .offset(x: shift * proxy.size.width)
                    .blendMode(.screen)
                }
            }
            .clipShape(.rect(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(RegaliaTheme.hairline, lineWidth: 1)
            }
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: false)) {
                    shift = 1.3
                }
            }
            .accessibilityLabel("Loading plans")
    }
}

#Preview {
    PaywallView(context: .gate)
        .environment(SubscriptionStore())
}
