import SwiftUI

struct ProfileFeedbackSection: View {
    let feedback: String?
    let onLeaveFeedback: () -> Void

    var body: some View {
        if feedback != nil {
            thankYouCard
        } else {
            leaveFeedbackButton
        }
    }

    private var thankYouCard: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "heart.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 28)
            Text("Thank you for your feedback!")
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.base)
        .frame(minHeight: 64)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Palette.rauschTint)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityIdentifier("profile.feedback.thanks")
    }

    private var leaveFeedbackButton: some View {
        Button(action: onLeaveFeedback) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Palette.rausch)
                    .frame(width: 28)
                Text("Leave feedback")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.Palette.mutedSoft)
            }
            .padding(.horizontal, Theme.Spacing.base)
            .frame(minHeight: 56)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("profile.feedback.leave")
    }
}
