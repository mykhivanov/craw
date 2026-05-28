import Foundation

protocol ReadingStatsService: Sendable {
    func fetchStats(period: StatsPeriod) async throws -> StatsBundle
    func fetchMethodology() async throws -> MethodologyDocument
}

struct LiveReadingStatsService: ReadingStatsService {
    let client: CrawAPIClient

    func fetchStats(period: StatsPeriod) async throws -> StatsBundle {
        try await client.fetchUserStats(period: period)
    }

    func fetchMethodology() async throws -> MethodologyDocument {
        try await client.fetchMethodology()
    }
}

#if DEBUG
    struct MockReadingStatsService: ReadingStatsService {
        func fetchStats(period: StatsPeriod) async throws -> StatsBundle {
            try await Task.sleep(nanoseconds: 250_000_000)
            return StatsFixtures.bundle(for: period)
        }

        func fetchMethodology() async throws -> MethodologyDocument {
            try await Task.sleep(nanoseconds: 150_000_000)
            return MethodologyDocument(markdown: StatsFixtures.methodology)
        }
    }
#endif
