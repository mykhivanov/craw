import SwiftUI

struct YearlyGoalStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "Annual target",
            title: "Finish stronger this year.",
            subtitle: "Choose a yearly target. Craw will turn it into a pace that feels actionable week by week.",
            buttonTitle: "Finish setup",
            isButtonEnabled: state.yearlyGoal != nil,
            onContinue: onContinue
        ) {
            VStack(spacing: Theme.Spacing.md) {
                ForEach(YearlyGoal.allCases) { goal in
                    OnboardingSelectableCard(
                        icon: goal.icon,
                        title: goal.label,
                        subtitle: goal.subtitle,
                        isSelected: state.yearlyGoal == goal
                    ) {
                        state.yearlyGoal = goal
                    }
                }
            }
        }
    }
}

#Preview {
    YearlyGoalStep(state: OnboardingState(), onContinue: {})
        .padding()
}
