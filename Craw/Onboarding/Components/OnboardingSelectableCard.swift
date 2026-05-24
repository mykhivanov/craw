import SwiftUI

struct OnboardingSelectableCard: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(label)
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Spacer(minLength: Theme.Spacing.sm)
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Theme.Palette.rausch)
                        .font(.system(size: 20))
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        isSelected ? Theme.Palette.rausch : Theme.Palette.hairline,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        OnboardingSelectableCard(label: "You tell me", isSelected: false) {}
        OnboardingSelectableCard(label: "1–6 books", isSelected: true) {}
    }
    .padding()
}
