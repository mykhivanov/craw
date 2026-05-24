import Foundation

protocol BookSearchService: Sendable {
    func search(query: String, offset: Int) async throws -> BookSearchPage
}

struct LiveBookSearchService: BookSearchService {
    let client: CrawAPIClient

    func search(query: String, offset: Int) async throws -> BookSearchPage {
        try await client.searchBooks(query: query, limit: 20, offset: offset)
    }
}

#if DEBUG
    struct MockBookSearchService: BookSearchService {
        func search(query: String, offset _: Int) async throws -> BookSearchPage {
            try await Task.sleep(nanoseconds: 200_000_000)
            let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
            let fixtures: [SearchBookDTO] = [
                SearchBookDTO(
                    id: "bk_mock_1",
                    title: "Atomic Habits",
                    author: "James Clear",
                    totalPages: 320,
                    coverImageURL: nil,
                    isbn: "9780735211292"
                ),
                SearchBookDTO(
                    id: "bk_mock_2",
                    title: "Deep Work",
                    author: "Cal Newport",
                    totalPages: 296,
                    coverImageURL: nil,
                    isbn: "9781455586691"
                ),
                SearchBookDTO(
                    id: "bk_mock_3",
                    title: "Thinking, Fast and Slow",
                    author: "Daniel Kahneman",
                    totalPages: 499,
                    coverImageURL: nil,
                    isbn: "9780374533557"
                )
            ]
            let filtered = fixtures.filter { item in
                trimmed.isEmpty || item.title.localizedCaseInsensitiveContains(trimmed) || item.author
                    .localizedCaseInsensitiveContains(trimmed)
            }
            return BookSearchPage(items: filtered, nextOffset: nil)
        }
    }
#endif
