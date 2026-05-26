import Foundation
import Testing
@testable import Craw

@Suite("ReadingActivityReader")
struct ReadingActivityReaderTests {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        cal.firstWeekday = 2
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        return calendar.date(from: components)!
    }

    private func day(_ date: Date, minutes: Int = 0) -> ReadingDay {
        ReadingDay(date: date, minutesRead: minutes)
    }

    @Test("Positive day-over-day percentage change")
    func positiveMinutesChange() {
        let today = date(2026, 5, 24)
        let yesterday = date(2026, 5, 23)
        let days = [
            day(today, minutes: 30),
            day(yesterday, minutes: 20)
        ]
        let result = ReadingActivityReader.minutesDeltaVsYesterday(
            from: days, now: today, calendar: calendar
        )
        #expect(result.todayMinutes == 30)
        guard case let .percentChange(pct) = result.kind else {
            Issue.record("Expected .percentChange, got \(result.kind)")
            return
        }
        #expect(pct == 50.0)
    }

    @Test("Negative day-over-day percentage change")
    func negativeMinutesChange() {
        let today = date(2026, 5, 24)
        let yesterday = date(2026, 5, 23)
        let days = [
            day(today, minutes: 10),
            day(yesterday, minutes: 20)
        ]
        let result = ReadingActivityReader.minutesDeltaVsYesterday(
            from: days, now: today, calendar: calendar
        )
        #expect(result.todayMinutes == 10)
        guard case let .percentChange(pct) = result.kind else {
            Issue.record("Expected .percentChange")
            return
        }
        #expect(pct == -50.0)
    }

    @Test("Yesterday-zero produces increase-from-zero kind")
    func yesterdayZero() {
        let today = date(2026, 5, 24)
        let yesterday = date(2026, 5, 23)
        let days = [
            day(today, minutes: 15),
            day(yesterday, minutes: 0)
        ]
        let result = ReadingActivityReader.minutesDeltaVsYesterday(
            from: days, now: today, calendar: calendar
        )
        #expect(result.todayMinutes == 15)
        #expect(result.kind == .increaseFromZero)
    }

    @Test("Both days zero produces unchangedZero kind")
    func bothZero() {
        let today = date(2026, 5, 24)
        let result = ReadingActivityReader.minutesDeltaVsYesterday(
            from: [], now: today, calendar: calendar
        )
        #expect(result.todayMinutes == 0)
        #expect(result.kind == .unchangedZero)
    }

    @Test("Five-day active streak including today")
    func fiveDayActiveStreak() throws {
        let today = date(2026, 5, 24)
        var days: [ReadingDay] = []
        for offset in 0..<5 {
            let d = try #require(calendar.date(byAdding: .day, value: -offset, to: today))
            days.append(day(d, minutes: 20))
        }
        let streak = ReadingActivityReader.currentStreak(
            from: days, now: today, calendar: calendar
        )
        #expect(streak == 5)
    }

    @Test("Today-not-yet-logged anchors streak on yesterday")
    func todayNotYetLoggedAnchorsOnYesterday() throws {
        let today = date(2026, 5, 24)
        var days: [ReadingDay] = []
        for offset in 1...3 {
            let d = try #require(calendar.date(byAdding: .day, value: -offset, to: today))
            days.append(day(d, minutes: 20))
        }
        let streak = ReadingActivityReader.currentStreak(
            from: days, now: today, calendar: calendar
        )
        #expect(streak == 3)
    }

    @Test("Streak broken by a mid-window zero-minute day")
    func streakBrokenByGap() throws {
        let today = date(2026, 5, 24)
        var days: [ReadingDay] = []
        for offset in 0...6 {
            let d = try #require(calendar.date(byAdding: .day, value: -offset, to: today))
            let minutes = (offset == 2) ? 0 : 30
            days.append(day(d, minutes: minutes))
        }
        let streak = ReadingActivityReader.currentStreak(
            from: days, now: today, calendar: calendar
        )
        #expect(streak == 2)
    }

    @Test("No activity at all produces zero streak")
    func noActivityZeroStreak() {
        let today = date(2026, 5, 24)
        let streak = ReadingActivityReader.currentStreak(
            from: [], now: today, calendar: calendar
        )
        #expect(streak == 0)
    }

    @Test("Current calendar week respects firstWeekday and marks today")
    func currentCalendarWeekMidWeek() {
        let wednesday = date(2026, 5, 20)
        let monday = date(2026, 5, 18)
        let tuesday = date(2026, 5, 19)
        let days = [
            day(monday, minutes: 30),
            day(tuesday, minutes: 30)
        ]
        let week = ReadingActivityReader.currentCalendarWeek(
            from: days, now: wednesday, calendar: calendar
        )
        #expect(week.count == 7)
        #expect(week.first?.date == monday)
        #expect(week[0].hasActivity == true)
        #expect(week[1].hasActivity == true)
        #expect(week[2].isToday == true)
        #expect(week[2].hasActivity == false)
        #expect(week[3..<7].allSatisfy { !$0.hasActivity })
    }

    @Test("Current calendar week with no activity on first weekday")
    func currentCalendarWeekStartOfWeek() {
        let monday = date(2026, 5, 18)
        let week = ReadingActivityReader.currentCalendarWeek(
            from: [], now: monday, calendar: calendar
        )
        #expect(week.count == 7)
        #expect(week.first?.isToday == true)
        #expect(week.allSatisfy { !$0.hasActivity })
    }

    @Test("Last seven days returns dense seven entries")
    func lastSevenDaysSparseWeek() throws {
        let today = date(2026, 5, 24)
        let twoDaysAgo = try #require(calendar.date(byAdding: .day, value: -2, to: today))
        let fiveDaysAgo = try #require(calendar.date(byAdding: .day, value: -5, to: today))
        let days = [
            day(twoDaysAgo, minutes: 30),
            day(fiveDaysAgo, minutes: 45)
        ]
        let result = ReadingActivityReader.lastSevenDays(
            from: days, now: today, calendar: calendar
        )
        #expect(result.count == 7)
        #expect(result.last?.date == today)
        let nonZero = result.filter { $0.minutesRead > 0 }
        #expect(nonZero.count == 2)
    }
}
