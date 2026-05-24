import SwiftUI

struct OnboardingView: View {
    @Environment(OnboardingState.self) private var state

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Spacer()
                OnboardingDotProgress(count: OnboardingState.stepCount, active: state.stepIndex)
                Spacer()
            }
            .padding(.top, Theme.Spacing.sm)

            currentStep
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.2), value: state.stepIndex)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas.ignoresSafeArea())
    }

    @ViewBuilder
    private var currentStep: some View {
        switch state.stepIndex {
        case 0:
            WelcomeStep(onContinue: state.advance)
        case 1:
            GoalStep(state: state, onContinue: state.advance)
        case 2:
            DailyTimeStep(state: state, onContinue: state.advance)
        case 3:
            HowToReadStep(onContinue: state.advance)
        case 4:
            ScheduleStep(state: state, onContinue: state.advance)
        default:
            YearlyGoalStep(state: state, onContinue: state.complete)
        }
    }
}

#Preview {
    OnboardingView()
        .environment(OnboardingState())
}
