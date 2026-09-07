import WidgetKit
import SwiftUI

// MARK: - Theme (kept in step with RegaliaTheme in the app target)

nonisolated enum WidgetTheme {
    static let canvasTop = Color(hex: 0x0B1020)
    static let canvasBottom = Color(hex: 0x05070F)
    static let gold = Color(hex: 0xE8B44A)
    static let bone = Color(hex: 0xF2E7D0)
    static let steel = Color(hex: 0x6E88C4)
    static let hairline = Color(hex: 0xE8B44A).opacity(0.18)

    static var canvas: LinearGradient {
        LinearGradient(colors: [canvasTop, canvasBottom], startPoint: .top, endPoint: .bottom)
    }
}

extension Color {
    /// Creates a color from a 24-bit RGB literal such as `0xE8B44A`.
    nonisolated init(hex: UInt32, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

// MARK: - Snapshot

/// The tiny snapshot the app mirrors into the App Group after every session change.
/// The widget never runs the app's logic — it just reads this.
nonisolated struct WidgetSnapshot: Equatable {
    let verseText: String
    let verseReference: String
    let isArmourComplete: Bool
    let equippedCount: Int
    let streak: Int

    var hasVerse: Bool { !verseText.isEmpty }

    static func read() -> WidgetSnapshot {
        let defaults = UserDefaults(suiteName: "group.app.rork.c9feujhlfbusu7b56fh6w")
        return WidgetSnapshot(
            verseText: defaults?.string(forKey: "widget.verseText") ?? "",
            verseReference: defaults?.string(forKey: "widget.verseReference") ?? "",
            isArmourComplete: defaults?.bool(forKey: "widget.isArmourOn") ?? false,
            equippedCount: defaults?.integer(forKey: "widget.equippedCount") ?? 0,
            streak: defaults?.integer(forKey: "widget.streak") ?? 0
        )
    }
}

// MARK: - Timeline

nonisolated struct VerseEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

nonisolated struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, snapshot: WidgetSnapshot.read())
    }

    func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, snapshot: WidgetSnapshot.read()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let entry = VerseEntry(date: .now, snapshot: WidgetSnapshot.read())
        // Roll over just after midnight so a new day never shows a stale verse.
        let nextMidnight = Calendar.current.startOfDay(for: Date()).addingTimeInterval(24 * 3600 + 60)
        completion(Timeline(entries: [entry], policy: .after(nextMidnight)))
    }
}

// MARK: - Views

struct RegaliaWidgetView: View {
    @Environment(\.widgetFamily) private var family
    var entry: Provider.Entry

    var body: some View {
        Group {
            switch family {
            case .systemMedium:
                MediumVerseView(snapshot: entry.snapshot)
            default:
                SmallVerseView(snapshot: entry.snapshot)
            }
        }
        .padding(4)
        .containerBackground(for: .widget) {
            ZStack {
                WidgetTheme.canvas
                RadialGradient(
                    colors: [WidgetTheme.gold.opacity(0.20), .clear],
                    center: UnitPoint(x: 0.5, y: 0.0),
                    startRadius: 5,
                    endRadius: 220
                )
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(WidgetTheme.hairline, lineWidth: 1)
            }
        }
    }
}

/// Small tile: lion seal, kept verse, gold reference.
private struct SmallVerseView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image("lion_mascot_sitting_upward")
                .resizable()
                .scaledToFit()
                .frame(height: 30)
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 0)

            if snapshot.hasVerse {
                Text("\u{201C}\(snapshot.verseText)\u{201D}")
                    .font(.system(size: 13, weight: .medium, design: .serif))
                    .foregroundStyle(WidgetTheme.bone)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.65)
                    .fixedSize(horizontal: false, vertical: true)

                Text(snapshot.verseReference)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .kerning(1.5)
                    .textCase(.uppercase)
                    .foregroundStyle(WidgetTheme.gold)
            } else {
                Spacer(minLength: 0)
                Text("Put on the armour — today's verse will be kept here.")
                    .font(.system(size: 12, design: .serif).italic())
                    .foregroundStyle(WidgetTheme.steel)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// Medium tile: verse on the left, reference + streak + status on the right.
private struct MediumVerseView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                if snapshot.hasVerse {
                    Text("\u{201C}\(snapshot.verseText)\u{201D}")
                        .font(.system(size: 14, weight: .medium, design: .serif))
                        .foregroundStyle(WidgetTheme.bone)
                        .lineSpacing(3)
                        .minimumScaleFactor(0.7)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Put on the armour — today's verse will be kept here.")
                        .font(.system(size: 13, design: .serif).italic())
                        .foregroundStyle(WidgetTheme.steel)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 6) {
                Image("lion_mascot_sitting_upward")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 24)

                Spacer(minLength: 0)

                if snapshot.hasVerse {
                    Text(snapshot.verseReference)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .kerning(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(WidgetTheme.gold)
                        .multilineTextAlignment(.trailing)
                }

                if snapshot.streak > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 9))
                        Text("\(snapshot.streak)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                    }
                    .foregroundStyle(WidgetTheme.gold)
                }

                StatusLine(snapshot: snapshot)
            }
            .frame(width: 92, alignment: .trailing)
        }
    }
}

/// "Armour on" when today's stand is done; a quiet nudge while it's still ahead.
private struct StatusLine: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .semibold))
            Text(label)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isDone ? WidgetTheme.gold : WidgetTheme.steel)
    }

    private var isDone: Bool { snapshot.isArmourComplete }

    private var symbol: String {
        isDone ? "seal.fill" : (snapshot.equippedCount == 0 ? "hand.raised.fill" : "shield")
    }

    private var label: String {
        if isDone { return "Armour on" }
        return snapshot.equippedCount == 0 ? "Say it first" : "Stand ahead"
    }
}

// MARK: - Widget

struct RegaliaWidget: Widget {
    let kind: String = "RegaliaVerseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RegaliaWidgetView(entry: entry)
        }
        .configurationDisplayName("Kept Verse")
        .description("Today's kept verse, with your armour status and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
