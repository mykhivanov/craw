import SwiftUI

struct MascotEmptyTile: View {
    let onAddTapped: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image("mascot")
                .resizable()
                .scaledToFit()
                .frame(height: 160)
                .accessibilityHidden(true)

            VStack(spacing: Theme.Spacing.xs) {
                Text("Your library is empty")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("Add your first book to start building a streak.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .multilineTextAlignment(.center)
            }

            Button(action: onAddTapped) {
                Text("Add a book")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.vertical, Theme.Spacing.sm)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
            .accessibilityLabel("Add your first book")
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Spacing.sm)
        .tileCard()
    }
}

#Preview {
    MascotEmptyTile(onAddTapped: {})
        .padding()
}
