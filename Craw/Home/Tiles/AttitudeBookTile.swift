import SwiftUI

struct AttitudeBookTile: View {
    let label: String
    let book: Book?
    let emptyHeadline: String
    let emptyDescription: String
    let onStart: (Book) -> Void
    let onAddTapped: () -> Void

    var body: some View {
        if let book {
            Button {
                onStart(book)
            } label: {
                tileContent(bookContent(book))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label): \(book.title) by \(book.author). Tap to start a reading session.")
        } else {
            Button {
                onAddTapped()
            } label: {
                tileContent(emptyContent)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(label): \(emptyHeadline). Tap to add a book.")
        }
    }

    private func tileContent(_ content: some View) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(label)
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
                .textCase(.uppercase)

            content
        }
        .tileCard()
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func bookContent(_ book: Book) -> some View {
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
            startActionPill
        }
    }

    private var startActionPill: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "play.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("Start reading")
                .font(Theme.Typography.buttonSm)
        }
        .foregroundStyle(Theme.Palette.canvas)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Palette.rausch)
        .clipShape(Capsule())
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
            Text("Add a book")
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(Theme.Palette.canvas)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.xs)
                .background(Theme.Palette.rausch)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
                .padding(.top, Theme.Spacing.xs)
        }
    }
}
