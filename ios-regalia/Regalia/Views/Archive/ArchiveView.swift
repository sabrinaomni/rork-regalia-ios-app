import SwiftUI

/// Archive tab: streak stats, filters, and every kept verse, prayer, and declaration.
struct ArchiveView: View {
    @Environment(RegaliaStore.self) private var store

    @State private var filter: ArchiveFilter = .all
    @State private var selected: SessionRecord?

    var body: some View {
        ZStack {
            RegaliaBackground(bloomStrength: 0.14)

            ScrollView {
                VStack(alignment: .leading, spacing: RegaliaLayout.sectionStack) {
                    Text("Archive")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(RegaliaTheme.bone)

                    stats

                    ScrollView(.horizontal) {
                        HStack(spacing: RegaliaLayout.rowStack) {
                            ForEach(ArchiveFilter.allCases) { option in
                                RegaliaChip(title: option.title, isSelected: filter == option) {
                                    withAnimation(.easeInOut(duration: 0.25)) { filter = option }
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                    .scrollIndicators(.hidden)

                    if groupedRecords.isEmpty {
                        emptyState
                    } else {
                        ForEach(groupedRecords, id: \.month) { group in
                            monthSection(group)
                        }

                        Text("Well done, good and faithful servant. Your faithfulness is building eternal strength.")
                            .font(.footnote)
                            .foregroundStyle(RegaliaTheme.steelBright)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, RegaliaLayout.tabbedScrollBottom)
            }
            .scrollIndicators(.hidden)
        }
        .sheet(item: $selected) { record in
            ArchiveDetailView(record: record)
        }
    }

    // MARK: - Pieces

    private var stats: some View {
        HStack(spacing: RegaliaLayout.cardStack - 2) {
            StatTile(value: "\(store.streak)", label: "Day streak")
            StatTile(value: "\(store.versesKept)", label: "Verses kept")
            StatTile(value: reclaimedLabel, label: "Reclaimed")
        }
    }

    private var reclaimedLabel: String {
        let minutes = store.minutesReclaimed
        if minutes < 60 { return "\(minutes)m" }
        return "\(minutes / 60)h"
    }

    private var emptyState: some View {
        VStack(spacing: RegaliaLayout.cardStack) {
            Image(systemName: "book.closed")
                .font(.system(size: 34))
                .foregroundStyle(RegaliaTheme.gold.opacity(0.7))
            Text("Nothing kept yet")
                .font(.headline)
                .foregroundStyle(RegaliaTheme.bone)
            Text("Finish your first Regalia and every verse, prayer, and declaration lands here.")
                .font(.footnote)
                .foregroundStyle(RegaliaTheme.steelBright)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 20)
        .regaliaCard()
    }

    private func monthSection(_ group: MonthGroup) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(group.month.uppercased())
                .font(.caption.weight(.semibold))
                .kerning(1.4)
                .foregroundStyle(RegaliaTheme.steel)
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 10)

            ForEach(Array(group.records.enumerated()), id: \.element.id) { pair in
                Button {
                    Haptics.tap()
                    selected = pair.element
                } label: {
                    ArchiveRow(record: pair.element, filter: filter)
                }
                .buttonStyle(.plain)

                if pair.offset < group.records.count - 1 {
                    Divider()
                        .overlay(RegaliaTheme.hairline)
                        .padding(.leading, 62)
                }
            }
            .padding(.bottom, 6)
        }
        .regaliaCard()
    }

    // MARK: - Data

    private struct MonthGroup {
        let month: String
        let records: [SessionRecord]
    }

    private var groupedRecords: [MonthGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "LLLL"

        var order: [String] = []
        var buckets: [String: [SessionRecord]] = [:]

        for record in store.completedRecords {
            let key = formatter.string(from: record.date)
            if buckets[key] == nil {
                buckets[key] = []
                order.append(key)
            }
            buckets[key]?.append(record)
        }

        return order.map { MonthGroup(month: $0, records: buckets[$0] ?? []) }
    }
}

nonisolated enum ArchiveFilter: String, CaseIterable, Identifiable, Sendable {
    case all, verses, prayers, declarations

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .verses: "Verses"
        case .prayers: "Prayers"
        case .declarations: "Declarations"
        }
    }
}

