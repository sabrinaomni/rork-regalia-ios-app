import SwiftUI

/// A prayer body rendered as its true paragraphs with generous spacing and line
/// height, so long-form prayers read comfortably at any text size.
struct PrayerBody: View {
    let text: String
    var fontSize: CGFloat = 17

    private var paragraphs: [String] {
        text.components(separatedBy: "\n\n").filter { !$0.isEmpty }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(paragraphs.enumerated()), id: \.offset) { pair in
                Text(pair.element)
                    .font(.system(size: fontSize, weight: .regular, design: .serif))
                    .lineSpacing(6)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
