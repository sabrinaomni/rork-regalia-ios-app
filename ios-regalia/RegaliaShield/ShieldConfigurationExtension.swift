import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Draws the Regalia block screen iOS shows in place of a guarded app.
///
/// Apple renders this out-of-process with a fixed layout, so the styling is limited to
/// a background, an icon, two labels, and two buttons. Everything shown here is mirrored
/// from the app through `GuardBridge`.
nonisolated final class ShieldConfigurationExtension: ShieldConfigurationDataSource {
    override func configuration(shielding application: Application) -> ShieldConfiguration {
        ShieldStyle.regalia()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        ShieldStyle.regalia()
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        ShieldStyle.regalia()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        ShieldStyle.regalia()
    }
}

/// Builds the shield's look from the state the app last mirrored into the App Group.
nonisolated enum ShieldStyle {
    private static let canvas = UIColor(red: 0.043, green: 0.063, blue: 0.125, alpha: 1)
    private static let bone = UIColor(red: 0.949, green: 0.906, blue: 0.816, alpha: 1)
    private static let gold = UIColor(red: 0.910, green: 0.706, blue: 0.290, alpha: 1)
    private static let steel = UIColor(red: 0.431, green: 0.533, blue: 0.769, alpha: 1)
    private static let midnight = UIColor(red: 0.082, green: 0.110, blue: 0.192, alpha: 1)

    static func regalia() -> ShieldConfiguration {
        let passesLeft = GuardBridge.passesLeftThisWeek
        let verse = "\u{201C}\(GuardBridge.verseText)\u{201D}\n\(GuardBridge.verseReference)"

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: canvas.withAlphaComponent(0.96),
            icon: mascot(),
            title: ShieldConfiguration.Label(text: GuardBridge.headline, color: bone),
            subtitle: ShieldConfiguration.Label(text: verse, color: steel),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: "Put on the armour",
                color: midnight
            ),
            primaryButtonBackgroundColor: gold,
            secondaryButtonLabel: ShieldConfiguration.Label(
                text: passesLeft > 0 ? "Spend a pass (\(passesLeft) left)" : "No passes left this week",
                color: passesLeft > 0 ? steel : steel.withAlphaComponent(0.5)
            )
        )
    }

    /// The lion at whatever stage of the armour the user has actually reached today.
    private static func mascot() -> UIImage? {
        let name: String
        switch GuardBridge.armourCount {
        case 0...1: name = "shield_lion_bare"
        case 2...4: name = "shield_lion_partial"
        default: name = "shield_lion_full"
        }
        return UIImage(named: name)
    }
}
