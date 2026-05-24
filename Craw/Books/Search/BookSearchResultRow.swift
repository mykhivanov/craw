import SwiftUI

struct BookSearchResultRow: View {
    let result: BookSearchResult

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            CoverPlaceholder(coverAssetName: nil, coverImageURL: result.coverImageURL)
                .frame(width: 52, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            VStack(alignment: .leading, spacing: 2) {
                Text(result.title)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(2)
                Text(result.author)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .lineLimit(1)
                Text("\(result.totalPages) pages")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.mutedSoft)
                    .padding(.top, Theme.Spacing.xs)
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
