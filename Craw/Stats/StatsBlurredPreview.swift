import SwiftUI

/// Hero-row preview shown above the paywall CTA for non-subscribers.
/// Renders three tile-shaped cards with placeholder copy and a blur applied so the
/// numbers feel teased but unreadable. Issues no network request and reveals no real
/// numbers — pure visual upsell.
struct StatsBlurredPreview: View {
    private let columns = [
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md),
        GridItem(.flexible(), spacing: Theme.Spacing.md)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text("A peek at your stats")
                    .font(Theme.Typography.captionSm)
            }
            .foregroundStyle(Theme.Palette.muted)

            LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.md) {
                blurredTile(title: "Focus difficulty", primary: "2.4", unit: "/ 5")
                blurredTile(title: "Goal hit rate", primary: "82", unit: "%")
                blurredTile(title: "Comprehension", primary: "78", unit: "%")
            }
            .blur(radius: 6)
            .overlay(
                LinearGradient(
                    colors: [Theme.Palette.canvas.opacity(0), Theme.Palette.canvas.opacity(0.6)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .allowsHitTesting(false)
        }
    }

    private func blurredTile(title: String, primary: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)
            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text(primary)
                    .font(Theme.Typography.displayLg)
                    .foregroundStyle(Theme.Palette.ink)
                Text(unit)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            Text("Top —%")
                .font(Theme.Typography.badge)
                .foregroundStyle(Theme.Palette.rausch)
                .padding(.horizontal, Theme.Spacing.xs)
                .padding(.vertical, 2)
                .background(Theme.Palette.rauschTint)
                .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
