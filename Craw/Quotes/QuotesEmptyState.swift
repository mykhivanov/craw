import SwiftUI

struct QuotesEmptyState: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.base) {
            Spacer(minLength: 0)

            VStack(spacing: Theme.Spacing.md) {
                Image("mascot")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .accessibilityHidden(true)

                VStack(spacing: Theme.Spacing.xs) {
                    Text("No quotes yet")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("Capture a quote during your next reading session and it will land here.")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, Theme.Spacing.lg)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("No quotes yet. Capture a quote during your next reading session and it will land here.")
    }
}

#Preview {
    QuotesEmptyState()
}
