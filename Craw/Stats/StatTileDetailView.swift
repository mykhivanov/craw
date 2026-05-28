import SwiftUI

struct StatTileDetailView: View {
    let selection: StatTileSelection
    let tile: Tile
    let trendPoints: [TrendPoint]
    let onMethodologyTap: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                heroValue
                StatsTrendCard(title: "Trend", subtitle: "History", points: trendPoints)
                cohortBlock
                methodologyLink
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.lg)
        }
        .background(Theme.Palette.canvas)
        .navigationTitle(selection.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var heroValue: some View {
        if let value = tile.value {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text(formatValue(value))
                        .font(Theme.Typography.displayHuge)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(tile.unit)
                        .font(Theme.Typography.bodyLg)
                        .foregroundStyle(Theme.Palette.muted)
                }
                if let trend = tile.trend {
                    trendDetail(trend)
                }
            }
        } else {
            Text("Not enough data yet to show this metric.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.muted)
        }
    }

    private func trendDetail(_ trend: TileTrend) -> some View {
        let isUp = trend.delta >= 0
        let label = if let pct = trend.deltaPct {
            String(format: "%@%.1f%% vs prior period", isUp ? "+" : "−", abs(pct))
        } else {
            String(format: "%@%.1f vs prior period", isUp ? "+" : "−", abs(trend.delta))
        }
        return Text(label)
            .font(Theme.Typography.bodySm)
            .foregroundStyle(isUp ? Theme.Palette.trendUp : Theme.Palette.trendDown)
    }

    @ViewBuilder
    private var cohortBlock: some View {
        if let cohort = tile.cohort {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("How you compare")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
                Text("Top \(max(1, 100 - cohort.percentile))% of readers")
                    .font(Theme.Typography.titleSm)
                    .foregroundStyle(Theme.Palette.ink)
                Text(String(format: "Median: %@", formatValue(cohort.median)))
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
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

    private var methodologyLink: some View {
        Button {
            onMethodologyTap()
        } label: {
            HStack(spacing: Theme.Spacing.xs) {
                Text("How we compare you")
                    .font(Theme.Typography.buttonSm)
                    .foregroundStyle(Theme.Palette.muted)
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.Palette.muted)
            }
        }
        .buttonStyle(.plain)
    }

    private func formatValue(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0, abs(value) < 1000 {
            return String(format: "%.0f", value)
        }
        return String(format: "%.1f", value)
    }
}
