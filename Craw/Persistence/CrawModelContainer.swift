import Foundation
import SwiftData

enum CrawModelContainer {
    /// Bumped whenever the persisted schema requires a hard reset of the on-device store.
    /// The redesign-reading-session-flow change drops fields and a whole model; lightweight
    /// migration can't cover destructive removals, so v2 wipes any v1 store on first launch
    /// of the new binary. Library books re-hydrate from the backend after sign-in.
    static let currentSchemaVersion: Int = 2

    static let schema = Schema([
        Book.self,
        ReadingDay.self,
        ReadingSession.self,
        SessionRetrospective.self,
        Quote.self
    ])

    private static let schemaVersionKey = "CrawSchemaVersion"
    private static let storeFileName = "Craw.store"

    static func make(inMemory: Bool = false) -> ModelContainer {
        if !inMemory {
            wipeStoreIfSchemaVersionStale()
        }
        let configuration = if inMemory {
            ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else {
            ModelConfiguration(schema: schema, url: liveStoreURL())
        }
        do {
            let container = try ModelContainer(for: schema, configurations: [configuration])
            if !inMemory {
                UserDefaults.standard.set(currentSchemaVersion, forKey: schemaVersionKey)
            }
            return container
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
        try context.save()
    }

    /// If the persisted schema version is older than `currentSchemaVersion`, delete the
    /// on-disk SwiftData store files so the container can rebuild against the new schema.
    /// In-memory containers never read or write the persisted version.
    private static func wipeStoreIfSchemaVersionStale() {
        let defaults = UserDefaults.standard
        let persistedVersion = defaults.integer(forKey: schemaVersionKey)
        guard persistedVersion < currentSchemaVersion else { return }
        deleteStoreFiles()
    }

    private static func liveStoreURL() -> URL {
        let fileManager = FileManager.default
        let supportDir = (try? fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )) ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return supportDir.appendingPathComponent(storeFileName)
    }

    private static func deleteStoreFiles() {
        let fileManager = FileManager.default
        let storeURL = liveStoreURL()
        let basePath = storeURL.path
        for suffix in ["", "-wal", "-shm"] {
            let path = basePath + suffix
            try? fileManager.removeItem(atPath: path)
        }
    }
}
