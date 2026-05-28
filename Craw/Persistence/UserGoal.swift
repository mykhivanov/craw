import Foundation
import SwiftData

@Model
final class UserGoal {
    @Attribute(.unique) var id: UUID
    var dailyMinutes: Int
    var yearlyBooks: Int?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        dailyMinutes: Int,
        yearlyBooks: Int? = nil,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.dailyMinutes = dailyMinutes
        self.yearlyBooks = yearlyBooks
        self.updatedAt = updatedAt
    }
}

enum UserGoalReader {
    static func current(in context: ModelContext) -> UserGoal? {
        let descriptor = FetchDescriptor<UserGoal>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor))?.first
    }

    static func upsert(
        dailyMinutes: Int,
        yearlyBooks: Int?,
        in context: ModelContext
    ) {
        if let existing = current(in: context) {
            existing.dailyMinutes = dailyMinutes
            existing.yearlyBooks = yearlyBooks
            existing.updatedAt = .now
        } else {
            context.insert(
                UserGoal(
                    dailyMinutes: dailyMinutes,
                    yearlyBooks: yearlyBooks
                )
            )
        }
        try? context.save()
    }
}
