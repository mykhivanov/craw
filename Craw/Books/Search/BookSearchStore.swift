import Foundation
import Observation

@Observable
@MainActor
final class BookSearchStore {
    enum State {
        case idle
        case loading
        case results([BookSearchResult])
        case empty(String)
        case error(String)
    }

    private(set) var state: State = .idle
    private(set) var query: String = ""
    private(set) var hasMore: Bool = false

    private let service: BookSearchService
    private let onUnauthorized: @MainActor () -> Void
    private var debounceTask: Task<Void, Never>?
    private var loadTask: Task<Void, Never>?
    private var nextOffset: Int = 0
    private var loadedIDs: Set<String> = []
    private var loadedDedupeKeys: Set<String> = []
    private var loadedResults: [BookSearchResult] = []
    private static let resultCap = 60
    private static let pageSize = 20
    private static let debounceNanos: UInt64 = 350_000_000

    init(service: BookSearchService, onUnauthorized: @escaping @MainActor () -> Void = {}) {
        self.service = service
        self.onUnauthorized = onUnauthorized
    }

    func updateQuery(_ raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != query else { return }
        query = trimmed
        debounceTask?.cancel()
        loadTask?.cancel()
        resetResults()
        if trimmed.isEmpty {
            state = .idle
            return
        }
        debounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: Self.debounceNanos)
            } catch {
                return
            }
            await self?.executeSearch(reset: true)
        }
    }

    func loadMore() {
        guard hasMore, loadTask == nil, !query.isEmpty else { return }
        guard loadedResults.count < Self.resultCap else { return }
        Task { [weak self] in
            await self?.executeSearch(reset: false)
        }
    }

    func retry() {
        guard !query.isEmpty else { return }
        loadTask?.cancel()
        resetResults()
        Task { [weak self] in
            await self?.executeSearch(reset: true)
        }
    }

    private func resetResults() {
        nextOffset = 0
        loadedIDs.removeAll()
        loadedDedupeKeys.removeAll()
        loadedResults.removeAll()
        hasMore = false
    }

    private func executeSearch(reset: Bool) async {
        let snapshotQuery = query
        if reset {
            state = .loading
        }
        let offset = nextOffset
        let currentTask = Task { [service] in
            try await service.search(query: snapshotQuery, offset: offset)
        }
        loadTask = Task { _ = try? await currentTask.value }
        defer { loadTask = nil }
        do {
            let page = try await currentTask.value
            guard snapshotQuery == query else { return }
            absorb(page)
            if loadedResults.isEmpty {
                state = .empty(snapshotQuery)
            } else {
                state = .results(loadedResults)
            }
        } catch APIError.cancelled {
            return
        } catch is CancellationError {
            return
        } catch APIError.unauthorized {
            onUnauthorized()
            state = .error(APIError.unauthorized.userFacingMessage)
        } catch let error as APIError {
            guard snapshotQuery == query else { return }
            state = .error(error.userFacingMessage)
        } catch {
            guard snapshotQuery == query else { return }
            state = .error("Something went wrong. Please try again.")
        }
    }

    private func absorb(_ page: BookSearchPage) {
        for dto in page.items {
            let key = "\(dto.title.lowercased())|\(dto.author.lowercased())"
            if loadedIDs.contains(dto.id) || loadedDedupeKeys.contains(key) {
                continue
            }
            loadedIDs.insert(dto.id)
            loadedDedupeKeys.insert(key)
            loadedResults.append(BookSearchResult(dto: dto))
            if loadedResults.count >= Self.resultCap {
                break
            }
        }
        if let next = page.nextOffset, loadedResults.count < Self.resultCap {
            nextOffset = next
            hasMore = true
        } else {
            hasMore = false
        }
    }
}
