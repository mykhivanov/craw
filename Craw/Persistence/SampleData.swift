#if DEBUG
    import Foundation
    import SwiftData

    enum SampleData {
        static let launchArgumentKey = "CrawSeedSampleData"

        static var isLaunchArgumentEnabled: Bool {
            UserDefaults.standard.bool(forKey: launchArgumentKey)
        }

        static func seedIfEmpty(into context: ModelContext) {
            let bookCount = (try? context.fetch(FetchDescriptor<Book>()).count) ?? 0
            let dayCount = (try? context.fetch(FetchDescriptor<ReadingDay>()).count) ?? 0
            guard bookCount == 0, dayCount == 0 else { return }
            seed(into: context)
        }

        static func seed(into context: ModelContext) {
            let inProgressForFun = Book(
                title: "The Lord of the Rings",
                author: "J.R.R. Tolkien",
                coverAssetName: nil,
                totalPages: 1200,
                attitude: .entertainment
            )
            let inProgressStudy = Book(
                title: "Project Hail Mary",
                author: "Andy Weir",
                coverAssetName: "book_cover_sample_a",
                totalPages: 480,
                attitude: .study
            )
            let finished = Book(
                title: "The Pragmatic Programmer",
                author: "Hunt & Thomas",
                coverAssetName: nil,
                totalPages: 320,
                attitude: .study,
                isFinished: true,
                finishedAt: Calendar.autoupdatingCurrent
                    .date(byAdding: .day, value: -10, to: .now) ?? .now
            )
            for book in [inProgressForFun, inProgressStudy, finished] {
                context.insert(book)
            }

            seedReadingDays(into: context)
            seedSessions(into: context, bookA: inProgressForFun, bookB: inProgressStudy)
            seedQuotes(into: context, bookA: inProgressForFun, bookB: inProgressStudy)

            try? context.save()
        }

        private static func seedReadingDays(into context: ModelContext) {
            struct DayPlan {
                let offset: Int
                let minutes: Int
            }
            let calendar = Calendar.autoupdatingCurrent
            let today = calendar.startOfDay(for: .now)
            let plan: [DayPlan] = [
                DayPlan(offset: 0, minutes: 45),
                DayPlan(offset: -1, minutes: 30),
                DayPlan(offset: -2, minutes: 40),
                DayPlan(offset: -3, minutes: 20),
                DayPlan(offset: -4, minutes: 0),
                DayPlan(offset: -5, minutes: 25),
                DayPlan(offset: -6, minutes: 0)
            ]
            for entry in plan {
                guard let day = calendar.date(byAdding: .day, value: entry.offset, to: today) else {
                    continue
                }
                if entry.minutes == 0 { continue }
                context.insert(ReadingDay(date: day, minutesRead: entry.minutes))
            }
        }

        private static func seedSessions(into context: ModelContext, bookA: Book, bookB: Book) {
            struct SessionPlan {
                let offset: Int
                let bookID: UUID
                let elapsedSeconds: Int
                let quizMark: Int?
                let focusDifficulty: Int
            }
            let calendar = Calendar.autoupdatingCurrent
            let now = Date.now
            let plans: [SessionPlan] = [
                SessionPlan(offset: 0, bookID: bookA.id, elapsedSeconds: 45 * 60, quizMark: nil, focusDifficulty: 2),
                SessionPlan(offset: -1, bookID: bookB.id, elapsedSeconds: 30 * 60, quizMark: 2, focusDifficulty: 3),
                SessionPlan(offset: -2, bookID: bookA.id, elapsedSeconds: 40 * 60, quizMark: nil, focusDifficulty: 4),
                SessionPlan(offset: -3, bookID: bookB.id, elapsedSeconds: 20 * 60, quizMark: 3, focusDifficulty: 2)
            ]
            for plan in plans {
                let endedAt = calendar.date(byAdding: .day, value: plan.offset, to: now) ?? now
                let startedAt = endedAt.addingTimeInterval(-TimeInterval(plan.elapsedSeconds))
                let session = ReadingSession(
                    bookID: plan.bookID,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    elapsedSeconds: plan.elapsedSeconds,
                    quizMark: plan.quizMark
                )
                context.insert(session)
                context.insert(SessionRetrospective(
                    sessionID: session.id,
                    focusDifficulty: plan.focusDifficulty,
                    createdAt: endedAt
                ))
            }
        }

        private static func seedQuotes(into context: ModelContext, bookA: Book, bookB: Book) {
            let quotes: [Quote] = [
                Quote(
                    bookID: bookA.id,
                    text: "All we have to decide is what to do with the time that is given us.",
                    pageNumber: 82
                ),
                Quote(bookID: bookA.id, text: "Not all those who wander are lost.", pageNumber: 167),
                Quote(
                    bookID: bookB.id,
                    text: "Science is a way of thinking much more than it is a body of knowledge.",
                    pageNumber: 41
                )
            ]
            for quote in quotes {
                context.insert(quote)
            }
        }
    }
#endif
