import Foundation

enum BookGoalReader {
    static func booksFinishedThisYear(
        from books: [Book],
        now: Date = .now,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Int {
        guard let yearInterval = calendar.dateInterval(of: .year, for: now) else {
            return 0
        }

        return books.filter { book in
            guard let finishedAt = book.finishedAt else { return false }
            return finishedAt >= yearInterval.start && finishedAt < yearInterval.end
        }
        .count
    }
}
