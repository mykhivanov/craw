import SwiftUI

struct GoalStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Pick your goal 📋")
                .font(Theme.Typography.displayLg)
                .foregroundStyle(Theme.Palette.ink)

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(OnboardingGoal.allCases) { goal in
                    goalRow(goal)
                }
            }

            Spacer(minLength: Theme.Spacing.lg)

            OnboardingPrimaryButton(title: "Continue", action: onContinue)
        }
    }

    private func goalRow(_ goal: OnboardingGoal) -> some View {
        let selected = state.selectedGoals.contains(goal)
        return Button {
            if selected {
                state.selectedGoals.remove(goal)
            } else {
                state.selectedGoals.insert(goal)
            }
        } label: {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(selected ? Theme.Palette.rausch : Theme.Palette.mutedSoft)
                Text(goal.label)
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer()
            }
            .padding(.vertical, Theme.Spacing.sm)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    GoalStep(state: OnboardingState(), onContinue: {})
        .padding()
}
