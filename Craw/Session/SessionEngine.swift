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
    private(set) var state: SessionState = .idle
    private(set) var book: Book?
    private(set) var startedAt: Date = .now
    private(set) var endedAt: Date?
    private(set) var accumulatedElapsedSeconds: Int = 0
    private(set) var lastResumeAt: Date?
    private(set) var startingPage: Int = 0
    private(set) var currentPage: Int = 0

    private let cache: ActiveSessionCaching
    private var autosaveTask: Task<Void, Never>?

    init(cache: ActiveSessionCaching = ActiveSessionCache()) {
        self.cache = cache
    }

    var elapsedSeconds: Int {
        liveAccumulated()
    }

    var pagesRead: Int {
        max(0, currentPage - startingPage)
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
        startingPage = book.currentPage
        currentPage = book.currentPage
        lastResumeAt = now
        state = .running
        scheduleAutosave()
        persistSnapshot()
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
    }

    func resume(now: Date = .now) {
        guard state == .paused else { return }
        lastResumeAt = now
        state = .running
        scheduleAutosave()
        persistSnapshot()
    }

    func stop(now: Date = .now) {
        guard state == .running || state == .paused else { return }
        if state == .running, let resume = lastResumeAt {
            accumulatedElapsedSeconds += Int(now.timeIntervalSince(resume))
            lastResumeAt = nil
        }
        endedAt = now
        cancelAutosave()
        state = .stopped
        persistSnapshot()
    }

    func setCurrentPage(_ page: Int) {
        guard state == .running || state == .paused else { return }
        let upperBound = book?.totalPages ?? Int.max
        currentPage = max(startingPage, min(page, upperBound))
        persistSnapshot()
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
        startingPage = 0
        currentPage = 0
    }

    // MARK: - Restoration

    func restore(from snapshot: ActiveSessionSnapshot, book: Book, now: Date = .now) {
        guard state == .idle else { return }
        self.book = book
        startedAt = snapshot.startedAt
        endedAt = nil
        accumulatedElapsedSeconds = snapshot.accumulatedElapsedSeconds
        startingPage = snapshot.startingPage
        currentPage = snapshot.currentPage
        if snapshot.isPaused {
            lastResumeAt = nil
            state = .paused
        } else {
            lastResumeAt = now
            state = .running
            scheduleAutosave()
        }
    }

    // MARK: - Cache plumbing

    func persistSnapshot() {
        guard let book else { return }
        let snapshot = ActiveSessionSnapshot(
            bookID: book.id,
            startedAt: startedAt,
            accumulatedElapsedSeconds: liveAccumulated(),
            startingPage: startingPage,
            currentPage: currentPage,
            isPaused: state == .paused,
            lastCheckpointAt: .now
        )
        cache.save(snapshot)
    }

    private func liveAccumulated(now: Date = .now) -> Int {
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
