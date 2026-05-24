import SwiftUI

struct OnboardingDotProgress: View {
    let count: Int
    let active: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.base) {
            Text("Step \(active + 1) of \(count)")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.muted)

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Theme.Palette.surfaceStrong)

                    Capsule()
                        .fill(Theme.Palette.rausch)
                        .frame(width: progressWidth(in: proxy.size.width))
                }
            }
            .frame(height: 6)
        }
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.vertical, Theme.Spacing.md)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(Capsule())
        .accessibilityElement()
        .accessibilityLabel("Step \(active + 1) of \(count)")
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: active)
    }

    private func progressWidth(in width: CGFloat) -> CGFloat {
        let safeCount = max(count, 1)
        return width * CGFloat(active + 1) / CGFloat(safeCount)
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
