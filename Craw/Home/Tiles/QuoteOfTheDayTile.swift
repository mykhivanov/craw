import SwiftUI

struct QuoteOfTheDayTile: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Quote of the day")
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
                .textCase(.uppercase)

            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(QuoteOfTheDay.text)
                    .font(Theme.Typography.displaySm.italic())
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(QuoteOfTheDay.attribution)
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }

            Rectangle()
                .fill(Theme.Palette.hairlineSoft)
                .frame(height: 1)

            Text(QuoteOfTheDay.subtitle)
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tileCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Quote of the day. \(QuoteOfTheDay.text) \(QuoteOfTheDay.attribution). \(QuoteOfTheDay.subtitle)"
        )
    }
}

private enum QuoteOfTheDay {
    static let text = "In the end, it’s not the years in your life that count. It’s the life in your years."
    static let attribution = "— Abraham Lincoln"
    static let subtitle = "Remember, you can find quote closer too you in your next book!"
}

#Preview {
    QuoteOfTheDayTile()
        .padding()
}
