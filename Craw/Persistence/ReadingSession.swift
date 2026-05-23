import Foundation
import SwiftData

enum VerificationState: String, Codable, CaseIterable {
    case pending
    case verified
    case failed
    case skipped
    case unavailable
}

@Model
final class ReadingSession {
    @Attribute(.unique) var id: UUID
    var bookID: UUID
    var startedAt: Date
    var endedAt: Date
    var elapsedSeconds: Int
    var pagesRead: Int
    var verificationRaw: String
    var reflectionText: String

    init(
        id: UUID = UUID(),
        bookID: UUID,
        startedAt: Date,
        endedAt: Date,
        elapsedSeconds: Int,
        pagesRead: Int,
        verification: VerificationState = .pending,
        reflectionText: String = ""
    ) {
        self.id = id
        self.bookID = bookID
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.elapsedSeconds = elapsedSeconds
        self.pagesRead = pagesRead
        verificationRaw = verification.rawValue
        self.reflectionText = reflectionText
    }
}

extension ReadingSession {
    var verification: VerificationState {
        get { VerificationState(rawValue: verificationRaw) ?? .pending }
        set { verificationRaw = newValue.rawValue }
    }
}
