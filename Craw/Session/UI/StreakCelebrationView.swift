import SwiftUI

struct StreakCelebrationView: View {
    let streakDays: Int
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()
            VStack(spacing: Theme.Spacing.base) {
                Text("\(streakDays)")
                    .font(.system(size: 96, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.Palette.rausch)
                Text("day streak")
                    .font(Theme.Typography.displayLg)
                    .foregroundStyle(Theme.Palette.ink)
            }
            Text("A whole week of reading.\nYou earned this.")
                .font(Theme.Typography.bodyMd)
                .foregroundStyle(Theme.Palette.body)
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: onContinue) {
                Text("Thanks")
                    .font(Theme.Typography.buttonMd)
                    .foregroundStyle(Theme.Palette.canvas)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Theme.Palette.rausch)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
            }
        }
        .padding(Theme.Spacing.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Palette.canvas)
    }
}
