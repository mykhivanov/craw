import SwiftUI

struct ScheduleStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    @State private var pickerDate: Date = ScheduleStep.defaultDate()

    private static let orderedDays: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("Let's schedule reading 📅")
                .font(Theme.Typography.displayLg)
                .foregroundStyle(Theme.Palette.ink)

            weekdaysRow

            HStack {
                Text("Remind me at")
                    .font(Theme.Typography.bodyMd)
                    .foregroundStyle(Theme.Palette.body)
                Spacer()
                DatePicker(
                    "",
                    selection: $pickerDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .onChange(of: pickerDate) { _, newValue in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                    state.reminderTime = comps
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.md)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .stroke(Theme.Palette.hairline, lineWidth: 1)
            )

            Spacer(minLength: Theme.Spacing.lg)

            OnboardingPrimaryButton(title: "Continue", action: onContinue)
        }
        .onAppear {
            pickerDate = ScheduleStep.dateFromComponents(state.reminderTime)
        }
    }

    private var weekdaysRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            ForEach(Self.orderedDays) { day in
                weekdayChip(day)
            }
        }
    }

    private func weekdayChip(_ day: Weekday) -> some View {
        let selected = state.readingWeekdays.contains(day)
        return Button {
            if selected {
                state.readingWeekdays.remove(day)
            } else {
                state.readingWeekdays.insert(day)
            }
        } label: {
            Text(day.shortLabel)
                .font(Theme.Typography.titleMd)
                .foregroundStyle(selected ? Theme.Palette.canvas : Theme.Palette.body)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(selected ? Theme.Palette.rausch : Theme.Palette.surfaceSoft)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private static func defaultDate() -> Date {
        dateFromComponents(DateComponents(hour: 8, minute: 0))
    }

    private static func dateFromComponents(_ components: DateComponents) -> Date {
        let now = Date()
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: now)
        comps.hour = components.hour ?? 8
        comps.minute = components.minute ?? 0
        return Calendar.current.date(from: comps) ?? now
    }
}

#Preview {
    ScheduleStep(state: OnboardingState(), onContinue: {})
        .padding()
}
