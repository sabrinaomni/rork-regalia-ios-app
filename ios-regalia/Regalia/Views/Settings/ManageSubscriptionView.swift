import RevenueCatUI
import SwiftUI

/// RevenueCat's Customer Center: change plan, cancel, request an Apple refund,
/// restore a purchase, or reach support — without leaving Regalia.
///
/// The screens and wording are configured in the RevenueCat dashboard under
/// Monetization Tools, so they stay current without shipping a new build. Anything
/// changed here reaches Regalia's own state through the customer-info listener in
/// `SubscriptionStore`.
struct ManageSubscriptionView: View {
    var body: some View {
        CustomerCenterView()
            .preferredColorScheme(.dark)
            .tint(RegaliaTheme.gold)
    }
}

#Preview {
    ManageSubscriptionView()
}
