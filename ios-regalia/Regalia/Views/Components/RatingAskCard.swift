import StoreKit
import SwiftUI

/// Regalia's place on the App Store, used to open the review composer directly.
nonisolated enum AppStoreReview {
    /// Regalia's numeric App Store ID (Apple ID 6809547894). Four- and five-star
    /// taps open the review composer directly through `writeReviewURL`. Kept
    /// optional so the card still degrades to Apple's built-in rating prompt if
    /// this is ever cleared.
    nonisolated static let appID: Int? = 6809547894

    nonisolated static var writeReviewURL: URL? {
        guard let appID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appID)?action=write-review")
    }
}

/// The gold star card. Raised on the session celebration when earned, and
/// reachable from Settings at any time. Four or five stars opens the App Store
/// review page; one to three turns the card into a private note that never
/// touches the store.
struct RatingAskCard: View {
    enum Mode {
        /// Counts toward the lifetime ask limits; has a small dismiss control.
        case celebration
        /// Opened from Settings — ignores the caps entirely.
        case manual
    }

    var mode: Mode = .celebration
    var onFinished: () -> Void = {}

    @Environment(RatingCoordinator.self) private var ratings
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var rating: Int?
    @State private var feedback = ""
    @State private var isFeedbackOpen = false
    @State private var isThanking = false
    @State private var poppedStar: Int?
    @State private var rowWidth: CGFloat = 0

    private enum Phase { case stars, feedback }
    private var phase: Phase { isFeedbackOpen ? .feedback : .stars }

    var body: some View {
        Group {
            if isThanking {
                thankYou
            } else {
                cardBody
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.8), value: isThanking)
        .onAppear {
            if mode == .celebration {
                ratings.markAsked()
            }
        }
    }

    // MARK: - Card body

    private var cardBody: some View {
        VStack(spacing: 14) {
            if mode == .celebration {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        Haptics.tap()
                        onFinished()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(RegaliaTheme.steel)
                            .frame(width: 26, height: 26)
                            .regaliaGlass(in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Dismiss")
                }
            }

            VStack(spacing: 5) {
                Text(mode == .celebration ? "You stood today." : "Rate Regalia")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(RegaliaTheme.bone)
                Text("Was it worth it? Tell the App Store.")
                    .font(.footnote)
                    .foregroundStyle(RegaliaTheme.steelBright)
            }
            .multilineTextAlignment(.center)

            if phase == .stars {
                starRow
                responseLine
                submitButton
            } else {
                feedbackEditor
            }
        }
        .padding(18)
        .regaliaCard(highlighted: true)
    }

    // MARK: - Stars

    private var starRow: some View {
        HStack(spacing: 18) {
            ForEach(1...5, id: \.self) { index in
                let isOn = (rating ?? 0) >= index
                Image(systemName: isOn ? "star.fill" : "star")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(isOn ? RegaliaTheme.gold : RegaliaTheme.steel.opacity(0.45))
                    .shadow(color: isOn ? RegaliaTheme.gold.opacity(0.5) : .clear, radius: 6)
                    .scaleEffect(poppedStar == index ? 1.28 : 1)
                    .animation(.spring(response: 0.32, dampingFraction: 0.5), value: poppedStar == index)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 46)
        .contentShape(.rect)
        .onGeometryChange(for: CGFloat.self, of: { $0.size.width }) { rowWidth = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in select(at: value.location.x) }
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rate Regalia, \(rating ?? 0) of 5 stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: select(count: min((rating ?? 0) + 1, 5))
            case .decrement: select(count: max((rating ?? 1) - 1, 1))
            @unknown default: break
            }
        }
        .accessibilityHint("Adjusts the number of stars")
    }

    private func select(at x: CGFloat) {
        guard rowWidth > 0 else { return }
        let count = min(max(Int((x / rowWidth * 5).rounded(.up)), 1), 5)
        select(count: count)
    }

    private func select(count: Int) {
        guard rating != count else { return }
        Haptics.tap()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.6)) {
            rating = count
            poppedStar = count
        }
        Task {
            try? await Task.sleep(for: .milliseconds(320))
            poppedStar = nil
        }
    }

    /// The line that answers back as the stars change.
    @ViewBuilder
    private var responseLine: some View {
        if let rating {
            Text(response(for: rating))
                .font(.callout.italic())
                .foregroundStyle(RegaliaTheme.gold.opacity(0.9))
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 6)))
        } else {
            Text("Tap a star")
                .font(.callout)
                .foregroundStyle(RegaliaTheme.steel)
        }
    }

    private func response(for count: Int) -> String {
        switch count {
        case 1...2: return "That's not good enough."
        case 3: return "There's more we could be."
        case 4: return "Glad the guard is holding."
        default: return "It's changing my mornings."
        }
    }

    // MARK: - Paths

    @ViewBuilder
    private var submitButton: some View {
        if let rating {
            if rating >= 4 {
                RegaliaPrimaryButton(title: "Open the App Store", systemImage: "star.circle.fill", showsChevron: false) {
                    submitHighRating()
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
            } else {
                RegaliaPrimaryButton(title: "Tell us what's missing", systemImage: "envelope.fill", showsChevron: false) {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isFeedbackOpen = true
                    }
                }
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
            }
        }
    }

    /// Four or five stars: a gold sweep, then the review page.
    private func submitHighRating() {
        Haptics.success()
        ratings.markRated()

        withAnimation(.easeInOut(duration: 0.7)) {
            poppedStar = nil
        }

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(750))
            if let url = AppStoreReview.writeReviewURL {
                openURL(url)
            } else {
                requestReview()
            }
            isThanking = true
            closeAfterThanks()
        }
    }

    private var feedbackEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What's missing?")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(RegaliaTheme.bone)

            TextField("A line or two is plenty…", text: $feedback, axis: .vertical)
                .lineLimit(3...5)
                .textInputAutocapitalization(.sentences)
                .font(.callout)
                .foregroundStyle(RegaliaTheme.bone)
                .tint(RegaliaTheme.gold)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(RegaliaTheme.canvasBottom.opacity(0.6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(RegaliaTheme.hairline, lineWidth: 1)
                        )
                }

            RegaliaPrimaryButton(title: "Send it to us", systemImage: "paperplane.fill", showsChevron: false) {
                sendFeedback()
            }
        }
        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 10)))
    }

    private func sendFeedback() {
        Haptics.success()
        ratings.markFeedbackSent()
        if let url = feedbackMailURL() {
            openURL(url)
        }
        isThanking = true
        closeAfterThanks()
    }

    /// The note lands in the support inbox, prefixed with the star count so the
    /// reply can pick up where the person left off.
    private func feedbackMailURL() -> URL? {
        let subject = "Regalia — \(rating ?? 0) star\(rating == 1 ? "" : "s") feedback"
        var body = feedback.trimmingCharacters(in: .whitespacesAndNewlines)
        if body.isEmpty { body = "(no note included)" }
        var parts = URLComponents()
        parts.scheme = "mailto"
        parts.path = "info@omniaiagency.co.uk"
        parts.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return parts.url
    }

    // MARK: - Thanks and closing

    private var thankYou: some View {
        VStack(spacing: 10) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 30, weight: .medium))
                .foregroundStyle(RegaliaTheme.gold)
            Text("Thank you.")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(RegaliaTheme.bone)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .padding(.horizontal, 18)
        .regaliaCard(highlighted: true)
    }

    private func closeAfterThanks() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(1300))
            onFinished()
        }
    }
}
