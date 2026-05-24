import ActivityKit
import Foundation

@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var activity: Activity<ReadingActivityAttributes>?

    private init() {}

    func start(engine: SessionEngine) {
        guard let book = engine.book else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        end()

        let attributes = ReadingActivityAttributes(
            bookID: book.id,
            bookTitle: book.title,
            bookAuthor: book.author,
            totalPages: book.totalPages,
            startedAt: engine.startedAt
        )
        let state = currentState(for: engine)
        let content = ActivityContent(state: state, staleDate: nil)

        do {
            activity = try Activity.request(attributes: attributes, content: content)
        } catch {
            activity = nil
        }
    }

    func update(engine: SessionEngine) {
        guard let activity else { return }
        let state = currentState(for: engine)
        let content = ActivityContent(state: state, staleDate: nil)
        Task {
            await activity.update(content)
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        let finalContent = activity.content
        Task {
            await activity.end(finalContent, dismissalPolicy: .immediate)
        }
    }

    private func currentState(for engine: SessionEngine) -> ReadingActivityAttributes.ContentState {
        let phase: ReadingActivityPhase = engine.state == .paused ? .paused : .running
        let accumulated: Int
        let lastResumeAt: Date?
        if engine.state == .running, let resume = engine.lastResumeAt {
            accumulated = engine.accumulatedElapsedSeconds
            lastResumeAt = resume
        } else {
            accumulated = engine.liveAccumulated()
            lastResumeAt = nil
        }
        return ReadingActivityAttributes.ContentState(
            phase: phase,
            accumulatedElapsedSeconds: accumulated,
            lastResumeAt: lastResumeAt,
            currentPage: engine.currentPage
        )
    }
}
