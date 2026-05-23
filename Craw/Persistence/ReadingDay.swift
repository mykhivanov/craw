import Foundation
import SwiftData

@Model
final class ReadingDay {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var date: Date
    var minutesRead: Int
    var pagesRead: Int

    init(
        id: UUID = UUID(),
        date: Date,
        minutesRead: Int = 0,
        pagesRead: Int = 0
    ) {
        self.id = id
        self.date = date
        self.minutesRead = minutesRead
        self.pagesRead = pagesRead
    }
}

extension ReadingDay {
    static func normalizedDate(
        _ date: Date,
        calendar: Calendar = .autoupdatingCurrent
    ) -> Date {
        calendar.startOfDay(for: date)
    }

    static func upsert(
        on date: Date,
        addingMinutes minutes: Int,
        addingPages pages: Int,
        in context: ModelContext,
        calendar: Calendar = .autoupdatingCurrent
    ) throws {
        let normalized = normalizedDate(date, calendar: calendar)
        let descriptor = FetchDescriptor<ReadingDay>(
            predicate: #Predicate { $0.date == normalized }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.minutesRead += minutes
            existing.pagesRead += pages
        } else {
            let row = ReadingDay(
                date: normalized,
                minutesRead: max(0, minutes),
                pagesRead: max(0, pages)
            )
            context.insert(row)
        }
    }
}
