import Foundation
import SwiftData

@Model
final class ReadingDay {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var date: Date
    var minutesRead: Int

    init(
        id: UUID = UUID(),
        date: Date,
        minutesRead: Int = 0
    ) {
        self.id = id
        self.date = date
        self.minutesRead = minutesRead
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
        in context: ModelContext,
        calendar: Calendar = .autoupdatingCurrent
    ) throws {
        let normalized = normalizedDate(date, calendar: calendar)
        let descriptor = FetchDescriptor<ReadingDay>(
            predicate: #Predicate { $0.date == normalized }
        )
        if let existing = try context.fetch(descriptor).first {
            existing.minutesRead += minutes
        } else {
            let row = ReadingDay(
                date: normalized,
                minutesRead: max(0, minutes)
            )
            context.insert(row)
        }
    }
}
