import ClerkKit
import SwiftUI

struct ProfileTab: View {
    @Environment(Clerk.self) private var clerk
    @State private var signOutError: String?
    @State private var isSigningOut = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    userHeader
                    signOutSection
                    if let signOutError {
                        Text(signOutError)
                            .font(Theme.Typography.bodySm)
                            .foregroundStyle(Theme.Palette.trendDown)
                            .padding(.horizontal, Theme.Spacing.base)
                    }
                }
                .padding(.horizontal, Theme.Spacing.base)
                .padding(.top, Theme.Spacing.lg)
            }
            .background(Theme.Palette.canvas)
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    @ViewBuilder
    private var userHeader: some View {
        if let user = clerk.user {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(user.firstName ?? "Reader")
                    .font(Theme.Typography.displaySm)
                    .foregroundStyle(Theme.Palette.ink)
                if let email = user.primaryEmailAddress?.emailAddress {
                    Text(email)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var signOutSection: some View {
        Button {
            signOut()
        } label: {
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
            .background(Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .disabled(isSigningOut)
        .accessibilityIdentifier("profile.signOut")
    }

    private func signOut() {
        isSigningOut = true
        signOutError = nil
        Task {
            do {
                try await Clerk.shared.auth.signOut()
            } catch {
                signOutError = "Couldn't sign out. Please try again."
            }
            isSigningOut = false
        }
    }
}
