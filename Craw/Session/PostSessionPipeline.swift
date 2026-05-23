import Foundation
import SwiftData

@MainActor
final class PostSessionPipeline {
    private let modelContext: ModelContext

    init(context: ModelContext) {
        modelContext = context
    }

    /// Insert (or fetch existing) `ReadingSession` for the just-stopped engine,
    /// update the book's `currentPage`, and upsert `ReadingDay` rows with
    /// cross-midnight split (minutes split, pages attributed entirely to stop-day).
    /// Idempotent on `(bookID, endedAt)` — re-entry returns the existing row.
    func commit(_ engine: SessionEngine) -> ReadingSession? {
        guard let book = engine.book, let endedAt = engine.endedAt else { return nil }
        let startedAt = engine.startedAt
        let bookID = book.id

        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.bookID == bookID && $0.endedAt == endedAt }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }

        let session = ReadingSession(
            bookID: bookID,
            startedAt: startedAt,
            endedAt: endedAt,
            elapsedSeconds: engine.elapsedSeconds,
            pagesRead: engine.pagesRead,
            verification: .pending
        )
        modelContext.insert(session)
        book.currentPage = engine.currentPage

        let buckets = MidnightSplitter.split(startedAt: startedAt, endedAt: endedAt)
        let stopDay = Calendar.autoupdatingCurrent.startOfDay(for: endedAt)
        for bucket in buckets {
            let minutes = bucket.seconds / 60
            let pages = bucket.date == stopDay ? engine.pagesRead : 0
            try? ReadingDay.upsert(
                on: bucket.date,
                addingMinutes: minutes,
                addingPages: pages,
                in: modelContext
            )
        }

        try? modelContext.save()
        return session
    }

    func saveThoughts(_ texts: [String], for bookID: UUID) {
        for text in texts {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            modelContext.insert(Thought(bookID: bookID, text: trimmed))
        }
        try? modelContext.save()
    }

    func saveRetrospective(
        sessionID: UUID,
        startDifficulty: Int,
        focusDifficulty: Int,
        enjoyment: Int
    ) {
        modelContext.insert(SessionRetrospective(
            sessionID: sessionID,
            startDifficulty: startDifficulty,
            focusDifficulty: focusDifficulty,
            enjoyment: enjoyment
        ))
        try? modelContext.save()
    }

    func updateVerification(
        sessionID: UUID,
        to state: VerificationState,
        reflectionText: String? = nil
    ) {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.id == sessionID }
        )
        guard let session = try? modelContext.fetch(descriptor).first else { return }
        session.verification = state
        if let reflectionText {
            session.reflectionText = reflectionText
        }
        try? modelContext.save()
    }

    /// Returns the user's current streak length, computed by reading the
    /// latest `ReadingDay` rows. Used by the celebration trigger to compare
    /// `streakBefore` and `streakAfter` around the commit step.
    func currentStreakSnapshot() -> Int {
        let descriptor = FetchDescriptor<ReadingDay>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let days = (try? modelContext.fetch(descriptor)) ?? []
        return ReadingActivityReader.currentStreak(from: days)
    }
}
