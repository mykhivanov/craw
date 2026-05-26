import SwiftData
import SwiftUI

struct AllCurrentlyReadingListView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(filter: BookLibraryReader.inProgressPredicate, sort: BookLibraryReader.defaultSort)
    private var books: [Book]

    let onStart: (Book) -> Void

    @State private var isAddPresented = false

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.sm) {
                ForEach(books) { book in
                    Button {
                        onStart(book)
                        dismiss()
                    } label: {
                        AllCurrentlyReadingRow(book: book)
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    isAddPresented = true
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Theme.Palette.ink)
                            .frame(width: 52, height: 52)
                            .background(
                                Theme.Palette.surfaceStrong,
                                in: RoundedRectangle(cornerRadius: Theme.Radius.button)
                            )
                        Text("Add a book")
                            .font(Theme.Typography.titleMd)
                            .foregroundStyle(Theme.Palette.ink)
                        Spacer(minLength: 0)
                    }
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Palette.surfaceCard)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
                }
                .buttonStyle(.plain)
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.md)
        }
        .background(Theme.Palette.canvas)
        .navigationTitle("Currently reading")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isAddPresented) {
            BookSearchView()
        }
    }
}

private struct AllCurrentlyReadingRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            CoverPlaceholder(coverAssetName: book.coverAssetName, coverImageURL: book.coverImageURL)
                .frame(width: 52, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                Text(book.author)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
                attitudeBadge
            }
            Spacer(minLength: 0)
            Image(systemName: "play.circle.fill")
                .font(.system(size: 26, weight: .regular))
                .foregroundStyle(Theme.Palette.rausch)
        }
        .padding(Theme.Spacing.sm)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var attitudeBadge: some View {
        Text(book.attitude == .study ? "To study" : "For fun")
            .font(Theme.Typography.captionSm)
            .foregroundStyle(Theme.Palette.muted)
            .textCase(.uppercase)
            .padding(.top, 2)
    }
}
