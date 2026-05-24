import SwiftUI

struct ScheduleStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    @State private var pickerDate: Date = ScheduleStep.defaultDate()

    private static let orderedDays: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "Reading schedule",
            title: "Lock in the days before the week gets noisy.",
            subtitle: "Choose when Craw should expect you. Consistency gets easier when the decision is already made.",
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.base) {
                daysCard
                reminderCard
            }
        }
        .onAppear {
            pickerDate = ScheduleStep.dateFromComponents(state.reminderTime)
        }
    }

    private var daysCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.base) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Reading days")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("\(state.readingWeekdays.count) selected")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Spacer()
                Image(systemName: "calendar.badge.checkmark")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Palette.rausch)
            }

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Self.orderedDays) { day in
                    weekdayChip(day)
                }
            }
        }
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var reminderCard: some View {
        HStack(spacing: Theme.Spacing.base) {
            Image(systemName: "bell.fill")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Theme.Palette.rausch)
                .frame(width: 42, height: 42)
                .background(Theme.Palette.rauschTint)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text("Reminder time")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("A small nudge before the day takes over.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }

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
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
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
                .frame(height: 44)
                .background(selected ? Theme.Palette.rausch : Theme.Palette.surfaceSoft)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.label)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
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
