import SwiftUI

struct StatsBackfillOverlay: View {
    let state: StatsBackfillStore.State

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView(value: progressValue)
                .progressViewStyle(.linear)
                .tint(Theme.Palette.rausch)
                .frame(maxWidth: 220)

            Text("Preparing your stats…")
                .font(Theme.Typography.titleSm)
                .foregroundStyle(Theme.Palette.ink)

            Text("This takes a moment. We're filling in your history.")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
                .multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: 320)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas.opacity(0.85))
    }

    private var progressValue: Double {
        if case let .running(progress) = state {
            return progress
        }
        return 0
    }
}
