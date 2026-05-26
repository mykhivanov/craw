import Foundation
import SwiftData

enum QuotesReader {
    static func quotesPredicate(for bookID: UUID) -> Predicate<Quote> {
        #Predicate { $0.bookID == bookID }
    }

    static var quoteSortNewestFirst: [SortDescriptor<Quote>] {
        [SortDescriptor(\.capturedAt, order: .reverse)]
    }
}
