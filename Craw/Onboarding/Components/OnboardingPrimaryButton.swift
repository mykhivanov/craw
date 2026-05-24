import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.Typography.buttonMd)
                .foregroundStyle(Theme.Palette.canvas)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.base)
                .background(isEnabled ? Theme.Palette.rausch : Theme.Palette.hairline)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(!isEnabled)
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        OnboardingPrimaryButton(title: "Continue") {}
        OnboardingPrimaryButton(title: "Continue", isEnabled: false) {}
    }
    .padding()
}
