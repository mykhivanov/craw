import Foundation

struct ActiveSessionSnapshot: Codable, Equatable {
    let bookID: UUID
    let startedAt: Date
    let accumulatedElapsedSeconds: Int
    let startingPage: Int
    let currentPage: Int
    let isPaused: Bool
    let lastCheckpointAt: Date
}

protocol ActiveSessionCaching: AnyObject {
    func save(_ snapshot: ActiveSessionSnapshot)
    func load() -> ActiveSessionSnapshot?
    func clear()
}

final class ActiveSessionCache: ActiveSessionCaching {
    private static let key = "CrawActiveSession"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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
