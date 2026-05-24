import SwiftUI

struct LiveCounterTile: View {
    let provider: LiveCounterProvider

    init(provider: LiveCounterProvider = CommunityActivityCounter()) {
        self.provider = provider
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 10)) { context in
            let value = provider.currentValue(at: context.date)
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("People reading now")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                    Text(value.formatted())
                        .font(Theme.Typography.displaySm)
                        .foregroundStyle(Theme.Palette.ink)
                        .contentTransition(.numericText(value: Double(value)))
                    Text("readers")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
            .tileCard()
            .accessibilityElement(children: .combine)
            .accessibilityLabel("People reading now")
            .accessibilityValue("\(value)")
            .accessibilityAddTraits(.updatesFrequently)
        }
    }
}

#Preview {
    LiveCounterTile()
        .padding()
}
