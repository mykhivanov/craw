import SwiftUI

struct GoalStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "",
            title: "What should Craw help you change?",
            subtitle: "",
            onContinue: onContinue
        ) {
            VStack(spacing: Theme.Spacing.sm) {
                ForEach(OnboardingGoal.allCases) { goal in
                    OnboardingSelectableCard(
                        icon: goal.icon,
                        title: goal.label,
                        subtitle: goal.subtitle,
                        isSelected: state.selectedGoals.contains(goal)
                    ) {
                        toggle(goal)
                    }
                }
            }
        }
    }

    private func toggle(_ goal: OnboardingGoal) {
        let selected = state.selectedGoals.contains(goal)
        if selected {
            state.selectedGoals.remove(goal)
        } else {
            state.selectedGoals.insert(goal)
        }
    }
}

#Preview {
    GoalStep(state: OnboardingState(), onContinue: {})
        .padding()
}
