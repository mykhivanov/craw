import Foundation
import Testing
@testable import Craw

@Suite("MidnightSplitter")
struct MidnightSplitterTests {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0, _ minute: Int = 0) -> Date {
        var c = DateComponents()
        c.year = year; c.month = month; c.day = day; c.hour = hour; c.minute = minute
        return calendar.date(from: c)!
    }

    @Test("Same-day session returns one bucket")
    func sameDay() {
        let start = date(2026, 5, 24, 10, 0)
        let end = date(2026, 5, 24, 10, 30) // 30 min later
        let buckets = MidnightSplitter.split(startedAt: start, endedAt: end, calendar: calendar)
        #expect(buckets.count == 1)
        #expect(buckets[0].seconds == 1800)
        #expect(buckets[0].date == date(2026, 5, 24))
    }

    @Test("Session straddling midnight returns two buckets")
    func acrossMidnight() {
        let start = date(2026, 5, 24, 23, 40) // 23:40
        let end = date(2026, 5, 25, 0, 20) // next day 00:20 → 40 min total
        let buckets = MidnightSplitter.split(startedAt: start, endedAt: end, calendar: calendar)
        #expect(buckets.count == 2)
        #expect(buckets[0].date == date(2026, 5, 24))
        #expect(buckets[0].seconds == 20 * 60)
        #expect(buckets[1].date == date(2026, 5, 25))
        #expect(buckets[1].seconds == 20 * 60)
    }

    @Test("Session crossing three days returns three buckets")
    func acrossThreeDays() {
        let start = date(2026, 5, 24, 23, 50)
        let end = date(2026, 5, 26, 0, 10)
        let buckets = MidnightSplitter.split(startedAt: start, endedAt: end, calendar: calendar)
        #expect(buckets.count == 3)
        #expect(buckets[0].date == date(2026, 5, 24))
        #expect(buckets[1].date == date(2026, 5, 25))
        #expect(buckets[1].seconds == 24 * 60 * 60)
        #expect(buckets[2].date == date(2026, 5, 26))
    }

    @Test("End before start returns no buckets")
    func reversedTimes() {
        let start = date(2026, 5, 24, 12, 0)
        let end = date(2026, 5, 24, 11, 0)
        let buckets = MidnightSplitter.split(startedAt: start, endedAt: end, calendar: calendar)
        #expect(buckets.isEmpty)
    }
}
