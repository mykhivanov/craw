import SwiftData
import SwiftUI

struct QuotesListView: View {
    @Query(sort: [SortDescriptor(\Quote.capturedAt, order: .reverse)])
    private var quotes: [Quote]

    @Query private var books: [Book]

    var body: some View {
        Group {
            if quotes.isEmpty {
                QuotesEmptyState()
            } else {
                ScrollView {
                    LazyVStack(spacing: Theme.Spacing.md) {
                        QuotesMascotHeader()

                        ForEach(quotes) { quote in
                            QuoteRow(quote: quote, book: bookByID[quote.bookID])
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.base)
                    .padding(.vertical, Theme.Spacing.base)
                }
                .background(Theme.Palette.canvas)
            }
        }
        .navigationTitle("Quotes")
        .navigationBarTitleDisplayMode(.large)
    }

    private var bookByID: [UUID: Book] {
        Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })
    }
}

#Preview("Populated") {
    NavigationStack {
        QuotesListView()
    }
    .modelContainer(CrawModelContainer.previewInMemory())
}
