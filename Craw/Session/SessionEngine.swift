import Foundation
import Observation

enum SessionState: String, Equatable {
    case idle
    case running
    case paused
    case stopped
    case saving
}

@Observable
@MainActor
final class SessionEngine {
    static let shared = SessionEngine()

    private(set) var state: SessionState = .idle
    private(set) var book: Book?
    private(set) var startedAt: Date = .now
    private(set) var endedAt: Date?
    private(set) var accumulatedElapsedSeconds: Int = 0
    private(set) var lastResumeAt: Date?
    /// True when the user ended this session via "Book is finished" (rather than "Finish").
    /// The post-session flow reads this to skip the section picker and jump straight to
    /// quiz questions on the book-finished path.
    private(set) var endedAsBookFinished: Bool = false

    private let cache: ActiveSessionCaching
    private var autosaveTask: Task<Void, Never>?

    init(cache: ActiveSessionCaching = ActiveSessionCache()) {
        self.cache = cache
    }

    var elapsedSeconds: Int {
        liveAccumulated()
    }

    var isActive: Bool {
        switch state {
        case .running, .paused, .stopped, .saving: true
        case .idle: false
        }
    }

    // MARK: - Transitions

    func start(book: Book, now: Date = .now) {
        guard state == .idle else { return }
        self.book = book
        startedAt = now
        endedAt = nil
        accumulatedElapsedSeconds = 0
        lastResumeAt = now
        endedAsBookFinished = false
        state = .running
        scheduleAutosave()
        persistSnapshot()
        LiveActivityController.shared.start(engine: self)
    }

    func pause(now: Date = .now) {
        guard state == .running else { return }
        if let resume = lastResumeAt {
            accumulatedElapsedSeconds += Int(now.timeIntervalSince(resume))
        }
        lastResumeAt = nil
        state = .paused
        cancelAutosave()
        persistSnapshot()
        LiveActivityController.shared.update(engine: self)
    }

    func resume(now: Date = .now) {
        guard state == .paused else { return }
        lastResumeAt = now
        state = .running
        scheduleAutosave()
        persistSnapshot()
        LiveActivityController.shared.update(engine: self)
    }

    func stop(now: Date = .now, asBookFinished: Bool = false) {
        guard state == .running || state == .paused else { return }
        if state == .running, let resume = lastResumeAt {
            accumulatedElapsedSeconds += Int(now.timeIntervalSince(resume))
            lastResumeAt = nil
        }
        endedAt = now
        endedAsBookFinished = asBookFinished
        cancelAutosave()
        state = .stopped
        persistSnapshot()
        LiveActivityController.shared.end()
    }

    func beginSaving() {
        guard state == .stopped else { return }
        state = .saving
    }

    func finish() {
        cancelAutosave()
        cache.clear()
        state = .idle
        book = nil
        startedAt = .now
        endedAt = nil
        accumulatedElapsedSeconds = 0
        lastResumeAt = nil
        endedAsBookFinished = false
        LiveActivityController.shared.end()
    }

    // MARK: - Restoration

    func restore(from snapshot: ActiveSessionSnapshot, book: Book, now: Date = .now) {
        guard state == .idle else { return }
        self.book = book
        startedAt = snapshot.startedAt
        endedAt = nil
        accumulatedElapsedSeconds = snapshot.accumulatedElapsedSeconds
        endedAsBookFinished = false
        if snapshot.isPaused {
            lastResumeAt = nil
            state = .paused
        } else {
            lastResumeAt = now
            state = .running
            scheduleAutosave()
        }
        LiveActivityController.shared.start(engine: self)
    }

    // MARK: - Cache plumbing

    func persistSnapshot() {
        guard let book else { return }
        let snapshot = ActiveSessionSnapshot(
            bookID: book.id,
            startedAt: startedAt,
            accumulatedElapsedSeconds: liveAccumulated(),
            isPaused: state == .paused,
            lastCheckpointAt: .now
        )
        cache.save(snapshot)
    }

    func liveAccumulated(now: Date = .now) -> Int {
        if state == .running, let resume = lastResumeAt {
            return accumulatedElapsedSeconds + Int(now.timeIntervalSince(resume))
        }
        return accumulatedElapsedSeconds
    }

    private func scheduleAutosave() {
        cancelAutosave()
        autosaveTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(15))
                if Task.isCancelled { break }
                self?.persistSnapshot()
            }
        }
    }

    private func cancelAutosave() {
        autosaveTask?.cancel()
        autosaveTask = nil
    }
}
