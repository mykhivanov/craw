import SwiftUI

struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "Welcome to Craw",
            title: "Read more. Remember more.",
            subtitle: "Build a simple reading system that keeps you moving, even when motivation drops.",
            buttonTitle: "Start building",
            onContinue: onContinue
        ) {
            VStack(spacing: Theme.Spacing.base) {
                planCard
                founderNote
            }
        }
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.base) {
            Text("Your plan starts here")
                .font(Theme.Typography.displaySm)
                .foregroundStyle(Theme.Palette.ink)

            VStack(spacing: Theme.Spacing.md) {
                benefitRow(
                    icon: "flame.fill",
                    title: "Set the minimum",
                    subtitle: "Choose a daily target you can actually keep."
                )
                benefitRow(
                    icon: "calendar",
                    title: "Protect the time",
                    subtitle: "Pick reading days before your calendar steals them."
                )
                benefitRow(
                    icon: "quote.bubble.fill",
                    title: "Keep the insight",
                    subtitle: "Capture the ideas that make each book worth it."
                )
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var founderNote: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image("mike")
                .resizable()
                .scaledToFill()
                .frame(width: 48, height: 48)
                .clipShape(Circle())
                .overlay(Circle().stroke(Theme.Palette.hairlineSoft, lineWidth: 1))

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Motivation fades. Systems stay.")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)

                Text("I built Craw to help you read consistently and leave every book with something you can remember.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.body)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Mike, creator of Craw")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.muted)
                    .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(.vertical, Theme.Spacing.base)
        .padding(.horizontal, Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 34, height: 34)
                .background(Theme.Palette.canvas)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text(subtitle)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    WelcomeStep(onContinue: {})
        .padding()
}
