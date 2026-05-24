import SwiftUI

struct OnboardingDotProgress: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == active ? Theme.Palette.rausch : Theme.Palette.hairline)
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: active)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Step \(active + 1) of \(count)")
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.lg) {
        OnboardingDotProgress(count: 6, active: 0)
        OnboardingDotProgress(count: 6, active: 2)
        OnboardingDotProgress(count: 6, active: 5)
    }
    .padding()
}
