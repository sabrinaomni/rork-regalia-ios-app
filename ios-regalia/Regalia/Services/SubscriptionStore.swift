import Foundation
import Observation
import RevenueCat

/// The two cadences Regalia sells. Titles and cadence copy live here; every price
/// comes from RevenueCat so changing a price in the dashboard needs no new build.
nonisolated enum SubscriptionPlan: String, Hashable, Sendable {
    case annual
    case monthly

    var title: String {
        switch self {
        case .annual: "Yearly"
        case .monthly: "Monthly"
        }
    }

    var cadence: String {
        switch self {
        case .annual: "billed once a year"
        case .monthly: "billed every month"
        }
    }
}

/// A plan exactly as the paywall draws it, so the views never touch the RevenueCat types.
nonisolated struct PlanOption: Identifiable, Equatable, Sendable {
    let plan: SubscriptionPlan
    /// Localized price string straight from the store, e.g. "$29.99".
    let priceText: String
    /// Secondary line, e.g. "$2.50 / month".
    let footnote: String?
    /// Gold badge text, computed from the two real prices.
    let badge: String?

    var id: SubscriptionPlan { plan }
    var title: String { plan.title }
    var cadence: String { plan.cadence }
}

/// Small print destinations required for subscription review.
nonisolated enum SubscriptionLinks {
    static let terms = "https://wear-regalia-daily.base44.app/terms"
    static let privacy = "https://wear-regalia-daily.base44.app/privacy"
    static let support = "https://wear-regalia-daily.base44.app/support"
}

/// Owns Regalia's subscription state: the offering shown on the paywall, the
/// entitlement that unlocks the app, purchases, and restores.
///
/// The last known entitlement is cached on the device so a paying subscriber with
/// no signal is never shut out of their own morning.
@Observable
@MainActor
final class SubscriptionStore {
    nonisolated enum LoadState: Equatable, Sendable {
        case idle
        case loading
        case loaded
        case failed(String)
    }

    /// Entitlement lookup key configured in RevenueCat.
    static let entitlementID = "regalia_premium"

    private(set) var isSubscribed: Bool
    /// "Yearly" / "Monthly" for the Settings row, from the active entitlement.
    private(set) var planName: String?
    private(set) var renewsAt: Date?
    private(set) var willRenew: Bool = false

    private(set) var loadState: LoadState = .idle
    private(set) var isPurchasing = false
    private(set) var isRestoring = false
    var selectedPlan: SubscriptionPlan = .annual
    var errorMessage: String?

    /// Granted only when the plans genuinely cannot be reached, so a failure on our
    /// side never locks someone out of the app. Never persisted.
    private(set) var hasTemporaryAccess = false

    private var annualPackage: Package?
    private var monthlyPackage: Package?
    private var didStart = false
    private let defaults: UserDefaults

    private enum Key {
        static let active = "regalia.subscription.active"
        static let planName = "regalia.subscription.planName"
        static let renewsAt = "regalia.subscription.renewsAt"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        isSubscribed = defaults.bool(forKey: Key.active)
        planName = defaults.string(forKey: Key.planName)
        renewsAt = defaults.object(forKey: Key.renewsAt) as? Date
    }

    // MARK: - Derived state

    /// True when the app should be open to this person.
    var hasAccess: Bool { isSubscribed || hasTemporaryAccess }

    var isLoadingPlans: Bool { loadState == .loading || loadState == .idle }

    var loadFailure: String? {
        if case let .failed(message) = loadState { return message }
        return nil
    }

    /// The plans in the order the paywall stacks them: yearly first.
    var planOptions: [PlanOption] {
        var options: [PlanOption] = []
        if let annualPackage {
            options.append(
                PlanOption(
                    plan: .annual,
                    priceText: annualPackage.storeProduct.localizedPriceString,
                    footnote: annualPerMonthText.map { "\($0) / month" },
                    badge: annualSavingBadge
                )
            )
        }
        if let monthlyPackage {
            options.append(
                PlanOption(
                    plan: .monthly,
                    priceText: monthlyPackage.storeProduct.localizedPriceString,
                    footnote: nil,
                    badge: nil
                )
            )
        }
        return options
    }

    /// Yearly price divided across twelve months, formatted in the store's own currency.
    private var annualPerMonthText: String? {
        guard let product = annualPackage?.storeProduct,
              let formatter = product.priceFormatter else { return nil }
        let perMonth = product.price / Decimal(12)
        return formatter.string(from: NSDecimalNumber(decimal: perMonth))
    }

    /// Computed from the two real prices, never hardcoded, so it can't overstate the saving.
    private var annualSavingBadge: String? {
        guard let monthlyPrice = monthlyPackage?.storeProduct.price,
              let annualPrice = annualPackage?.storeProduct.price,
              monthlyPrice > 0 else { return nil }
        let twelveMonths = monthlyPrice * Decimal(12)
        guard annualPrice < twelveMonths else { return nil }
        let ratio = (twelveMonths - annualPrice) / twelveMonths
        let percent = Int((NSDecimalNumber(decimal: ratio).doubleValue * 100).rounded())
        guard percent >= 5 else { return nil }
        return "Save \(percent)%"
    }

