import Foundation

struct ActiveSessionSnapshot: Codable, Equatable {
    let bookID: UUID
    let startedAt: Date
    let accumulatedElapsedSeconds: Int
    let isPaused: Bool
    let lastCheckpointAt: Date
}

protocol ActiveSessionCaching: AnyObject {
    func save(_ snapshot: ActiveSessionSnapshot)
    func load() -> ActiveSessionSnapshot?
    func clear()
}

final class ActiveSessionCache: ActiveSessionCaching {
    /// Bumped from v1: the snapshot no longer carries `startingPage`/`currentPage`.
    /// A stale v1 cache fails to decode and is silently cleared on next load.
    private static let key = "CrawActiveSession.v2"
    private static let legacyKeys = ["CrawActiveSession"]

    private let defaults: UserDefaults

    nonisolated init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        for legacy in Self.legacyKeys {
            defaults.removeObject(forKey: legacy)
        }
    }

    func save(_ snapshot: ActiveSessionSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: Self.key)
    }

    func load() -> ActiveSessionSnapshot? {
        guard let data = defaults.data(forKey: Self.key) else { return nil }
        return try? JSONDecoder().decode(ActiveSessionSnapshot.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: Self.key)
    }
}
