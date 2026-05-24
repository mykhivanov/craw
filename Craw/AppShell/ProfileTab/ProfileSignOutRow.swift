import SwiftUI

struct ProfileSignOutRow: View {
    let isSigningOut: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text("Sign out")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.trendDown)
                Spacer()
                if isSigningOut {
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
        .disabled(isSigningOut)
        .accessibilityIdentifier("profile.signOut")
    }
}
