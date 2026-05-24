import SwiftUI

struct OnboardingSelectableCard: View {
    let icon: String
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let action: () -> Void

    init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    init(label: String, isSelected: Bool, action: @escaping () -> Void) {
        self.init(
            icon: "checkmark.seal",
            title: label,
            isSelected: isSelected,
            action: action
        )
    }

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: Theme.Spacing.md) {
                iconView

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                        .fixedSize(horizontal: false, vertical: true)

                    if let subtitle {
                        Text(subtitle)
                            .font(Theme.Typography.bodySm)
                            .foregroundStyle(Theme.Palette.muted)
                            .lineSpacing(1)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer(minLength: Theme.Spacing.sm)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 21, weight: .semibold))
                    .foregroundStyle(isSelected ? Theme.Palette.rausch : Theme.Palette.hairline)
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.base)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? Theme.Palette.rauschTint : Theme.Palette.surfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(
                        isSelected ? Theme.Palette.rausch : Theme.Palette.hairlineSoft,
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var accessibilityLabel: String {
        if let subtitle {
            return "\(title), \(subtitle)"
        }
        return title
    }

    private var iconView: some View {
        Image(systemName: icon)
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(isSelected ? Theme.Palette.rausch : Theme.Palette.ink)
            .frame(width: 42, height: 42)
            .background(isSelected ? Theme.Palette.canvas : Theme.Palette.surfaceSoft)
            .clipShape(Circle())
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        OnboardingSelectableCard(
            icon: "flame.fill",
            title: "Build the habit",
            subtitle: "Small daily wins that compound.",
            isSelected: false
        ) {}
        OnboardingSelectableCard(
            icon: "target",
            title: "Finish 12 books",
            subtitle: "A clear target for the year.",
            isSelected: true
        ) {}
    }
    .padding()
}
