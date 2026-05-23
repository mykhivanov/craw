import Foundation
import SwiftData

@Model
final class Quote {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var text: String
    var pageNumber: Int?
    var capturedAt: Date

    init(
        id: UUID = UUID(),
        bookID: UUID,
        text: String,
        pageNumber: Int? = nil,
        capturedAt: Date = .now
    ) {
        self.id = id
        self.bookID = bookID
        self.text = text
        self.pageNumber = pageNumber
        self.capturedAt = capturedAt
    }
}
