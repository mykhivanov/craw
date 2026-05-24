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
    @State private var showRemindersPrompt: Bool = false

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
            title: "",
            subtitle: "",
            onContinue: handleContinueTapped
        ) {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                actionsRow
                if showDeniedNote {
                    deniedNote
                }
                daysCard
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
        .confirmationDialog(
            "Enable reading reminders?",
            isPresented: $showRemindersPrompt,
            titleVisibility: .visible
        ) {
            Button("Enable reminders") {
                Task { @MainActor in
                    await handleReminderToggle(newValue: true)
                    onContinue()
                }
            }
            Button("Not now", role: .cancel) {
                onContinue()
            }
        } message: {
            Text("Craw can nudge you on your reading days. You can change this anytime in Settings.")
        }
    }

    private func handleContinueTapped() {
        if !state.wantsReminders, state.reminderAuthorizationStatus == .notDetermined {
            showRemindersPrompt = true
        } else {
            onContinue()
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

    private var actionsRow: some View {
        HStack(spacing: Theme.Spacing.sm) {
            reminderToggleCompact
            reminderTimeCompact
        }
    }

    private var reminderToggleCompact: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(spacing: Theme.Spacing.xs) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.Palette.rausch)
                Text("Reminders")
                    .font(Theme.Typography.titleMd)
                    .foregroundStyle(Theme.Palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }

            HStack {
                Spacer()
                Toggle("", isOn: reminderToggleBinding)
                    .labelsHidden()
                    .tint(Theme.Palette.rausch)
            }
        }
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.vertical, Theme.Spacing.sm)
        .frame(maxWidth: .infinity, minHeight: 92)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Reminders")
    }

    private var reminderTimeCompact: some View {
        Button {
            pickerDate = ScheduleStep.dateFromComponents(state.reminderTime)
            isPickerPresented = true
        } label: {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.Palette.rausch)
                    Text("Reminder time")
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                HStack(spacing: Theme.Spacing.xs) {
                    Text(Self.formatReminderTime(state.reminderTime))
                        .font(Theme.Typography.titleMd)
                        .foregroundStyle(Theme.Palette.ink)
                        .lineLimit(1)
                    Spacer(minLength: Theme.Spacing.xs)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.Palette.muted)
                }
            }
            .padding(.horizontal, Theme.Spacing.base)
            .padding(.vertical, Theme.Spacing.sm)
            .frame(maxWidth: .infinity, minHeight: 92)
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

    private var deniedNote: some View {
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
        .padding(.horizontal, Theme.Spacing.base)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Palette.surfaceCard)
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .stroke(Theme.Palette.hairlineSoft, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card))
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
                Text(day.label)
                    .font(Theme.Typography.titleSm)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

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