    /// One line describing the subscription for the Settings row.
    var statusLine: String {
        guard isSubscribed else { return "Not subscribed" }
        let plan = planName ?? "Subscribed"
        guard let renewsAt else { return plan }
        let date = renewsAt.formatted(date: .abbreviated, time: .omitted)
        return willRenew ? "\(plan) · renews \(date)" : "\(plan) · ends \(date)"
    }

    // MARK: - Lifecycle

    /// Starts the entitlement listener and loads the offering. Safe to call repeatedly.
    func start() async {
        guard !didStart else { return }
        didStart = true
        guard Purchases.isConfigured else {
            loadState = .failed("Subscriptions aren't configured in this build.")
            return
        }
        Task { await self.listenForEntitlementChanges() }
        await refreshOfferings()
        await refreshStatus()
    }

    /// Keeps purchases, renewals, cancellations and refunds reflected without a relaunch.
    private func listenForEntitlementChanges() async {
        for await info in Purchases.shared.customerInfoStream {
            apply(info)
        }
    }

    func refreshOfferings() async {
        guard Purchases.isConfigured else {
            loadState = .failed("Subscriptions aren't configured in this build.")
            return
        }
        loadState = .loading
        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else {
                loadState = .failed("No subscription plans are available right now.")
                return
            }
            annualPackage = current.annual ?? current.availablePackages.first { $0.packageType == .annual }
            monthlyPackage = current.monthly ?? current.availablePackages.first { $0.packageType == .monthly }
            guard annualPackage != nil || monthlyPackage != nil else {
                loadState = .failed("No subscription plans are available right now.")
                return
            }
            selectedPlan = annualPackage != nil ? .annual : .monthly
            loadState = .loaded
        } catch {
            print("[Subscriptions] offerings failed: \(error.localizedDescription)")
            loadState = .failed("We couldn't reach the store. Check your connection and try again.")
        }
    }

    /// Silent refresh of the entitlement; a failure keeps the cached state.
    func refreshStatus() async {
        guard Purchases.isConfigured else { return }
        do {
            apply(try await Purchases.shared.customerInfo())
        } catch {
            print("[Subscriptions] status refresh failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard !isPurchasing, Purchases.isConfigured, let package = package(for: selectedPlan) else { return }
        isPurchasing = true
        do {
            let result = try await Purchases.shared.purchase(package: package)
            if !result.userCancelled {
                apply(result.customerInfo)
            }
        } catch ErrorCode.purchaseCancelledError {
            // Cancelled at the StoreKit sheet — not an error.
        } catch ErrorCode.paymentPendingError {
            // Awaiting parental approval or extra authentication — not a failure.
        } catch {
            print("[Subscriptions] purchase failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        guard !isRestoring, Purchases.isConfigured else { return }
        isRestoring = true
        do {
            let info = try await Purchases.shared.restorePurchases()
            apply(info)
            if !isSubscribed {
                errorMessage = "No active Regalia subscription was found for this Apple Account."
            }
        } catch {
            print("[Subscriptions] restore failed: \(error.localizedDescription)")
            errorMessage = error.localizedDescription
        }
        isRestoring = false
    }

    /// Escape hatch shown only when the plans could not be loaded at all.
    func grantTemporaryAccess() {
        hasTemporaryAccess = true
    }

    // MARK: - Internals

    private func package(for plan: SubscriptionPlan) -> Package? {
        switch plan {
        case .annual: annualPackage
        case .monthly: monthlyPackage
        }
    }

    private func apply(_ info: CustomerInfo) {
        let entitlement = info.entitlements[SubscriptionStore.entitlementID]
        let active = entitlement?.isActive == true
        isSubscribed = active
        willRenew = entitlement?.willRenew ?? false
        renewsAt = active ? entitlement?.expirationDate : nil
        planName = active ? SubscriptionStore.planName(for: entitlement?.productIdentifier) : nil
        if active {
            hasTemporaryAccess = false
        }
        cache()
    }

    private func cache() {
        defaults.set(isSubscribed, forKey: Key.active)
        if let planName {
            defaults.set(planName, forKey: Key.planName)
        } else {
            defaults.removeObject(forKey: Key.planName)
        }
        if let renewsAt {
            defaults.set(renewsAt, forKey: Key.renewsAt)
        } else {
            defaults.removeObject(forKey: Key.renewsAt)
        }
    }

    private nonisolated static func planName(for productIdentifier: String?) -> String? {
        guard let identifier = productIdentifier?.lowercased() else { return nil }
        if identifier.contains("year") || identifier.contains("annual") { return SubscriptionPlan.annual.title }
        if identifier.contains("month") { return SubscriptionPlan.monthly.title }
        return "Subscribed"
    }
}
