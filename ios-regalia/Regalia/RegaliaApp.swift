//
//  RegaliaApp.swift
//  Regalia
//

import RevenueCat
import SwiftUI

@main
struct RegaliaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = RegaliaStore()
    @State private var screenTime = ScreenTimeGuard()
    @State private var reminders = ReminderScheduler()
    @State private var subscriptions = SubscriptionStore()

    init() {
        RegaliaApp.configurePurchases()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .environment(screenTime)
                .environment(reminders)
                .environment(subscriptions)
        }
    }

    /// Foregrounds notification handling: banners still show while the app is open,
/// and any tapped Regalia reminder — body or "Stand now" — becomes a session.
final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        if action == ReminderScheduler.standActionID || action == UNNotificationDefaultActionIdentifier {
            Task { @MainActor in
                NotificationCenter.default.post(name: ReminderScheduler.openSessionSignal, object: nil)
            }
        }
        completionHandler()
    }
}

/// Configures RevenueCat once, at launch: the Test Store in debug builds and the
    /// App Store in release. An absent key leaves the SDK unconfigured rather than
    /// crashing, and the paywall reports that plainly.
    private static func configurePurchases() {
        #if DEBUG
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_TEST_API_KEY
        Purchases.logLevel = .warn
        #else
        let apiKey = Config.EXPO_PUBLIC_REVENUECAT_IOS_API_KEY
        #endif

        guard !apiKey.isEmpty else {
            print("[Subscriptions] no RevenueCat API key for this build — purchases disabled")
            return
        }
        Purchases.configure(withAPIKey: apiKey)
    }
}
