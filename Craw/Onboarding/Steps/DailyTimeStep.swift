import SwiftUI

struct DailyTimeStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    @State private var isPickerPresented: Bool = false

    private static let minMinutes: Int = 5
    private static let maxMinutes: Int = 120
    private static let stepMinutes: Int = 5

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text("Let's rock! 🎸")
                    .font(Theme.Typography.displayLg)
                    .foregroundStyle(Theme.Palette.ink)
                Text("How much time do you want to read per day?")
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.body)
            }

            Button {
                isPickerPresented = true
            } label: {
                Text(Self.format(minutes: state.dailyReadingMinutes))
                    .font(Theme.Typography.displayNumeric)
                    .foregroundStyle(Theme.Palette.ink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.lg)
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card)
                            .stroke(Theme.Palette.hairline, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer(minLength: Theme.Spacing.lg)

            OnboardingPrimaryButton(title: "Continue", action: onContinue)
        }
        .sheet(isPresented: $isPickerPresented) {
            pickerSheet
                .presentationDetents([.height(320)])
        }
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
