import SwiftUI

struct QuotesMascotHeader: View {
    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            MascotView(mascot: .pigeon)
                .frame(width: 64, height: 64)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text("Keep it up!")
                    .font(Theme.Typography.titleSm)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Every quote you save makes the next session feel a little easier.")
                    .font(Theme.Typography.captionSm)
                    .foregroundStyle(Theme.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .tileCard()
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Keep it up. Every quote you save makes the next session feel a little easier.")
    }
}

#Preview {
    QuotesMascotHeader()
        .padding()
}
