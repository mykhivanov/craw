import ActivityKit
import Foundation

@MainActor
final class LiveActivityController {
    static let shared = LiveActivityController()

    private var currentActivityID: String?
    private var queue: Task<Void, Never>?
    private var didReconcile = false

    private init() {}

    func start(engine: SessionEngine) {
        guard let book = engine.book else { return }
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = ReadingActivityAttributes(
            bookID: book.id,
            bookTitle: book.title,
            bookAuthor: book.author,
            startedAt: engine.startedAt
        )
        let state = currentState(for: engine)

        enqueue { [weak self] in
            guard let self else { return }
            await reconcileIfNeeded()
            await endAllExistingActivities()
            do {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: ActivityContent(state: state, staleDate: nil)
                )
                currentActivityID = activity.id
            } catch {
                currentActivityID = nil
            }
        }
    }

    func update(engine: SessionEngine) {
        let state = currentState(for: engine)
        enqueue { [weak self] in
            guard let self else { return }
            await reconcileIfNeeded()
            guard
                let id = currentActivityID,
                let activity = Activity<ReadingActivityAttributes>.activities.first(where: { $0.id == id })
            else { return }
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        enqueue { [weak self] in
            guard let self else { return }
            await reconcileIfNeeded()
            await endAllExistingActivities()
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
            lastResumeAt: lastResumeAt
        )
    }

    private func enqueue(_ work: @escaping @MainActor () async -> Void) {
        let previous = queue
        queue = Task { @MainActor in
            await previous?.value
            await work()
        }
    }

    private func endAllExistingActivities() async {
        for activity in Activity<ReadingActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivityID = nil
    }

    private func reconcileIfNeeded() async {
        guard !didReconcile else { return }
        didReconcile = true
        let existing = Activity<ReadingActivityAttributes>.activities
        switch existing.count {
        case 0:
            currentActivityID = nil
        case 1:
            currentActivityID = existing.first?.id
        default:
            for activity in existing {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivityID = nil
        }
    }
}
