import Foundation

enum ReadingActivityReader {
    struct DayMetrics: Equatable {
        let date: Date
        let minutesRead: Int
    }

    enum MinutesDeltaKind: Equatable {
        case unchangedZero
        case increaseFromZero
        case percentChange(Double)
    }

    struct MinutesDelta: Equatable {
        let todayMinutes: Int
        let kind: MinutesDeltaKind
    }

    struct CalendarWeekDay: Equatable {
        let date: Date
        let weekdaySymbol: String
        let minutesRead: Int
        let hasMetGoal: Bool
        let isToday: Bool
    }

    static func today(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> DayMetrics {
        let key = calendar.startOfDay(for: now)
        let row = days.first { $0.date == key }
        return DayMetrics(
            date: key,
            minutesRead: row?.minutesRead ?? 0
        )
    }

    static func lastSevenDays(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [DayMetrics] {
        let today = calendar.startOfDay(for: now)
        return (0..<7).reversed().compactMap { offset -> DayMetrics? in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else {
                return nil
            }
            let row = days.first { $0.date == date }
            return DayMetrics(
                date: date,
                minutesRead: row?.minutesRead ?? 0
            )
        }
    }

    static func minutesDeltaVsYesterday(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> MinutesDelta {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let todayMinutes = days.first(where: { $0.date == today })?.minutesRead ?? 0
        let yesterdayMinutes = days.first(where: { $0.date == yesterday })?.minutesRead ?? 0

        if yesterdayMinutes == 0, todayMinutes == 0 {
            return MinutesDelta(todayMinutes: 0, kind: .unchangedZero)
        }
        if yesterdayMinutes == 0 {
            return MinutesDelta(todayMinutes: todayMinutes, kind: .increaseFromZero)
        }
        let pct = (Double(todayMinutes - yesterdayMinutes) / Double(yesterdayMinutes)) * 100.0
        return MinutesDelta(todayMinutes: todayMinutes, kind: .percentChange(pct))
    }

    static func currentStreak(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        dailyGoalMinutes: Int = ReadingGoals.dailyMinutes
    ) -> Int {
        guard dailyGoalMinutes > 0 else { return 0 }
        let today = calendar.startOfDay(for: now)
        let todayRow = days.first(where: { $0.date == today })
        let anchor: Date = if let todayRow, todayRow.minutesRead >= dailyGoalMinutes {
            today
        } else {
            calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        var streak = 0
        var cursor = anchor
        while true {
            guard let row = days.first(where: { $0.date == cursor }),
                  row.minutesRead >= dailyGoalMinutes
            else {
                break
            }
            streak += 1
            guard let next = calendar.date(byAdding: .day, value: -1, to: cursor) else {
                break
            }
            cursor = next
        }
        return streak
    }

    static func currentCalendarWeek(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        dailyGoalMinutes: Int = ReadingGoals.dailyMinutes
    ) -> [CalendarWeekDay] {
        currentSundayFirstWeek(
            from: days,
            now: now,
            calendar: calendar,
            dailyGoalMinutes: dailyGoalMinutes
        )
    }

    static func currentSundayFirstWeek(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent,
        dailyGoalMinutes: Int = ReadingGoals.dailyMinutes
    ) -> [CalendarWeekDay] {
        let today = calendar.startOfDay(for: now)
        let weekStart = sundayStartOfWeek(for: today, calendar: calendar)
        let symbols = calendar.shortWeekdaySymbols

        return (0..<7).compactMap { offset -> CalendarWeekDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }
            let rawIdx = calendar.component(.weekday, from: date) - 1
            let weekdayIdx = max(0, min(symbols.count - 1, rawIdx))
            let minutesRead = days.first(where: { $0.date == date })?.minutesRead ?? 0
            return CalendarWeekDay(
                date: date,
                weekdaySymbol: symbols[weekdayIdx],
                minutesRead: minutesRead,
                hasMetGoal: dailyGoalMinutes > 0 && minutesRead >= dailyGoalMinutes,
                isToday: date == today
            )
        }
    }

    static func fullGoalWeeksCount(
        from days: [ReadingDay],
        dailyGoalMinutes: Int = ReadingGoals.dailyMinutes,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        guard dailyGoalMinutes > 0 else { return 0 }

        let successfulDates = days
            .filter { $0.minutesRead >= dailyGoalMinutes }
            .map { calendar.startOfDay(for: $0.date) }

        let groupedByWeek = Dictionary(grouping: successfulDates) { date in
            sundayStartOfWeek(for: date, calendar: calendar)
        }

        return groupedByWeek.values.filter { Set($0).count == 7 }.count
    }

    static func sundayStartOfWeek(
        for date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        let startOfDay = calendar.startOfDay(for: date)
        let weekday = calendar.component(.weekday, from: startOfDay)
        let daysFromSunday = weekday - 1
        return calendar.date(byAdding: .day, value: -daysFromSunday, to: startOfDay) ?? startOfDay
    }
}
