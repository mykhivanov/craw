import SwiftUI
import UIKit
import UserNotifications

struct ScheduleStep: View {
    @Bindable var state: OnboardingState
    let onContinue: () -> Void

    @Environment(NotificationsService.self) private var notifications

    @State private var isPickerPresented: Bool = false
    @State private var pickerDate: Date = ScheduleStep.defaultDate()
    @State private var showDeniedNote: Bool = false

    private static let orderedDays: [Weekday] = [
        .monday, .tuesday, .wednesday, .thursday, .friday, .saturday, .sunday
    ]
    private static let columns: [GridItem] = [
        GridItem(.flexible(), spacing: Theme.Spacing.sm),
        GridItem(.flexible(), spacing: Theme.Spacing.sm)
    ]
    private static let dayPresets: [DayPreset] = [
        .init(title: "Weekdays", days: Weekday.weekdays),
        .init(title: "Every day", days: Set(Weekday.allCases)),
        .init(title: "Weekend", days: [.saturday, .sunday])
    ]

    var body: some View {
        OnboardingStepScaffold(
            eyebrow: "Reading schedule",
            title: "Choose your reading days.",
            subtitle: "Tap the days you want to read. Then set one reminder time.",
            onContinue: onContinue
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                daysCard
                reminderCard
                reminderToggleCard
            }
        }
        .onAppear {
            pickerDate = ScheduleStep.dateFromComponents(state.reminderTime)
        }
        .task {
            await notifications.refreshAuthorizationStatus()
            state.reminderAuthorizationStatus = notifications.authorizationStatus
            showDeniedNote = state.wantsReminders && notifications.authorizationStatus == .denied
        }
        .onChange(of: state.readingWeekdays) {
            rescheduleIfActive()
        }
        .onChange(of: state.reminderTime) {
            rescheduleIfActive()
        }
        .sheet(isPresented: $isPickerPresented) {
            pickerSheet
                .presentationDetents([.height(360), .medium])
        }
    }

    private var reminderToggleBinding: Binding<Bool> {
        Binding(
            get: { state.wantsReminders },
            set: { newValue in
                Task { @MainActor in await handleReminderToggle(newValue: newValue) }
            }
        )
    }

    private var reminderToggleCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .top, spacing: Theme.Spacing.base) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Theme.Palette.rausch)
                    .frame(width: 44, height: 44)
                    .background(Theme.Palette.rauschTint)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Turn on reminders")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text("We'll send a gentle nudge at this time so a missed day doesn't become a missed week.")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: Theme.Spacing.sm)

                Toggle("", isOn: reminderToggleBinding)
                    .labelsHidden()
                    .tint(Theme.Palette.rausch)
            }

            if showDeniedNote {
                HStack(spacing: Theme.Spacing.sm) {
                    Text("Notifications are off. Enable them in Settings.")
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                    Spacer(minLength: Theme.Spacing.sm)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(Theme.Typography.buttonSm)
                    .foregroundStyle(Theme.Palette.rausch)
                }
                .padding(.top, Theme.Spacing.xs)
            }
        }
        .padding(Theme.Spacing.base)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .contain)
    }

    private func handleReminderToggle(newValue: Bool) async {
        if newValue {
            let status = await notifications.requestAuthorization()
            state.reminderAuthorizationStatus = status
            switch status {
            case .authorized, .provisional, .ephemeral:
                state.wantsReminders = true
                showDeniedNote = false
                notifications.registerForRemoteNotifications()
                await notifications.scheduleDailyReminders(
                    weekdays: state.readingWeekdays,
                    time: state.reminderTime
                )
            default:
                state.wantsReminders = false
                showDeniedNote = true
            }
        } else {
            state.wantsReminders = false
            showDeniedNote = false
            await notifications.clearScheduledReminders()
        }
    }

    private func rescheduleIfActive() {
        guard state.wantsReminders else { return }
        Task {
            await notifications.scheduleDailyReminders(
                weekdays: state.readingWeekdays,
                time: state.reminderTime
            )
        }
    }

    private var daysCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Reading days")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                    Text(selectedDaysSummary)
                        .font(Theme.Typography.bodySm)
                        .foregroundStyle(Theme.Palette.muted)
                }
                Spacer()
            }

            quickPresetRow

            LazyVGrid(columns: Self.columns, spacing: Theme.Spacing.sm) {
                ForEach(Self.orderedDays) { day in
                    weekdayChip(day)
                }
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
    }

    private var reminderCard: some View {
        Button {
            pickerDate = ScheduleStep.dateFromComponents(state.reminderTime)
            isPickerPresented = true
        } label: {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Theme.Spacing.base) {
                    reminderIcon
                    reminderText
                    Spacer(minLength: Theme.Spacing.sm)
                    reminderTimePill
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    HStack(alignment: .top, spacing: Theme.Spacing.base) {
                        reminderIcon
                        reminderText
                    }
                    reminderTimePill
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
        .buttonStyle(.plain)
        .accessibilityLabel("Reminder time")
        .accessibilityValue(Self.formatReminderTime(state.reminderTime))
        .accessibilityHint("Opens the time picker")
    }

    private var quickPresetRow: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(Self.dayPresets) { preset in
                    presetButton(preset)
                }
            }

            VStack(spacing: Theme.Spacing.sm) {
                ForEach(Self.dayPresets) { preset in
                    presetButton(preset)
                }
            }
        }
    }

    private var reminderIcon: some View {
        Image(systemName: "bell.fill")
            .font(.system(size: 17, weight: .semibold))
            .foregroundStyle(Theme.Palette.rausch)
            .frame(width: 44, height: 44)
            .background(Theme.Palette.rauschTint)
            .clipShape(Circle())
    }

    private var reminderText: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Reminder time")
                .font(Theme.Typography.titleMd)
                .foregroundStyle(Theme.Palette.ink)
            Text("We'll nudge you on selected days.")
                .font(Theme.Typography.bodySm)
                .foregroundStyle(Theme.Palette.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var reminderTimePill: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Text(Self.formatReminderTime(state.reminderTime))
                .font(Theme.Typography.buttonMd)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundStyle(Theme.Palette.ink)
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Palette.surfaceSoft)
        .clipShape(Capsule())
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
            HStack(spacing: Theme.Spacing.sm) {
                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                    Text(Self.shortName(for: day))
                        .font(Theme.Typography.titleMd)
                    Text(day.label)
                        .font(Theme.Typography.captionSm)
                        .opacity(0.72)
                }

                Spacer()

                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundStyle(selected ? Theme.Palette.canvas : Theme.Palette.ink)
            .padding(.horizontal, Theme.Spacing.md)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 58)
            .background(selected ? Theme.Palette.rausch : Theme.Palette.surfaceSoft)
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.button)
                    .stroke(selected ? Theme.Palette.rausch : Theme.Palette.hairlineSoft, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.label)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
        .animation(.easeInOut(duration: 0.15), value: selected)
    }

    private func presetButton(_ preset: DayPreset) -> some View {
        let selected = state.readingWeekdays == preset.days
        return Button {
            state.readingWeekdays = preset.days
        } label: {
            Text(preset.title)
                .font(Theme.Typography.buttonSm)
                .foregroundStyle(selected ? Theme.Palette.canvas : Theme.Palette.ink)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.sm)
                .background(selected ? Theme.Palette.ink : Theme.Palette.surfaceSoft)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityValue(selected ? "Selected" : "Not selected")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var pickerSheet: some View {
        VStack(spacing: Theme.Spacing.base) {
            VStack(spacing: Theme.Spacing.xs) {
                Text("Set reminder time")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                Text("This applies to the reading days you selected.")
                    .font(Theme.Typography.bodySm)
                    .foregroundStyle(Theme.Palette.muted)
            }
            .padding(.top, Theme.Spacing.lg)

            DatePicker(
                "Reminder time",
                selection: $pickerDate,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.wheel)
            .labelsHidden()
            .frame(maxHeight: 180)
            .onChange(of: pickerDate) { _, newValue in
                state.reminderTime = Calendar.current.dateComponents([.hour, .minute], from: newValue)
            }

            OnboardingPrimaryButton(title: "Done") {
                isPickerPresented = false
            }
            .padding(.horizontal, Theme.Spacing.base)
        }
        .padding(.bottom, Theme.Spacing.lg)
    }

    private var selectedDaysSummary: String {
        if state.readingWeekdays == Weekday.weekdays {
            return "Weekdays selected"
        }
        if state.readingWeekdays.count == Weekday.allCases.count {
            return "Every day selected"
        }
        if state.readingWeekdays == Set<Weekday>([.saturday, .sunday]) {
            return "Weekend selected"
        }
        if state.readingWeekdays.isEmpty {
            return "No days selected"
        }
        return "\(state.readingWeekdays.count) days selected"
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

    private static func shortName(for day: Weekday) -> String {
        switch day {
        case .monday: "Mon"
        case .tuesday: "Tue"
        case .wednesday: "Wed"
        case .thursday: "Thu"
        case .friday: "Fri"
        case .saturday: "Sat"
        case .sunday: "Sun"
        }
    }

    private static func formatReminderTime(_ components: DateComponents) -> String {
        let date = dateFromComponents(components)
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

private struct DayPreset: Identifiable {
    let title: String
    let days: Set<Weekday>

    var id: String {
        title
    }
}

#Preview {
    ScheduleStep(state: OnboardingState(), onContinue: {})
        .padding()
        .environment(NotificationsService.shared)
}
