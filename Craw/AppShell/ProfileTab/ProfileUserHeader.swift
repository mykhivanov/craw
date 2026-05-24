import ClerkKit
import SwiftUI

struct ProfileUserHeader: View {
    @Environment(Clerk.self) private var clerk

    var body: some View {
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
}
