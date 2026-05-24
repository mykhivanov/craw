import SwiftUI

struct OnboardingStepScaffold<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var buttonTitle: String = "Continue"
    var isButtonEnabled: Bool = true
    let onContinue: () -> Void
    let content: Content

    init(
        eyebrow: String,
        title: String,
        subtitle: String,
        buttonTitle: String = "Continue",
        isButtonEnabled: Bool = true,
        onContinue: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.isButtonEnabled = isButtonEnabled
        self.onContinue = onContinue
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    header
                    content
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Theme.Spacing.lg)
                .padding(.bottom, Theme.Spacing.xl)
            }
            .scrollIndicators(.hidden)

            OnboardingPrimaryButton(
                title: buttonTitle,
                isEnabled: isButtonEnabled,
                action: onContinue
            )
            .padding(.top, Theme.Spacing.base)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            if !eyebrow.isEmpty {
                Text(eyebrow.uppercased())
                .font(Theme.Typography.microLabel)
                .foregroundStyle(Theme.Palette.rausch)
                .tracking(0.6)
            }

            if !title.isEmpty {
                Text(title)
                    .font(Theme.Typography.onboardingHero)
                    .foregroundStyle(Theme.Palette.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.body)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    OnboardingStepScaffold(
        eyebrow: "Step 1",
        title: "Build a reading streak that sticks.",
        subtitle: "A few small choices now create your daily reading plan.",
        onContinue: {}
    ) {
        Text("Preview content")
            .font(Theme.Typography.bodyMd)
    }
    .padding()
}
