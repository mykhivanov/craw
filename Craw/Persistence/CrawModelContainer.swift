import Foundation
import SwiftData

enum CrawModelContainer {
    static let schema = Schema([Book.self, ReadingDay.self])

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
}
