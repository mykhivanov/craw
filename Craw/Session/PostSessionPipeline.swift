import Foundation
import SwiftData

@MainActor
final class PostSessionPipeline {
    private let modelContext: ModelContext

    init(context: ModelContext) {
        modelContext = context
    }

    /// Insert (or fetch existing) `ReadingSession` for the just-stopped engine,
    /// and upsert `ReadingDay` rows with cross-midnight minute split.
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
            elapsedSeconds: engine.elapsedSeconds
        )
        modelContext.insert(session)

        let buckets = MidnightSplitter.split(startedAt: startedAt, endedAt: endedAt)
        for bucket in buckets {
            let minutes = bucket.seconds / 60
            try? ReadingDay.upsert(
                on: bucket.date,
                addingMinutes: minutes,
                in: modelContext
            )
        }

        try? modelContext.save()
        return session
    }

    func saveRetrospective(sessionID: UUID, focusDifficulty: Int) {
        modelContext.insert(SessionRetrospective(
            sessionID: sessionID,
            focusDifficulty: focusDifficulty
        ))
        try? modelContext.save()
    }

    func updateQuizResult(
        sessionID: UUID,
        sectionOrPageHint: String?,
        mark: Int?
    ) {
        let descriptor = FetchDescriptor<ReadingSession>(
            predicate: #Predicate { $0.id == sessionID }
        )
        guard let session = try? modelContext.fetch(descriptor).first else { return }
        if let sectionOrPageHint {
            session.sectionOrPageHint = sectionOrPageHint
        }
        if let mark {
            session.quizMark = mark
        }
        try? modelContext.save()
    }

    /// Idempotent: flips `isFinished = true` and stamps `finishedAt = .now` only on the
    /// first call. Re-entry preserves the original `finishedAt`.
    func markBookFinished(bookID: UUID) {
        let descriptor = FetchDescriptor<Book>(
            predicate: #Predicate { $0.id == bookID }
        )
        guard let book = try? modelContext.fetch(descriptor).first else { return }
        if !book.isFinished {
            book.isFinished = true
            book.finishedAt = .now
            try? modelContext.save()
        }
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
