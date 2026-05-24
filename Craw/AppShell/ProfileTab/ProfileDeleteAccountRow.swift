import SwiftUI

struct ProfileDeleteAccountRow: View {
    let isDeleting: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("Delete account")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.trendDown)
                Spacer()
                if isDeleting {
                    ProgressView().tint(Theme.Palette.trendDown)
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .frame(height: 56)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
        .disabled(isDeleting)
        .accessibilityIdentifier("profile.deleteAccount")
    }
}
