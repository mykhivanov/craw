import SwiftUI

struct StatTile: View {
    let title: String
    let tile: Tile
    let emptyStateMessage: String
    let isHero: Bool

    init(
        title: String,
        tile: Tile,
        emptyStateMessage: String,
        isHero: Bool = false
    ) {
        self.title = title
        self.tile = tile
        self.emptyStateMessage = emptyStateMessage
        self.isHero = isHero
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(title)
                .font(Theme.Typography.captionSm)
                .foregroundStyle(Theme.Palette.muted)

            if let value = tile.value {
                valueRow(value)
                bottomRow
            } else {
                emptyState
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .contentShape(Rectangle())
    }

    private func valueRow(_ value: Double) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
            Text(formatValue(value))
                .font(isHero ? Theme.Typography.displayLg : Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(tile.unit)
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private var bottomRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            if let trend = tile.trend {
                trendChip(trend)
            }
            if let cohort = tile.cohort {
                percentileBand(cohort)
            }
        }
    }

    @ViewBuilder
    private func trendChip(_ trend: TileTrend) -> some View {
        let isUp = trend.delta >= 0
        let color = isUp ? Theme.Palette.trendUp : Theme.Palette.trendDown
        HStack(spacing: 2) {
            Image(systemName: isUp ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .semibold))
            Text(formatDelta(trend))
                .font(Theme.Typography.badge)
        }
        .foregroundStyle(color)
    }

    private func percentileBand(_ cohort: TileCohort) -> some View {
        Text(percentileLabel(for: cohort.percentile))
            .font(Theme.Typography.badge)
            .foregroundStyle(Theme.Palette.rausch)
            .padding(.horizontal, Theme.Spacing.xs)
            .padding(.vertical, 2)
            .background(Theme.Palette.rauschTint)
            .clipShape(Capsule())
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(emptyStateMessage)
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0, abs(value) < 1000 {
            return String(format: "%.0f", value)
        }
        if abs(value) >= 1000 {
            return Self.integerFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }

    private func formatDelta(_ trend: TileTrend) -> String {
        if let pct = trend.deltaPct {
            return String(format: "%+.0f%%", pct)
        }
        return String(format: "%+.1f", trend.delta)
    }

    private func percentileLabel(for percentile: Int) -> String {
        let topPercent = max(1, 100 - percentile)
        return "Top \(topPercent)%"
    }

    private static let integerFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()
}
