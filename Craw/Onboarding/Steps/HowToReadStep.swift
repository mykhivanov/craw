import SwiftUI

struct HowToReadStep: View {
    let onContinue: () -> Void

    private let principles: [Principle] = [
        .init(
            icon: "iphone.slash",
            text: "Remove distractions before you start — especially social media."
        ),
        .init(
            icon: "book.closed.fill",
            text: "Don't just finish pages — understand them."
        ),
        .init(
            icon: "quote.bubble.fill",
            text: "Note if an idea or quote feels important."
        ),
        .init(
            icon: "text.bubble.fill",
            text: "Summarize in your own words so you remember what you read."
        ),
        .init(
            icon: "timer",
            text: "Pace yourself: take a short break every 20–30 minutes."
        )
    ]

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "How to read",
            title: "Read with focus, not just speed.",
            subtitle: "A few simple rules make every session easier to start and easier to remember.",
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
                Text(principle.text)
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.body)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
    let text: String
}

#Preview {
    HowToReadStep(onContinue: {})
        .padding()
}
