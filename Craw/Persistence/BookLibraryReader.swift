import Foundation
import SwiftData

enum BookLibraryReader {
    static var inProgressPredicate: Predicate<Book> {
        #Predicate { $0.currentPage < $0.totalPages }
    }

    static var finishedPredicate: Predicate<Book> {
        #Predicate { $0.currentPage >= $0.totalPages }
    }

    /// #Predicate can't reference enum cases via key path, so compare the persisted raw string.
    static var inProgressEntertainmentPredicate: Predicate<Book> {
        let raw = BookAttitude.entertainment.rawValue
        return #Predicate { $0.currentPage < $0.totalPages && $0.attitudeRaw == raw }
    }

    static var inProgressStudyPredicate: Predicate<Book> {
        let raw = BookAttitude.study.rawValue
        return #Predicate { $0.currentPage < $0.totalPages && $0.attitudeRaw == raw }
    }

    static var defaultSort: [SortDescriptor<Book>] {
        [SortDescriptor(\.dateAdded, order: .reverse)]
    }
}
