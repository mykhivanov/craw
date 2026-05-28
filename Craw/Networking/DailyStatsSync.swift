import Foundation
import os
import SwiftData

/// Fire-and-forget POST of a daily-stats aggregate. Subscription gating happens inside
/// `CrawAPIClient.postDailyStats`, so callers can invoke this unconditionally — the
/// network won't be touched for non-subscribers.
@MainActor
enum DailyStatsSync {
    private static let logger = Logger(subsystem: "com.mykhivanov.Craw", category: "DailyStatsSync")
    private static let lastSyncedDayKey = "CrawDailyStatsLastSyncedDay"

    /// Aggregate the given day and POST. Caller is fire-and-forget; failures are logged
    /// and dropped (backfill reconciles on next launch).
    static func sync(for date: Date, in context: ModelContext) {
        let payload = DailyStatsAggregator.aggregate(for: date, in: context)
        let client = AppEnvironment.liveAPIClient
        Task.detached(priority: .utility) {
            await postWithRetry(payload, client: client)
        }
    }

    /// On scene-foreground, POST yesterday's aggregate if the local day has rolled over
    /// since the last successful sync. Idempotent — `UserDefaults` tracks the last day
    /// we've already posted.
    static func syncYesterdayIfDayRolled(
        in context: ModelContext,
        calendar: Calendar = .autoupdatingCurrent
    ) {
        let today = calendar.startOfDay(for: .now)
        let lastSynced = UserDefaults.standard.object(forKey: lastSyncedDayKey) as? Date
        guard lastSynced == nil || lastSynced! < today else { return }

        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today) {
            sync(for: yesterday, in: context)
        }
        UserDefaults.standard.set(today, forKey: lastSyncedDayKey)
    }

    private static func postWithRetry(_ payload: DailyStatsPayload, client: CrawAPIClient) async {
        do {
            _ = try await client.postDailyStats(payload)
        } catch APIError.subscriptionRequired {
            // Expected for non-subscribers. Silent. Backfill will reconcile on subscribe.
        } catch APIError.cancelled {
            return
        } catch {
            // One in-process retry, then drop and log.
            do {
                _ = try await client.postDailyStats(payload)
            } catch {
                logger.error(
                    "DailyStatsSync drop after retry for date \(payload.date, privacy: .public): \(String(describing: error), privacy: .public)"
                )
            }
        }
    }
}
