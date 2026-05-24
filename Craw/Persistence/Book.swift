import Foundation
import SwiftData

@Model
final class Book {
    @Attribute(.unique) var id: UUID
    var remoteID: String?
    var title: String
    var author: String
    var coverAssetName: String?
    var coverImageURL: URL?
    var isbn: String?
    var totalPages: Int
    var currentPage: Int
    var dateAdded: Date

    init(
        id: UUID = UUID(),
        remoteID: String? = nil,
        title: String,
        author: String,
        coverAssetName: String? = nil,
        coverImageURL: URL? = nil,
        isbn: String? = nil,
        totalPages: Int,
        currentPage: Int = 0,
        dateAdded: Date = .now
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.author = author
        self.coverAssetName = coverAssetName
        self.coverImageURL = coverImageURL
        self.isbn = isbn
        self.totalPages = totalPages
        self.currentPage = currentPage
        self.dateAdded = dateAdded
    }
}

enum BookStatus {
    case notStarted
    case inProgress
    case finished
}

extension Book {
    var status: BookStatus {
        if currentPage <= 0 { return .notStarted }
        if currentPage >= totalPages { return .finished }
        return .inProgress
    }

    var progressFraction: Double {
        guard totalPages > 0 else { return 0 }
        return min(1.0, max(0.0, Double(currentPage) / Double(totalPages)))
    }
}
