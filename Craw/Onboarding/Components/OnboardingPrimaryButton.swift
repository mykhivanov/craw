import SwiftUI

struct OnboardingPrimaryButton: View {
    let title: String
    var isEnabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(Theme.Typography.buttonMd)

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(Theme.Palette.canvas)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isEnabled ? Theme.Palette.rausch : Theme.Palette.rauschDisabled)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .disabled(!isEnabled)
        .buttonStyle(OnboardingPrimaryButtonStyle())
        .animation(.easeInOut(duration: 0.15), value: isEnabled)
    }
}

private struct OnboardingPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        OnboardingPrimaryButton(title: "Continue") {}
        OnboardingPrimaryButton(title: "Continue", isEnabled: false) {}
    }
    .padding()
}
