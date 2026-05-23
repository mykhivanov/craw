import Foundation

enum ReadingActivityReader {
    struct DayMetrics: Equatable {
        let date: Date
        let minutesRead: Int
        let pagesRead: Int
    }

    enum PagesDeltaKind: Equatable {
        case unchangedZero
        case increaseFromZero
        case percentChange(Double)
    }

    struct PagesDelta: Equatable {
        let todayPages: Int
        let kind: PagesDeltaKind
    }

    struct CalendarWeekDay: Equatable {
        let date: Date
        let weekdaySymbol: String
        let hasActivity: Bool
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
            minutesRead: row?.minutesRead ?? 0,
            pagesRead: row?.pagesRead ?? 0
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
                minutesRead: row?.minutesRead ?? 0,
                pagesRead: row?.pagesRead ?? 0
            )
        }
    }

    static func pagesDeltaVsYesterday(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> PagesDelta {
        let today = calendar.startOfDay(for: now)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today) ?? today
        let todayPages = days.first(where: { $0.date == today })?.pagesRead ?? 0
        let yesterdayPages = days.first(where: { $0.date == yesterday })?.pagesRead ?? 0

        if yesterdayPages == 0, todayPages == 0 {
            return PagesDelta(todayPages: 0, kind: .unchangedZero)
        }
        if yesterdayPages == 0 {
            return PagesDelta(todayPages: todayPages, kind: .increaseFromZero)
        }
        let pct = (Double(todayPages - yesterdayPages) / Double(yesterdayPages)) * 100.0
        return PagesDelta(todayPages: todayPages, kind: .percentChange(pct))
    }

    static func currentStreak(
        from days: [ReadingDay],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        let today = calendar.startOfDay(for: now)
        let todayRow = days.first(where: { $0.date == today })
        let anchor: Date = if let todayRow, todayRow.minutesRead > 0 {
            today
        } else {
            calendar.date(byAdding: .day, value: -1, to: today) ?? today
        }
        var streak = 0
        var cursor = anchor
        while true {
            guard let row = days.first(where: { $0.date == cursor }),
                  row.minutesRead > 0
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
        calendar: Calendar = .autoupdatingCurrent
    ) -> [CalendarWeekDay] {
        let today = calendar.startOfDay(for: now)
        let interval = calendar.dateInterval(of: .weekOfYear, for: today)
            ?? DateInterval(start: today, duration: 7 * 86400)
        let weekStart = calendar.startOfDay(for: interval.start)
        let symbols = calendar.shortWeekdaySymbols

        return (0..<7).compactMap { offset -> CalendarWeekDay? in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }
            let rawIdx = calendar.component(.weekday, from: date) - 1
            let weekdayIdx = max(0, min(symbols.count - 1, rawIdx))
            let hasActivity = (days.first(where: { $0.date == date })?.minutesRead ?? 0) > 0
            return CalendarWeekDay(
                date: date,
                weekdaySymbol: symbols[weekdayIdx],
                hasActivity: hasActivity,
                isToday: date == today
            )
        }
    }
}
