import SwiftUI

struct WeekStripSection: View {
    let days: [ReadingDay]
    let dailyGoalMinutes: Int

    init(days: [ReadingDay], dailyGoalMinutes: Int = ReadingGoals.dailyMinutes) {
        self.days = days
        self.dailyGoalMinutes = dailyGoalMinutes
    }

    private var entries: [ReadingActivityReader.CalendarWeekDay] {
        ReadingActivityReader.currentSundayFirstWeek(
            from: days,
            dailyGoalMinutes: dailyGoalMinutes
        )
    }

    private var today: Date {
        Calendar.autoupdatingCurrent.startOfDay(for: .now)
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(entries, id: \.date) { entry in
                DayCell(
                    weekdaySymbol: entry.weekdaySymbol,
                    minutesRead: entry.minutesRead,
                    goalMinutes: dailyGoalMinutes,
                    hasMetGoal: entry.hasMetGoal,
                    isToday: entry.date == today
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

struct DayCell: View {
    let weekdaySymbol: String
    let minutesRead: Int
    let goalMinutes: Int
    let hasMetGoal: Bool
    let isToday: Bool

    private var progress: Double {
        guard goalMinutes > 0 else { return 0 }
        return min(1.0, max(0.0, Double(minutesRead) / Double(goalMinutes)))
    }

    private var trackColor: Color {
        isToday ? Theme.Palette.rausch.opacity(0.18) : Theme.Palette.hairlineSoft
    }

    private var fillColor: Color {
        if hasMetGoal {
            return isToday ? Theme.Palette.rausch : Theme.Palette.ink
        }
        return Theme.Palette.mutedSoft
    }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            ZStack {
                Circle()
                    .stroke(trackColor, lineWidth: 3)
                if progress > 0 {
                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(fillColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
                if isToday {
                    Circle()
                        .stroke(Theme.Palette.rausch, lineWidth: 1)
                        .padding(-3)
                }
            }
            .frame(width: 36, height: 36)

            Text(weekdaySymbol)
                .font(isToday ? Theme.Typography.microLabel : Theme.Typography.captionSm)
                .foregroundStyle(isToday ? Theme.Palette.ink : Theme.Palette.muted)
        }
    }
}

#Preview("Sparse week (2 of 7)") {
    let calendar = Calendar.autoupdatingCurrent
    let today = calendar.startOfDay(for: .now)
    let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
    let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: today)!
    return WeekStripSection(days: [
        ReadingDay(date: twoDaysAgo, minutesRead: 25),
        ReadingDay(date: fiveDaysAgo, minutesRead: 45)
    ])
    .padding()
}
