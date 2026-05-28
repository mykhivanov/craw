import Foundation
import SwiftData

@MainActor
enum DailyStatsAggregator {
    /// Build the daily-stats payload for a single local day. Pure read — does not mutate.
    /// `minutes_read` is sourced from `ReadingDay` (which already splits cross-midnight time
    /// by bucket). All other fields are computed from sessions/retros/quotes/books whose
    /// timestamps fall inside the day.
    static func aggregate(
        for date: Date,
        in context: ModelContext,
        calendar: Calendar = .autoupdatingCurrent
    ) -> DailyStatsPayload {
        let dayStart = calendar.startOfDay(for: date)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) ?? dayStart
        let normalizedDay = ReadingDay.normalizedDate(date, calendar: calendar)

        let minutesRead = fetchMinutes(on: normalizedDay, in: context)
        let sessions = fetchSessions(from: dayStart, until: dayEnd, in: context)
        let sessionIDs = sessions.map(\.id)
        let retrospectives = fetchRetrospectives(for: sessionIDs, in: context)
        let booksByID = booksKeyedByID(for: sessions, in: context)

        let avgFocus = average(retrospectives.map { Double($0.focusDifficulty) })
        let avgQuiz = average(sessions.compactMap { $0.quizMark.map(Double.init) })
        let studyShare = studyShareFromSessions(sessions, booksByID: booksByID)
        let goal = UserGoalReader.current(in: context)
        let goalMinutes = goal?.dailyMinutes
        let goalHit = goalMinutes.map { minutesRead >= $0 }
        let booksFinished = fetchBooksFinished(from: dayStart, until: dayEnd, in: context)
        let quotesCaptured = fetchQuotesCaptured(from: dayStart, until: dayEnd, in: context)

        return DailyStatsPayload(
            date: Self.isoDay(from: normalizedDay),
            minutesRead: minutesRead,
            sessions: sessions.count,
            avgFocusDifficulty: avgFocus,
            avgQuizMark: avgQuiz,
            studyShare: studyShare,
            dailyGoalMin: goalMinutes,
            goalHit: goalHit,
            booksFinished: booksFinished,
            quotesCaptured: quotesCaptured
        )
    }

    private static func fetchMinutes(on day: Date, in context: ModelContext) -> Int {
        let descriptor = FetchDescriptor<ReadingDay>(
            predicate: #Predicate { $0.date == day }
        )
        return (try? context.fetch(descriptor).first?.minutesRead) ?? 0
    }

    private static func fetchSessions(
        from start: Date,
        until end: Date,
        in context: ModelContext
    ) -> [ReadingSession] {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.startedAt >= start && $0.startedAt < end }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func fetchRetrospectives(
        for sessionIDs: [UUID],
        in context: ModelContext
    ) -> [SessionRetrospective] {
        guard !sessionIDs.isEmpty else { return [] }
        let ids = Set(sessionIDs)
        let descriptor = FetchDescriptor<SessionRetrospective>(
            predicate: #Predicate { ids.contains($0.sessionID) }
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    private static func booksKeyedByID(
        for sessions: [ReadingSession],
        in context: ModelContext
    ) -> [UUID: Book] {
        let bookIDs = Set(sessions.map(\.bookID))
        guard !bookIDs.isEmpty else { return [:] }
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { bookIDs.contains($0.id) }
        )
        let books = (try? context.fetch(descriptor)) ?? []
        return Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })
    }

    private static func studyShareFromSessions(
        _ sessions: [ReadingSession],
        booksByID: [UUID: Book]
    ) -> Double {
        var studySeconds = 0
        var totalSeconds = 0
        for session in sessions {
            totalSeconds += session.elapsedSeconds
            if booksByID[session.bookID]?.attitude == .study {
                studySeconds += session.elapsedSeconds
            }
        }
        guard totalSeconds > 0 else { return 0 }
        return Double(studySeconds) / Double(totalSeconds)
    }

    private static func fetchBooksFinished(
        from start: Date,
        until end: Date,
        in context: ModelContext
    ) -> Int {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { book in
                book.isFinished && book.finishedAt != nil && book.finishedAt! >= start && book
                    .finishedAt! < end
            }
        )
        return (try? context.fetch(descriptor).count) ?? 0
    }

    private static func fetchQuotesCaptured(
        from start: Date,
        until end: Date,
        in context: ModelContext
    ) -> Int {
        let descriptor = FetchDescriptor<Quote>(
            predicate: #Predicate { $0.capturedAt >= start && $0.capturedAt < end }
        )
        return (try? context.fetch(descriptor).count) ?? 0
    }

    private static func average(_ values: [Double]) -> Double? {
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +) / Double(values.count)
    }

    private static let dayFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withFullDate]
        return f
    }()

    private static func isoDay(from date: Date) -> String {
        dayFormatter.string(from: date)
    }
}
