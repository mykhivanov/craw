import SwiftUI

struct FinishedSection: View {
    let books: [Book]

    var body: some View {
        if books.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Finished")
                    .font(Theme.Typography.titleSm)
                    .foregroundStyle(Theme.Palette.muted)
                    .textCase(.uppercase)
                    .padding(.horizontal, Theme.Spacing.xxs)

                VStack(spacing: Theme.Spacing.xs) {
                    ForEach(books) { book in
                        FinishedListRow(book: book)
                    }
                }
            }
        }
    }
}

/// Standard button-height row for the Finished section. Tap is a no-op in this change —
/// per spec, the row exists as a visual shelf only. Wrapped as a `Button` so accessibility
/// users still hear it as a button-like element, but with an empty action.
struct FinishedListRow: View {
    let book: Book

    var body: some View {
        Button(action: {}) {
            HStack(spacing: Theme.Spacing.md) {
                Text(book.title)
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                Spacer(minLength: 0)
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.muted)
            }
            .padding(.horizontal, Theme.Spacing.base)
            .frame(height: 48)
            .background(Theme.Palette.surfaceSoft)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(book.title) — finished")
    }
}

struct CoverPlaceholder: View {
    let coverAssetName: String?
    let coverImageURL: URL?

    init(coverAssetName: String?, coverImageURL: URL? = nil) {
        self.coverAssetName = coverAssetName
        self.coverImageURL = coverImageURL
    }

    var body: some View {
        ZStack {
            Theme.Palette.surfaceStrong
            if let coverImageURL {
                AsyncImage(url: coverImageURL) { phase in
                    switch phase {
                    case let .success(image):
                        image.resizable().scaledToFill()
                    default:
                        placeholderGlyph
                    }
                }
            } else if let coverAssetName, UIImage(named: coverAssetName) != nil {
                Image(coverAssetName)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderGlyph
            }
        }
    }

    private var placeholderGlyph: some View {
        Image(systemName: "book.closed")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(Theme.Palette.mutedSoft)
    }
}
