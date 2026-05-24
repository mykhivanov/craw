import SwiftData
import SwiftUI

struct BookDetailView: View {
    let book: Book

    @Environment(SessionEngine.self) private var engine
    @Query private var quotes: [Quote]
    @Query private var thoughts: [Thought]

    @State private var quotesExpanded = true
    @State private var thoughtsExpanded = true

    init(book: Book) {
        self.book = book
        let bookID = book.id
        _quotes = Query(
            filter: QuotesThoughtsReader.quotesPredicate(for: bookID),
            sort: QuotesThoughtsReader.quoteSortNewestFirst
        )
        _thoughts = Query(
            filter: QuotesThoughtsReader.thoughtsPredicate(for: bookID),
            sort: QuotesThoughtsReader.thoughtSortNewestFirst
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                heroSection
                startCTA
                quotesSection
                thoughtsSection
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Palette.canvas)
        .navigationTitle(book.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        VStack(spacing: Theme.Spacing.base) {
            CoverPlaceholder(coverAssetName: book.coverAssetName, coverImageURL: book.coverImageURL)
                .frame(width: 120, height: 168)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
            VStack(spacing: Theme.Spacing.xxs) {
                Text(book.title)
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                    .multilineTextAlignment(.center)
                Text(book.author)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            progressIndicator
        }
        .frame(maxWidth: .infinity)
    }

    private var progressIndicator: some View {
        HStack(spacing: Theme.Spacing.base) {
            ZStack {
                Circle()
                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 4)
                Circle()
                    .trim(from: 0, to: book.progressFraction)
                    .stroke(Theme.Palette.rausch, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(book.currentPage) / \(book.totalPages) pages")
                    .font(Theme.Typography.titleSm)
                    .foregroundStyle(Theme.Palette.ink)
                Text("\(Int(book.progressFraction * 100))% complete")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            Spacer(minLength: 0)
        }
    }

    private var startCTA: some View {
        Button {
            engine.start(book: book)
        } label: {
            Text("Start reading session")
                .font(Theme.Typography.buttonMd)
                .foregroundStyle(Theme.Palette.canvas)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.Palette.rausch)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
    }

    private var quotesSection: some View {
        DisclosureGroup(isExpanded: $quotesExpanded) {
            if quotes.isEmpty {
                emptyRow("No quotes yet. Capture one during a session.")
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(quotes) { quote in
                        VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                            Text("“\(quote.text)”")
                                .font(Theme.Typography.bodyMd)
                                .foregroundStyle(Theme.Palette.body)
                            if let page = quote.pageNumber {
                                Text("page \(page)")
                                    .font(Theme.Typography.captionSm)
                                    .foregroundStyle(Theme.Palette.mutedSoft)
                            }
                        }
                        .padding(Theme.Spacing.sm)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Palette.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                }
            }
        } label: {
            Text("Quotes (\(quotes.count))")
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
        }
        .tint(Theme.Palette.ink)
    }

    private var thoughtsSection: some View {
        DisclosureGroup(isExpanded: $thoughtsExpanded) {
            if thoughts.isEmpty {
                emptyRow("No thoughts yet. Add one during or after a session.")
            } else {
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    ForEach(thoughts) { thought in
                        Text(thought.text)
                            .font(Theme.Typography.bodyMd)
                            .foregroundStyle(Theme.Palette.body)
                            .padding(Theme.Spacing.sm)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Palette.surfaceSoft)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                    }
                }
            }
        } label: {
            Text("Thoughts (\(thoughts.count))")
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
        }
        .tint(Theme.Palette.ink)
    }

    private func emptyRow(_ text: String) -> some View {
        Text(text)
            .font(Theme.Typography.bodySm)
            .foregroundStyle(Theme.Palette.mutedSoft)
            .padding(Theme.Spacing.sm)
    }
}
