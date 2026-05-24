import SwiftUI

struct HowToReadStep: View {
    let onContinue: () -> Void

    private let tips: [String] = [
        "Remove distractions before you start — especially social media.",
        "Don't just finish pages — understand them.",
        "Note if an idea or quote feels important.",
        "Summarize in your own words so you remember what you read.",
        "Pace yourself: take a short break every 20–30 minutes."
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("How to read")
                .font(Theme.Typography.displayLg)
                .foregroundStyle(Theme.Palette.ink)

            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                ForEach(tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: Theme.Spacing.sm) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Theme.Palette.rausch)
                            .padding(.top, 4)
                        Text(tip)
                            .font(Theme.Typography.bodyMd)
                            .foregroundStyle(Theme.Palette.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            Spacer(minLength: Theme.Spacing.lg)

            OnboardingPrimaryButton(title: "Continue", action: onContinue)
        }
    }
}

#Preview {
    HowToReadStep(onContinue: {})
        .padding()
}
