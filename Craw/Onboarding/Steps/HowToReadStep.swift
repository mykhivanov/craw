import SwiftUI

struct HowToReadStep: View {
    let onContinue: () -> Void

    private let principles: [Principle] = [
        .init(
            icon: "iphone.slash",
            title: "Clear the runway",
            subtitle: "Put the phone away before you start. Reading needs fewer interruptions, not more willpower."
        ),
        .init(
            icon: "highlighter",
            title: "Catch the useful ideas",
            subtitle: "Save quotes, thoughts, and moments that feel worth returning to."
        ),
        .init(
            icon: "text.bubble.fill",
            title: "Explain it back",
            subtitle: "A short summary in your own words turns finished pages into remembered ideas."
        )
    ]

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "The Craw method",
            title: "Don’t just finish pages. Keep the signal.",
            subtitle: "Use this simple loop whenever you read: focus, capture, remember.",
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(principles) { principle in
                    principleCard(principle)
                }
            }
        }
    }

    private func principleCard(_ principle: Principle) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: principle.icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 42, height: 42)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(principle.title)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text(principle.subtitle)
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

private struct Principle: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
}

#Preview {
    HowToReadStep(onContinue: {})
        .padding()
}
