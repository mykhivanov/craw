import SwiftUI

struct DailyTimeStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    @State private var isPickerPresented: Bool = false

    private static let minMinutes: Int = 5
    private static let maxMinutes: Int = 120
    private static let stepMinutes: Int = 5
    private static let quickPicks: [Int] = [10, 15, 20, 30]

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "Daily minimum",
            title: "Choose a target you can win today.",
            subtitle: "",
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.base) {
                timeCard
                quickPickRow
                coachNote
            }
        }
        .sheet(isPresented: $isPickerPresented) {
            pickerSheet
                .presentationDetents([.height(320)])
        }
    }

    private var timeCard: some View {
        HStack(spacing: Theme.Spacing.base) {
            minuteButton(systemName: "minus") {
                adjustMinutes(by: -Self.stepMinutes)
            }

            timeValueButton

            minuteButton(systemName: "plus") {
                adjustMinutes(by: Self.stepMinutes)
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var timeValueButton: some View {
        Button {
            isPickerPresented = true
        } label: {
            VStack(spacing: Theme.Spacing.xs) {
                Text(Self.format(minutes: state.dailyReadingMinutes))
                    .font(Theme.Typography.displayNumeric)
                    .foregroundStyle(Theme.Palette.ink)
                Text("per reading day")
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Palette.muted)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the full minutes picker")
    }

    private var quickPickRow: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Popular starting points")
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Palette.muted)

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Self.quickPicks, id: \.self) { minutes in
                    quickPick(minutes)
                }
            }
        }
    }

    private var coachNote: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 34, height: 34)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Coach tip")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("If you can do more, great. The real win is protecting the minimum when life gets messy.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private func minuteButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Theme.Palette.ink)
                .frame(width: 48, height: 48)
                .background(Theme.Palette.canvas)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func quickPick(_ minutes: Int) -> some View {
        let selected = state.dailyReadingMinutes == minutes
        return Button {
            state.dailyReadingMinutes = minutes
        } label: {
            Text(Self.format(minutes: minutes))
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(selected ? Theme.Palette.canvas : Theme.Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .background(selected ? Theme.Palette.rausch : Theme.Palette.surfaceSoft)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func adjustMinutes(by delta: Int) {
        let next = state.dailyReadingMinutes + delta
        state.dailyReadingMinutes = min(Self.maxMinutes, max(Self.minMinutes, next))
    }

    private var pickerSheet: some View {
        VStack(spacing: Theme.Spacing.base) {
            Text("Minutes per day")
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
                .padding(.top, Theme.Spacing.lg)

            Picker("Minutes", selection: $state.dailyReadingMinutes) {
                ForEach(
                    Array(stride(from: Self.minMinutes, through: Self.maxMinutes, by: Self.stepMinutes)),
                    id: \.self
                ) { mins in
                    Text(Self.format(minutes: mins)).tag(mins)
                }
            }
            .pickerStyle(.wheel)
            .frame(maxHeight: 180)

            OnboardingPrimaryButton(title: "Done") {
                isPickerPresented = false
            }
            .padding(.horizontal, Theme.Spacing.base)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    static func format(minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes) min"
        }
        let hours = minutes / 60
        let rest = minutes % 60
        if rest == 0 {
            return "\(hours)h"
        }
        return "\(hours)h \(rest)m"
    }
}

#Preview {
    DailyTimeStep(state: OnboardingState(), onContinue: {})
        .padding()
}
