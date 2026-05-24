import SwiftUI

struct WelcomeStep: View {
    let onContinue: () -> Void

    private let quoteBody: String = """
    I built this because I struggled with reading too.
    Motivation does not work. Discipline does.

    I knew books could make me sharper, more focused, and more intentional — but I often lost momentum, got distracted, or read without really absorbing much.

    Whether you're building the habit or already read often, this app is here to
    A) help you read consistently
    B) get more from every book.
    """

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Welcome 👋")
                .font(Theme.Typography.displayLg)
                .foregroundStyle(Theme.Palette.ink)

            quoteBlock

            Spacer(minLength: Theme.Spacing.lg)

            OnboardingPrimaryButton(title: "Continue", action: onContinue)
        }
    }

    private var quoteBlock: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                Text("\u{201C}")
                    .font(Theme.Typography.displayHuge)
                    .foregroundStyle(Theme.Palette.rausch)
                    .frame(width: 28, alignment: .topLeading)
                    .offset(y: -8)

                Text(quoteBody)
                    .font(Theme.Typography.bodyMd)
                    .italic()
                    .foregroundStyle(Theme.Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: Theme.Spacing.md) {
                Image("mike")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Theme.Palette.hairline, lineWidth: 1))

                VStack(alignment: .leading, spacing: 0) {
                    Text("Mike")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("creator of Craw")
                        .font(Theme.Typography.captionSm)
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
            .padding(.leading, 40)
        }
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.vertical, Theme.Spacing.base)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    WelcomeStep(onContinue: {})
        .padding()
}
