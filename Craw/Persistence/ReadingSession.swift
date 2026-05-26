import Foundation
import SwiftData

@Model
final class ReadingSession {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var startedAt: Date
    var endedAt: Date
    var elapsedSeconds: Int
    var sectionOrPageHint: String?
    var quizMark: Int?

    init(
        id: UUID = UUID(),
        bookID: UUID,
        startedAt: Date,
        endedAt: Date,
        elapsedSeconds: Int,
        sectionOrPageHint: String? = nil,
        quizMark: Int? = nil
    ) {
        self.id = id
        self.bookID = bookID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedSeconds = elapsedSeconds
        self.sectionOrPageHint = sectionOrPageHint
        self.quizMark = quizMark
    }
}
