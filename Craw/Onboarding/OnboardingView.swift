import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(OnboardingState.self) private var state
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack(spacing: Theme.Spacing.base) {
            OnboardingDotProgress(count: OnboardingState.stepCount, active: state.stepIndex)
                .padding(.top, Theme.Spacing.sm)

            currentStep
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .id(state.stepIndex)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, Theme.Spacing.lg)
        .frame(maxWidth: 560, maxHeight: .infinity)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas.ignoresSafeArea())
        .animation(.spring(response: 0.35, dampingFraction: 0.9), value: state.stepIndex)
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
            YearlyGoalStep(state: state, onContinue: completeOnboarding)
        }
    }

    private func completeOnboarding() {
        UserGoalReader.upsert(
            dailyMinutes: state.dailyReadingMinutes,
            yearlyBooks: state.yearlyGoal?.annualBookTarget,
            in: modelContext
        )
        state.complete()
    }
}

#Preview {
    OnboardingView()
        .environment(OnboardingState())
        .environment(NotificationsService.shared)
}
