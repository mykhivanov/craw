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
    var dateAdded: Date
    /// Stored as String because #Predicate can't traverse enum cases as key paths.
    /// Lightweight migration uses the declaration-site default for old rows.
    var attitudeRaw: String = BookAttitude.entertainment.rawValue
    var isFinished: Bool = false
    var finishedAt: Date?

    var attitude: BookAttitude {
        get { BookAttitude(rawValue: attitudeRaw) ?? .entertainment }
        set { attitudeRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        remoteID: String? = nil,
        title: String,
        author: String,
        coverAssetName: String? = nil,
        coverImageURL: URL? = nil,
        isbn: String? = nil,
        totalPages: Int,
        dateAdded: Date = .now,
        attitude: BookAttitude,
        isFinished: Bool = false,
        finishedAt: Date? = nil
    ) {
        self.id = id
        self.remoteID = remoteID
        self.title = title
        self.author = author
        self.coverAssetName = coverAssetName
        self.coverImageURL = coverImageURL
        self.isbn = isbn
        self.totalPages = totalPages
        self.dateAdded = dateAdded
        attitudeRaw = attitude.rawValue
        self.isFinished = isFinished
        self.finishedAt = finishedAt
    }
}

enum BookAttitude: String, Codable, CaseIterable {
    case entertainment
    case study
}

enum BookStatus {
    case inProgress
    case finished
}

extension Book {
    var status: BookStatus {
        isFinished ? .finished : .inProgress
    }
}
