import SwiftUI

struct QuoteRow: View {
    let quote: Quote
    let book: Book?

    private static let dateFormat: Date.FormatStyle = .dateTime
        .day()
        .month(.abbreviated)
        .year()

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("“\(quote.text)”")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.ink)
                .fixedSize(horizontal: false, vertical: true)

            Text(bookSubtitle)
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)

            HStack(alignment: .center, spacing: Theme.Spacing.sm) {
                Text(quote.capturedAt, format: Self.dateFormat)
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.mutedSoft)
                Spacer(minLength: 0)
                if let page = quote.pageNumber {
                    Text("p. \(page)")
                        .font(Theme.Typography.captionSm)
                        .foregroundStyle(Theme.Palette.muted)
                        .padding(.horizontal, Theme.Spacing.sm)
                        .padding(.vertical, Theme.Spacing.xxs)
                        .background(Theme.Palette.surfaceSoft)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                }
            }
        }
        .tileCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var bookSubtitle: String {
        guard let book else { return "Unknown book" }
        return "\(book.title) — \(book.author)"
    }

    private var accessibilityLabel: String {
        let dateString = quote.capturedAt.formatted(Self.dateFormat)
        let pageString = quote.pageNumber.map { ", page \($0)" } ?? ""
        return "\(quote.text). \(bookSubtitle)\(pageString). Captured \(dateString)."
    }
}

#Preview("With page") {
    let book = Book(
        title: "Atomic Habits",
        author: "James Clear",
        totalPages: 320,
        attitude: .study
    )
    return QuoteRow(
        quote: Quote(
            bookID: book.id,
            text: "You do not rise to the level of your goals. You fall to the level of your systems.",
            pageNumber: 27
        ),
        book: book
    )
    .padding()
}

#Preview("Without page") {
    let book = Book(
        title: "The Hobbit",
        author: "J. R. R. Tolkien",
        totalPages: 310,
        attitude: .entertainment
    )
    return QuoteRow(
        quote: Quote(
            bookID: book.id,
            text: "Not all those who wander are lost."
        ),
        book: book
    )
    .padding()
}

#Preview("Unknown book") {
    QuoteRow(
        quote: Quote(
            bookID: UUID(),
            text: "A book is a dream you hold in your hand.",
            pageNumber: 42
        ),
        book: nil
    )
    .padding()
}
