import SwiftUI

/// Reads a `LegalDocument` inside the app on the Regalia canvas.
///
/// Shipping the text in the binary means the Terms and Privacy Policy are always
/// there for App Review — no browser, no network, no page that can fail to load.
/// A "View on the web" row still points at the published copy.
struct LegalDocumentView: View {
    let document: LegalDocument

    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        NavigationStack {
            ZStack {
                RegaliaBackground(bloomStrength: 0.1)

                ScrollView {
                    VStack(alignment: .leading, spacing: 26) {
                        header

                        ForEach(document.sections) { section in
                            sectionBlock(section)
                        }

                        webRow
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 40)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle(document.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .tint(RegaliaTheme.gold)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(document.title)
                .font(.system(size: 32, weight: .bold, design: .serif))
                .foregroundStyle(RegaliaTheme.gold)
                .fixedSize(horizontal: false, vertical: true)

            Text(document.effectiveDate.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .kerning(2)
                .foregroundStyle(RegaliaTheme.steel)

            Text(document.summary)
                .font(.system(size: 16))
                .foregroundStyle(RegaliaTheme.bone.opacity(0.92))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)

            Rectangle()
                .fill(RegaliaTheme.hairline)
                .frame(height: 1)
                .padding(.top, 6)
        }
    }

    // MARK: - Sections

    private func sectionBlock(_ section: LegalDocument.Section) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(section.heading)
                .font(.system(size: 19, weight: .semibold, design: .serif))
                .foregroundStyle(RegaliaTheme.bone)
                .fixedSize(horizontal: false, vertical: true)

            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .font(.system(size: 15))
                    .foregroundStyle(RegaliaTheme.steelBright)
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Web copy

    @ViewBuilder
    private var webRow: some View {
        if let url = URL(string: document.webURL) {
            Button {
                Haptics.tap()
                openURL(url)
            } label: {
                HStack(spacing: 8) {
                    Text("View on the web")
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(RegaliaTheme.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .regaliaGlass(in: Capsule(), tint: RegaliaTheme.gold)
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the published copy of this document in your browser")
        }
    }
}

#Preview("Terms") {
    LegalDocumentView(document: .terms)
}

#Preview("Privacy") {
    LegalDocumentView(document: .privacy)
}
