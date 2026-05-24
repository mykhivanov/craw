import SwiftUI

struct YearlyGoalStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Final goal 📚")
                    .font(Theme.Typography.displayLg)
                    .foregroundStyle(Theme.Palette.ink)
                Text("How many books do you want to finish this year?")
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.body)
            }

            VStack(spacing: Theme.Spacing.md) {
                ForEach(YearlyGoal.allCases) { goal in
                    OnboardingSelectableCard(
                        label: goal.label,
                        isSelected: state.yearlyGoal == goal
                    ) {
                        state.yearlyGoal = goal
                    }
                }
            }

            Spacer(minLength: Theme.Spacing.lg)

            OnboardingPrimaryButton(
                title: "Continue",
                isEnabled: state.yearlyGoal != nil,
                action: onContinue
            )
        }
    }
}

#Preview {
    YearlyGoalStep(state: OnboardingState(), onContinue: {})
        .padding()
}
