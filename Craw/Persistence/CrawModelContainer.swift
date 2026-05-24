import Foundation
import SwiftData

enum CrawModelContainer {
    static let schema = Schema([
        Book.self,
        ReadingDay.self,
        ReadingSession.self,
        SessionRetrospective.self,
        Quote.self,
        Thought.self
    ])

    static func make(inMemory: Bool = false) -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to construct ModelContainer: \(error)")
        }
    }

    static func live() -> ModelContainer {
        make(inMemory: false)
    }

    static func previewInMemory() -> ModelContainer {
        make(inMemory: true)
    }

    static func wipeAllUserData(context: ModelContext) throws {
        try context.delete(model: Book.self)
        try context.delete(model: ReadingDay.self)
        try context.delete(model: ReadingSession.self)
        try context.delete(model: SessionRetrospective.self)
        try context.delete(model: Quote.self)
        try context.delete(model: Thought.self)
        try context.save()
    }
}
