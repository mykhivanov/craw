import Foundation
import Observation
import os
import SwiftData

/// One-time historical backfill of `daily-stats` aggregates for an active subscriber.
/// Scans all local `ReadingDay` rows, derives a `DailyStatsPayload` per day, and POSTs
/// sequentially. A local resume marker (`UserDefaults`) lets the run resume after
/// interruption — server upserts on `(user_id, date)` so duplicates are harmless.
@Observable
@MainActor
final class StatsBackfillStore {
    enum State: Equatable {
        case idle
        case running(progress: Double)
        case complete
    }

    private(set) var state: State = .idle

    private let completeFlagKey = "crawStatsBackfillComplete"
    private let resumeMarkerKey = "crawStatsBackfillResumeMarker"
    private let logger = Logger(subsystem: "com.mykhivanov.Craw", category: "StatsBackfill")
    private var runningTask: Task<Void, Never>?

    /// True once the backfill has completed (or been determined unnecessary).
    var isComplete: Bool {
        UserDefaults.standard.bool(forKey: completeFlagKey)
    }

    /// Kick off the backfill if conditions are met:
    /// - subscriber has entitlement
    /// - backfill hasn't completed yet
    /// - no run is currently in flight
    /// Caller is fire-and-forget; observe `state` for progress.
    func runIfNeeded(
        in context: ModelContext,
        subscriptionStore: SubscriptionStore
    ) {
        guard !isComplete else {
            state = .complete
            return
        }
        guard subscriptionStore.isEntitled else { return }
        guard runningTask == nil else { return }

        runningTask = Task { [weak self] in
            await self?.run(in: context)
            self?.runningTask = nil
        }
    }

    private func run(in context: ModelContext) async {
        let days = fetchAllDaysWithMinutes(in: context)
        let resumeAfter = resumeMarkerDate()
        let pending = days.filter { day in
            guard let resumeAfter else { return true }
            return day.date > resumeAfter
        }

        guard !pending.isEmpty else {
            markComplete()
            return
        }

        state = .running(progress: 0)
        let total = pending.count
        let client = AppEnvironment.liveAPIClient

        for (index, day) in pending.enumerated() {
            let payload = DailyStatsAggregator.aggregate(for: day.date, in: context)
            do {
                _ = try await client.postDailyStats(payload)
                setResumeMarker(day.date)
            } catch APIError.subscriptionRequired {
                logger.notice("Backfill stopped: subscription no longer active")
                state = .idle
                return
            } catch APIError.cancelled {
                state = .idle
                return
            } catch {
                logger
                    .error(
                        "Backfill failed on \(payload.date, privacy: .public); aborting run: \(String(describing: error), privacy: .public)"
                    )
                state = .idle
                return
            }
            state = .running(progress: Double(index + 1) / Double(total))
        }

        markComplete()
    }

    private func markComplete() {
        UserDefaults.standard.set(true, forKey: completeFlagKey)
        state = .complete
    }

    private func resumeMarkerDate() -> Date? {
        UserDefaults.standard.object(forKey: resumeMarkerKey) as? Date
    }

    private func setResumeMarker(_ date: Date) {
        UserDefaults.standard.set(date, forKey: resumeMarkerKey)
    }

    private func fetchAllDaysWithMinutes(in context: ModelContext) -> [ReadingDay] {
        let descriptor = FetchDescriptor<ReadingDay>(
            predicate: #Predicate { $0.minutesRead > 0 },
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }
}
