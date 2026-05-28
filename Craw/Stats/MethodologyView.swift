import SwiftUI

struct MethodologyView: View {
    let service: ReadingStatsService

    @State private var markdown: String?
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                if let markdown {
                    if let attributed = try? AttributedString(
                        markdown: markdown,
                        options: AttributedString
                            .MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
                    ) {
                        Text(attributed)
                            .font(Theme.Typography.bodyMd)
                            .foregroundStyle(Theme.Palette.body)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text(markdown)
                            .font(Theme.Typography.bodyMd)
                            .foregroundStyle(Theme.Palette.body)
                    }
                } else if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.Typography.bodyMd)
                        .foregroundStyle(Theme.Palette.muted)
                } else {
                    ProgressView()
                        .tint(Theme.Palette.rausch)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Theme.Spacing.xl)
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.canvas)
        .navigationTitle("How we compare you")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await load()
        }
    }

    private func load() async {
        do {
            let doc = try await service.fetchMethodology()
            markdown = doc.markdown
        } catch {
            errorMessage = "Methodology unavailable. Please try again later."
        }
    }
}
