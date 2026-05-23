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

            try? context.save()
        }
    }
#endif
