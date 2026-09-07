//
//  RegaliaTests.swift
//  RegaliaTests
//
//  Created by Rork on August 28, 2026.
//

import Foundation
import Testing
@testable import Regalia

/// Guards the written content of the prayer library. Every prayer is composed twice —
/// once with a name and once without — because the name slot and the enforced closing
/// are the two places where grammar has broken before.
struct PrayerLibraryTests {

    private static let names = ["Sarah", ""]

    /// Composes every prayer under both name conditions.
    private static func allBodies() -> [(id: String, name: String, body: String)] {
        PrayerLibrary.all.flatMap { prayer in
            names.map { name in
                (prayer.id, name, PrayerLibrary.compose(prayer, name: name).body)
            }
        }
    }

    @Test func everyPrayerEndsWithTheClosing() {
        for entry in Self.allBodies() {
            #expect(
                entry.body.lowercased().hasSuffix("in jesus' name, amen."),
                "\(entry.id) does not close properly (name: \"\(entry.name)\")"
            )
        }
    }

    @Test func theClosingIsCapitalisedAfterAFullStop() {
        for entry in Self.allBodies() {
            #expect(
                !entry.body.contains(". in Jesus' name"),
                "\(entry.id) starts a new sentence with a lowercase \"in\" (name: \"\(entry.name)\")"
            )
            #expect(
                !entry.body.contains(", In Jesus' name"),
                "\(entry.id) capitalises \"In\" mid-sentence (name: \"\(entry.name)\")"
            )
        }
    }

    @Test func theClosingIsNeverDuplicated() {
        for entry in Self.allBodies() {
            let occurrences = entry.body.components(separatedBy: "Jesus' name, Amen.").count - 1
            #expect(occurrences == 1, "\(entry.id) has \(occurrences) closings (name: \"\(entry.name)\")")
        }
    }

    @Test func theNameSlotIsAlwaysResolved() {
        for entry in Self.allBodies() {
            #expect(
                !entry.body.contains(PrayerLibrary.nameToken),
                "\(entry.id) leaked the name token (name: \"\(entry.name)\")"
            )
        }
    }

    @Test func removingTheNameLeavesCleanPunctuation() {
        for entry in Self.allBodies() {
            #expect(!entry.body.contains("  "), "\(entry.id) has a double space (name: \"\(entry.name)\")")
            #expect(!entry.body.contains(" ,"), "\(entry.id) has a floating comma (name: \"\(entry.name)\")")
            #expect(!entry.body.contains(",,"), "\(entry.id) has a doubled comma (name: \"\(entry.name)\")")
            #expect(!entry.body.contains(" ."), "\(entry.id) has a floating full stop (name: \"\(entry.name)\")")
        }
    }

    @Test func theNameIsUsedWhenGiven() {
        let personalised = PrayerLibrary.all.filter { prayer in
            prayer.paragraphs.contains { $0.contains(PrayerLibrary.nameToken) }
        }
        #expect(!personalised.isEmpty, "no prayer uses the name slot any more")

        for prayer in personalised {
            let body = PrayerLibrary.compose(prayer, name: "Sarah").body
            #expect(body.contains(", Sarah,"), "\(prayer.id) does not read the name as an appositive")
        }
    }

    /// The name slot must never be followed by a third-person verb, which is what
    /// produced "mom, come to You this morning" and "mom, confesses that…".
    @Test func theNameSlotIsNeverAVocative() {
        for prayer in PrayerLibrary.all {
            for paragraph in prayer.paragraphs where paragraph.contains(PrayerLibrary.nameToken) {
                #expect(
                    paragraph.contains(", \(PrayerLibrary.nameToken),"),
                    "\(prayer.id) uses the name outside the appositive form"
                )
                #expect(
                    !paragraph.hasPrefix(PrayerLibrary.nameToken),
                    "\(prayer.id) opens a sentence by addressing the person praying"
                )
            }
        }
    }

    @Test func everyPrayerHasATitleAndParagraphs() {
        for prayer in PrayerLibrary.all {
            #expect(!prayer.title.isEmpty, "\(prayer.id) has no title")
            #expect(prayer.paragraphs.count >= 2, "\(prayer.id) is too short")
            #expect(!prayer.tags.isEmpty, "\(prayer.id) has no tags")
        }
    }

    @Test func prayerIdentifiersAreUnique() {
        let ids = PrayerLibrary.all.map(\.id)
        #expect(Set(ids).count == ids.count, "the library has duplicate prayer ids")
    }

    /// The wording should fit anyone praying it.
    @Test func theWordingIsGenderNeutral() {
        let gendered = ["as a man", "a man digs", "common to man", " he could", " his own strength"]
        for prayer in PrayerLibrary.all {
            let body = PrayerLibrary.compose(prayer, name: "Sarah").body
            for phrase in gendered {
                #expect(!body.contains(phrase), "\(prayer.id) contains gendered wording: \"\(phrase)\"")
            }
        }
    }
}
