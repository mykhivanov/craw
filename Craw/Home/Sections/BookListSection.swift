import SwiftUI

struct BookListSection: View {
    let title: String
    let books: [Book]
    let showsAddButton: Bool
    let onAddTapped: (() -> Void)?
    let emptyContent: (() -> AnyView)?

    init(
        title: String,
        books: [Book],
        showsAddButton: Bool,
        onAddTapped: (() -> Void)? = nil,
        emptyContent: (() -> AnyView)? = nil
    ) {
        self.title = title
        self.books = books
        self.showsAddButton = showsAddButton
        self.onAddTapped = onAddTapped
        self.emptyContent = emptyContent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            header
            if books.isEmpty {
                emptyContent?()
            } else {
                VStack(spacing: Theme.Spacing.sm) {
                    ForEach(books) { book in
                        NavigationLink(value: book) {
                            BookRow(book: book)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text(title)
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
            if showsAddButton {
                Button {
                    onAddTapped?()
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Theme.Palette.ink)
                        .frame(width: 32, height: 32)
                        .background(Theme.Palette.surfaceStrong, in: Circle())
                }
                .accessibilityLabel("Add book")
            }
        }
    }
}

struct BookRow: View {
    let book: Book

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            CoverPlaceholder(coverAssetName: book.coverAssetName)
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
                if book.status != .finished {
                    ProgressBar(progress: book.progressFraction)
                        .frame(height: 4)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
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
}

struct CoverPlaceholder: View {
    let coverAssetName: String?

    var body: some View {
        ZStack {
            Theme.Palette.surfaceStrong
            if let coverAssetName, UIImage(named: coverAssetName) != nil {
                Image(coverAssetName)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "book.closed")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }
        }
    }
}

private struct ProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.Palette.hairlineSoft)
                Capsule()
                    .fill(Theme.Palette.rausch)
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
            }
        }
    }
}
