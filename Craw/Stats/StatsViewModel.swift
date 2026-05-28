import Foundation
import Observation

@Observable
@MainActor
final class StatsViewModel {
    enum State: Equatable {
        case idle
        case loading
        case loaded(StatsBundle)
        case subscriptionRequired
        case error(String)

        var bundle: StatsBundle? {
            if case let .loaded(bundle) = self { return bundle }
            return nil
        }

        static func == (lhs: State, rhs: State) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.loading, .loading), (.subscriptionRequired, .subscriptionRequired):
                true
            case let (.loaded(a), .loaded(b)):
                a.generatedAt == b.generatedAt && a.period == b.period
            case let (.error(a), .error(b)):
                a == b
            default:
                false
            }
        }
    }

    private(set) var state: State = .idle
    var period: StatsPeriod = .month

    private let service: ReadingStatsService
    private var loadTask: Task<Void, Never>?

    init(service: ReadingStatsService) {
        self.service = service
    }

    func loadIfNeeded() {
        guard case .idle = state else { return }
        load()
    }

    func selectPeriod(_ newPeriod: StatsPeriod) {
        guard newPeriod != period else { return }
        period = newPeriod
        load()
    }

    func reload() {
        load()
    }

    private func load() {
        loadTask?.cancel()
        state = .loading
        let selected = period
        let svc = service
        loadTask = Task { [weak self] in
            do {
                let bundle = try await svc.fetchStats(period: selected)
                guard !Task.isCancelled else { return }
                self?.state = .loaded(bundle)
            } catch APIError.subscriptionRequired {
                self?.state = .subscriptionRequired
            } catch APIError.cancelled {
                return
            } catch {
                self?.state = .error(error.localizedDescription)
            }
        }
    }
}
