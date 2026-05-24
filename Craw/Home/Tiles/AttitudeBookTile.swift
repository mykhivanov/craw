import SwiftUI

struct AttitudeBookTile: View {
    let label: String
    let book: Book?
    let emptyHeadline: String
    let emptyDescription: String
    let onAddTapped: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
                .textCase(.uppercase)

            if let book {
                bookBody(book)
            } else {
                emptyContent
            }
        }
        .tileCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    private func bookBody(_ book: Book) -> some View {
        NavigationLink(value: book) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                CoverPlaceholder(coverAssetName: book.coverAssetName, coverImageURL: book.coverImageURL)
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    Text(book.author)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                        .lineLimit(1)
                }
                AttitudeTileProgressBar(progress: book.progressFraction)
                    .frame(height: 4)
            }
        }
        .buttonStyle(.plain)
    }

    private var emptyContent: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(emptyHeadline)
                .font(Theme.Typography.titleSm)
                .foregroundStyle(Theme.Palette.ink)
                .multilineTextAlignment(.leading)
            Text(emptyDescription)
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
                .multilineTextAlignment(.leading)
            Button {
                onAddTapped()
            } label: {
                Text("Add a book")
                    .font(Theme.Typography.buttonSm)
                    .foregroundStyle(Theme.Palette.canvas)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.vertical, Theme.Spacing.xs)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .padding(.top, Theme.Spacing.xs)
        }
    }

    private var accessibilityDescription: String {
        if let book {
            let percent = Int((book.progressFraction * 100).rounded())
            return "\(label): \(book.title) by \(book.author), \(percent)% read"
        }
        return "\(label): \(emptyHeadline)"
    }
}

private struct AttitudeTileProgressBar: View {
    let progress: Double

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Palette.hairlineSoft)
                Capsule()
                    .fill(Theme.Palette.rausch)
                    .frame(width: proxy.size.width * max(0, min(1, progress)))
            }
        }
    }
}
