import Foundation
import SwiftData

enum QuotesThoughtsReader {
    static func quotesPredicate(for bookID: UUID) -> Predicate<Quote> {
        #Predicate { $0.bookID == bookID }
    }

    static func thoughtsPredicate(for bookID: UUID) -> Predicate<Thought> {
        #Predicate { $0.bookID == bookID }
    }

    static var quoteSortNewestFirst: [SortDescriptor<Quote>] {
        [SortDescriptor(\.capturedAt, order: .reverse)]
    }

    static var thoughtSortNewestFirst: [SortDescriptor<Thought>] {
        [SortDescriptor(\.capturedAt, order: .reverse)]
    }
}