/// A single archived day.
private struct ArchiveRow: View {
    let record: SessionRecord
    let filter: ArchiveFilter

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: record.mood?.symbol ?? "shield.fill")
                .font(.system(size: 20))
                .foregroundStyle(RegaliaTheme.gold.opacity(0.9))
                .frame(width: 34)

            VStack(alignment: .leading, spacing: 4) {
                Text(headline)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(RegaliaTheme.bone)

                Text(preview)
                    .font(.footnote.italic())
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 6)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(RegaliaTheme.steel.opacity(0.7))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .contentShape(.rect)
    }

    private var headline: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        let date = formatter.string(from: record.date)
        guard let mood = record.mood else { return date }
        return "\(date) · \(mood.label)"
    }

    private var preview: String {
        switch filter {
        case .all, .verses:
            if let verse = record.dailyVerse ?? record.moodVerse {
                return "“\(verse.text)”"
            }
        case .prayers:
            if let prayer = record.prayer {
                return prayer.title
            }
        case .declarations:
            if !record.handedOver.isEmpty {
                return "Handed over: \(record.handedOver)"
            }
            return "\(record.equippedCount) of 7 pieces declared"
        }
        return "\(record.equippedCount) of 7 pieces equipped"
    }
}

/// Detail sheet for one archived day.
private struct ArchiveDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let record: SessionRecord

    var body: some View {
        NavigationStack {
            ZStack {
                RegaliaBackground(bloomStrength: 0.12)

                ScrollView {
                    VStack(spacing: RegaliaLayout.sectionStack) {
                        HStack(spacing: RegaliaLayout.rowStack) {
                            if let mood = record.mood {
                                Label(mood.label, systemImage: mood.symbol)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(RegaliaTheme.gold)
                            }
                            Spacer()
                            Text("\(record.equippedCount) of 7 equipped")
                                .font(.footnote.monospacedDigit())
                                .foregroundStyle(RegaliaTheme.steelBright)
                        }

                        ArmourTrack(equipped: record.equippedPieces)
                            .padding(.vertical, 6)

                        if let verse = record.dailyVerse {
                            sectionCard(title: "Today's verse") { VerseCard(verse: verse, compact: true) }
                        }
                        if let verse = record.moodVerse {
                            sectionCard(title: "Mood Scripture") { VerseCard(verse: verse, compact: true) }
                        }
                        if let verse = record.temptationVerse {
                            sectionCard(title: "Against temptation") { VerseCard(verse: verse, compact: true) }
                        }
                        if let renewal = record.renewal {
                            sectionCard(title: "Renewed") {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Lie: \(renewal.lie)")
                                        .font(.callout)
                                        .foregroundStyle(RegaliaTheme.steelBright)
                                    Text("Truth: \(renewal.truth)")
                                        .font(.callout.weight(.medium))
                                        .foregroundStyle(RegaliaTheme.bone)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .regaliaCard(cornerRadius: 16)
                            }
                        }
                        if !record.handedOver.isEmpty {
                            sectionCard(title: "Handed over") {
                                Text(record.handedOver)
                                    .font(.callout)
                                    .foregroundStyle(RegaliaTheme.bone)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .regaliaCard(cornerRadius: 16)
                            }
                        }
                        if let prayer = record.prayer {
                            sectionCard(title: prayer.title) {
                                PrayerBody(text: prayer.body, fontSize: 16)
                                    .foregroundStyle(RegaliaTheme.bone)
                                    .padding(14)
                                    .regaliaCard(cornerRadius: 16)
                            }
                        }
                        if let supporting = record.supportingVerses, !supporting.isEmpty {
                            sectionCard(title: "Scripture behind the armour") {
                                VStack(alignment: .leading, spacing: RegaliaLayout.rowStack) {
                                    ForEach(ArmourPiece.allCases, id: \.self) { piece in
                                        if let verse = supporting[piece.rawValue] {
                                            HStack(alignment: .top, spacing: 12) {
                                                Text(piece.shortTitle)
                                                    .font(.caption.weight(.semibold))
                                                    .kerning(0.8)
                                                    .foregroundStyle(RegaliaTheme.gold.opacity(0.85))
                                                    .frame(width: 88, alignment: .leading)
                                                VStack(alignment: .leading, spacing: 3) {
                                                    Text(verse.text)
                                                        .font(.footnote)
                                                        .foregroundStyle(RegaliaTheme.steelBright)
                                                        .fixedSize(horizontal: false, vertical: true)
                                                    Text(verse.reference)
                                                        .font(.caption.italic())
                                                        .foregroundStyle(RegaliaTheme.steel)
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .regaliaCard(cornerRadius: 16)
                            }
                        }
                    }
                    .padding(20)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(RegaliaTheme.gold)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .presentationDetents([.large])
        .presentationContentInteraction(.scrolls)
    }

    private var title: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: record.date)
    }

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .kerning(1.3)
                .foregroundStyle(RegaliaTheme.gold.opacity(0.8))
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
