import SwiftUI

struct ProfileDeveloperQuote: View {
    private let quote =
        "Thank you for reading with Craw. Every page you turn helps me keep building this — quietly, carefully, for readers."

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            quoteHeader
            quoteBody

            Divider()
                .background(Theme.Palette.hairlineSoft)

            signatureRow
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.xl)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .crawCardShadow()
    }

    private var quoteHeader: some View {
        HStack(alignment: .top) {
            Text("Founder note")
                .font(Theme.Typography.badge)
                .foregroundStyle(Theme.Palette.rausch)
                .textCase(.uppercase)
                .tracking(0.8)
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.vertical, Theme.Spacing.sm)
                .background(Theme.Palette.rauschTint)
                .clipShape(Capsule())

            Spacer(minLength: Theme.Spacing.base)

            Image(systemName: "quote.opening")
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(Theme.Palette.rausch)
                .accessibilityHidden(true)
        }
    }

    private var quoteBody: some View {
        Text(quote)
            .font(Theme.Typography.bodyMd)
            .foregroundStyle(Theme.Palette.body)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var signatureRow: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image("mike")
                .resizable()
                .scaledToFill()
                .frame(width: 52, height: 52)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.Palette.canvas, lineWidth: 3))
                .crawCardShadow()

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Mike")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("creator of Craw")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
            }

            Spacer()

            Image(systemName: "book.closed.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 38, height: 38)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())
                .accessibilityHidden(true)
        }
    }

    private var cardBackground: some View {
        ZStack(alignment: .topTrailing) {
            Theme.Palette.surfaceCard

            Circle()
                .fill(Theme.Palette.rauschTint)
                .frame(width: 150, height: 150)
                .offset(x: 58, y: -58)
        }
    }
}
