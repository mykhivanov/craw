import Foundation
import SwiftData

enum BookLibraryReader {
    static var inProgressPredicate: Predicate<Book> {
        #Predicate { $0.isFinished == false }
    }

    static var finishedPredicate: Predicate<Book> {
        #Predicate { $0.isFinished == true }
    }

    /// #Predicate can't reference enum cases via key path, so compare the persisted raw string.
    static var inProgressEntertainmentPredicate: Predicate<Book> {
        let raw = BookAttitude.entertainment.rawValue
        return #Predicate { $0.isFinished == false && $0.attitudeRaw == raw }
    }

    static var inProgressStudyPredicate: Predicate<Book> {
        let raw = BookAttitude.study.rawValue
        return #Predicate { $0.isFinished == false && $0.attitudeRaw == raw }
    }

    static var defaultSort: [SortDescriptor<Book>] {
        [SortDescriptor(\.dateAdded, order: .reverse)]
    }

    static var finishedSort: [SortDescriptor<Book>] {
        [SortDescriptor(\.finishedAt, order: .reverse), SortDescriptor(\.dateAdded, order: .reverse)]
    }
}
