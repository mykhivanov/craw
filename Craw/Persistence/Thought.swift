import Foundation
import SwiftData

@Model
final class Thought {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var text: String
    var capturedAt: Date

    init(
        id: UUID = UUID(),
        bookID: UUID,
        text: String,
        capturedAt: Date = .now
    ) {
        self.id = id
        self.bookID = bookID
        self.text = text
        self.capturedAt = capturedAt
    }
}
