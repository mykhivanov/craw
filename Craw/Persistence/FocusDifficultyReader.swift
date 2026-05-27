import Foundation

enum FocusDifficultyReader {
    struct WeeklyAverage: Equatable, Identifiable {
        let weekStart: Date
        let average: Double?

        var id: Date {
            weekStart
        }
    }

    static func currentWeekAverage(
        sessions: [ReadingSession],
        retrospectives: [SessionRetrospective],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Double? {
        let weekStart = ReadingActivityReader.sundayStartOfWeek(for: now, calendar: calendar)
        return averageFocusDifficulty(
            sessions: sessions,
            retrospectives: retrospectives,
            weekStart: weekStart,
            calendar: calendar
        )
    }

    static func lastFiveWeeks(
        sessions: [ReadingSession],
        retrospectives: [SessionRetrospective],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> [WeeklyAverage] {
        let currentWeekStart = ReadingActivityReader.sundayStartOfWeek(for: now, calendar: calendar)
        return (0..<5).reversed().compactMap { offset -> WeeklyAverage? in
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -offset, to: currentWeekStart) else {
                return nil
            }
            return WeeklyAverage(
                weekStart: weekStart,
                average: averageFocusDifficulty(
                    sessions: sessions,
                    retrospectives: retrospectives,
                    weekStart: weekStart,
                    calendar: calendar
                )
            )
        }
    }

    private static func averageFocusDifficulty(
        sessions: [ReadingSession],
        retrospectives: [SessionRetrospective],
        weekStart: Date,
        calendar: Calendar
    ) -> Double? {
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) else {
            return nil
        }

        let sessionEndedAtByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0.endedAt) })
        let values = retrospectives.compactMap { retrospective -> Int? in
            guard let endedAt = sessionEndedAtByID[retrospective.sessionID],
                  endedAt >= weekStart,
                  endedAt < weekEnd
            else {
                return nil
            }
            return retrospective.focusDifficulty
        }

        guard !values.isEmpty else { return nil }
        return Double(values.reduce(0, +)) / Double(values.count)
    }
}
