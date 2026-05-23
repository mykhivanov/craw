import Foundation
import SwiftData

enum BookLibraryReader {
    static var inProgressPredicate: Predicate<Book> {
        #Predicate { $0.currentPage < $0.totalPages }
    }

    static var finishedPredicate: Predicate<Book> {
        #Predicate { $0.currentPage >= $0.totalPages }
    }

    static var defaultSort: [SortDescriptor<Book>] {
        [SortDescriptor(\.dateAdded, order: .reverse)]
    }
}
