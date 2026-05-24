import SwiftUI

struct ProfileDeveloperQuote: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(
                "\"Thank you for reading with Craw. Every page you turn helps me keep building this — quietly, carefully, for readers.\""
            )
            .font(Theme.Typography.bodyMd.italic())
            .foregroundStyle(Theme.Palette.body)
            .fixedSize(horizontal: false, vertical: true)
            Text("— Misha")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
        }
        .padding(Theme.Spacing.base)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}
