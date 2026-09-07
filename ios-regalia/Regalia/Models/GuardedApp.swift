import SwiftUI

/// An app the user has asked Regalia to guard until the daily session is finished.
nonisolated struct GuardedApp: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let name: String
    let symbol: String
    private let tintHex: UInt32

    var tint: Color { Color(hex: tintHex) }

    nonisolated static let catalog: [GuardedApp] = [
        GuardedApp(id: "tiktok", name: "TikTok", symbol: "music.note", tintHex: 0xFF2D55),
        GuardedApp(id: "instagram", name: "Instagram", symbol: "camera.fill", tintHex: 0xE1306C),
        GuardedApp(id: "youtube", name: "YouTube", symbol: "play.rectangle.fill", tintHex: 0xFF0000),
        GuardedApp(id: "x", name: "X", symbol: "bubble.left.and.bubble.right.fill", tintHex: 0x8E8E93),
        GuardedApp(id: "snapchat", name: "Snapchat", symbol: "bolt.fill", tintHex: 0xFFFC00),
        GuardedApp(id: "reddit", name: "Reddit", symbol: "text.bubble.fill", tintHex: 0xFF4500),
        GuardedApp(id: "netflix", name: "Netflix", symbol: "film.fill", tintHex: 0xE50914),
        GuardedApp(id: "twitch", name: "Twitch", symbol: "gamecontroller.fill", tintHex: 0x9146FF),
        GuardedApp(id: "facebook", name: "Facebook", symbol: "person.2.fill", tintHex: 0x1877F2),
        GuardedApp(id: "browser", name: "Web browser", symbol: "safari.fill", tintHex: 0x0A84FF),
        GuardedApp(id: "games", name: "Games", symbol: "dpad.fill", tintHex: 0x30D158),
        GuardedApp(id: "dating", name: "Dating apps", symbol: "heart.slash.fill", tintHex: 0xFF375F)
    ]

    nonisolated static func app(withID id: String) -> GuardedApp? {
        catalog.first { $0.id == id }
    }
}
