import RevenueCat
import RevenueCatUI
import SwiftUI

/// RevenueCat's dashboard-configured paywall, used only as the backup when Regalia's
/// own paywall cannot load its plans.
///
/// This path fetches its own layout, copy and prices through the SDK, so it can still
/// sell a subscription when our offering lookup failed. Entitlement changes arrive
/// through `SubscriptionStore`'s customer-info listener, so there is no state to copy
/// across by hand — these callbacks only decide when the screen closes.
struct RemotePaywallView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        RevenueCatUI.PaywallView(displayCloseButton: true)
            .onPurchaseCompleted { _ in
                Haptics.success()
                dismiss()
            }
            .onRestoreCompleted { _ in
                Haptics.success()
                dismiss()
            }
            .onRequestedDismissal {
                dismiss()
            }
            .preferredColorScheme(.dark)
            .tint(RegaliaTheme.gold)
            .background {
                RegaliaTheme.canvasBottom.ignoresSafeArea()
            }
    }
}

#Preview {
    RemotePaywallView()
}
