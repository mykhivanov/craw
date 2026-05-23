import Foundation
import Testing
@testable import Craw

@Suite("ReadingActivityReader.hardDays")
struct HardDaysTests {
    private let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        return cal
    }()

    private func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 20) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = h
        return calendar.date(from: c)!
    }

    private func session(endedAt: Date, bookID: UUID = UUID()) -> ReadingSession {
        ReadingSession(
            bookID: bookID,
            startedAt: endedAt.addingTimeInterval(-600),
            endedAt: endedAt,
            elapsedSeconds: 600,
            pagesRead: 5
        )
    }

    private func retro(
        for session: ReadingSession,
        start: Int,
        focus: Int,
        enjoyment: Int = 3
    ) -> SessionRetrospective {
        SessionRetrospective(
            sessionID: session.id,
            startDifficulty: start,
            focusDifficulty: focus,
            enjoyment: enjoyment
        )
    }

    @Test("Mixed week with two hard days returns 2")
    func mixedWeek() {
        let today = date(2026, 5, 24)
        let s0 = session(endedAt: today)
        let s1 = session(endedAt: date(2026, 5, 22))
        let s2 = session(endedAt: date(2026, 5, 21))
        let r0 = retro(for: s0, start: 2, focus: 2) // not hard
        let r1 = retro(for: s1, start: 5, focus: 3) // HARD (start>=4)
        let r2 = retro(for: s2, start: 2, focus: 4) // HARD (focus>=4)

        let count = ReadingActivityReader.hardDaysInLastSevenDays(
            sessions: [s0, s1, s2],
            retrospectives: [r0, r1, r2],
            now: today,
            calendar: calendar
        )
        #expect(count == 2)
    }

    @Test("Day with both hard and not-hard sessions is hard")
    func anyHardSessionMakesDayHard() {
        let today = date(2026, 5, 24)
        let s1 = session(endedAt: today)
        let s2 = session(endedAt: today.addingTimeInterval(-3600))
        let r1 = retro(for: s1, start: 1, focus: 2) // not hard
        let r2 = retro(for: s2, start: 5, focus: 3) // HARD

        let count = ReadingActivityReader.hardDaysInLastSevenDays(
            sessions: [s1, s2],
            retrospectives: [r1, r2],
            now: today,
            calendar: calendar
        )
        #expect(count == 1)
    }

    @Test("No hard sessions returns zero")
    func allEasy() {
        let today = date(2026, 5, 24)
        let s1 = session(endedAt: today)
        let r1 = retro(for: s1, start: 1, focus: 2)
        let count = ReadingActivityReader.hardDaysInLastSevenDays(
            sessions: [s1],
            retrospectives: [r1],
            now: today,
            calendar: calendar
        )
        #expect(count == 0)
    }

    @Test("Sessions older than 7 days are ignored")
    func oldSessionsIgnored() {
        let today = date(2026, 5, 24)
        let old = session(endedAt: date(2026, 5, 10)) // 14 days ago
        let r = retro(for: old, start: 5, focus: 5)
        let count = ReadingActivityReader.hardDaysInLastSevenDays(
            sessions: [old],
            retrospectives: [r],
            now: today,
            calendar: calendar
        )
        #expect(count == 0)
    }
}
