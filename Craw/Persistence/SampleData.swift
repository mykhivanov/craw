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
            let inProgressNoCover = Book(
                title: "The Lord of the Rings",
                author: "J.R.R. Tolkien",
                coverAssetName: nil,
                totalPages: 1200,
                currentPage: 540
            )
            let inProgressWithCover = Book(
                title: "Project Hail Mary",
                author: "Andy Weir",
                coverAssetName: "book_cover_sample_a",
                totalPages: 480,
                currentPage: 60
            )
            let finished = Book(
                title: "The Pragmatic Programmer",
                author: "Hunt & Thomas",
                coverAssetName: nil,
                totalPages: 320,
                currentPage: 320
            )
            for book in [inProgressNoCover, inProgressWithCover, finished] {
                context.insert(book)
            }

            seedReadingDays(into: context)
            seedSessions(
                into: context,
                bookA: inProgressNoCover,
                bookB: inProgressWithCover
            )
            seedQuotesAndThoughts(
                into: context,
                bookA: inProgressNoCover,
                bookB: inProgressWithCover
            )

            try? context.save()
        }

        private static func seedReadingDays(into context: ModelContext) {
            struct DayPlan {
                let offset: Int
                let minutes: Int
                let pages: Int
            }
            let calendar = Calendar.autoupdatingCurrent
            let today = calendar.startOfDay(for: .now)
            let plan: [DayPlan] = [
                DayPlan(offset: 0, minutes: 45, pages: 30),
                DayPlan(offset: -1, minutes: 30, pages: 20),
                DayPlan(offset: -2, minutes: 40, pages: 25),
                DayPlan(offset: -3, minutes: 20, pages: 10),
                DayPlan(offset: -4, minutes: 0, pages: 0),
                DayPlan(offset: -5, minutes: 25, pages: 15),
                DayPlan(offset: -6, minutes: 0, pages: 0)
            ]
            for entry in plan {
                guard let day = calendar.date(byAdding: .day, value: entry.offset, to: today) else {
                    continue
                }
                if entry.minutes == 0, entry.pages == 0 { continue }
                context.insert(ReadingDay(
                    date: day,
                    minutesRead: entry.minutes,
                    pagesRead: entry.pages
                ))
            }
        }

        /// Four sessions across the last four days. Retrospectives produce
        /// exactly two "hard" days (offsets -2 and -3) per the hard-day rule:
        /// any session that day with startDifficulty >= 4 OR focusDifficulty >= 4.
        private static func seedSessions(into context: ModelContext, bookA: Book, bookB: Book) {
            struct SessionPlan {
                let offset: Int
                let bookID: UUID
                let elapsedSeconds: Int
                let pagesRead: Int
                let verification: VerificationState
                let startDifficulty: Int
                let focusDifficulty: Int
                let enjoyment: Int
            }
            let calendar = Calendar.autoupdatingCurrent
            let now = Date.now
            let plans: [SessionPlan] = [
                SessionPlan(
                    offset: 0,
                    bookID: bookA.id,
                    elapsedSeconds: 45 * 60,
                    pagesRead: 30,
                    verification: .verified,
                    startDifficulty: 2,
                    focusDifficulty: 2,
                    enjoyment: 4
                ),
                SessionPlan(
                    offset: -1,
                    bookID: bookB.id,
                    elapsedSeconds: 30 * 60,
                    pagesRead: 20,
                    verification: .failed,
                    startDifficulty: 3,
                    focusDifficulty: 3,
                    enjoyment: 3
                ),
                SessionPlan(
                    offset: -2,
                    bookID: bookA.id,
                    elapsedSeconds: 40 * 60,
                    pagesRead: 25,
                    verification: .verified,
                    startDifficulty: 5,
                    focusDifficulty: 4,
                    enjoyment: 2
                ),
                SessionPlan(
                    offset: -3,
                    bookID: bookB.id,
                    elapsedSeconds: 20 * 60,
                    pagesRead: 10,
                    verification: .skipped,
                    startDifficulty: 4,
                    focusDifficulty: 2,
                    enjoyment: 3
                )
            ]
            for plan in plans {
                let endedAt = calendar.date(byAdding: .day, value: plan.offset, to: now) ?? now
                let startedAt = endedAt.addingTimeInterval(-TimeInterval(plan.elapsedSeconds))
                let session = ReadingSession(
                    bookID: plan.bookID,
                    startedAt: startedAt,
                    endedAt: endedAt,
                    elapsedSeconds: plan.elapsedSeconds,
                    pagesRead: plan.pagesRead,
                    verification: plan.verification
                )
                context.insert(session)
                context.insert(SessionRetrospective(
                    sessionID: session.id,
                    startDifficulty: plan.startDifficulty,
                    focusDifficulty: plan.focusDifficulty,
                    enjoyment: plan.enjoyment,
                    createdAt: endedAt
                ))
            }
        }

        private static func seedQuotesAndThoughts(into context: ModelContext, bookA: Book, bookB: Book) {
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

            let thoughts: [Thought] = [
                Thought(bookID: bookA.id, text: "Sam carries the story when Frodo breaks."),
                Thought(bookID: bookA.id, text: "Pacing slows in the Council of Elrond — re-read tomorrow."),
                Thought(bookID: bookA.id, text: "Tom Bombadil cut feels right for the films but I miss him."),
                Thought(bookID: bookB.id, text: "Grace's diet-monster banter lands harder than expected."),
                Thought(bookID: bookB.id, text: "Astrophage as a closed-loop fuel is more interesting than the alien.")
            ]
            for thought in thoughts {
                context.insert(thought)
            }
        }
    }
#endif
