import ActivityKit
import Foundation

enum ReadingActivityPhase: String, Codable {
    case running
    case paused
}

struct ReadingActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var phase: ReadingActivityPhase
        var accumulatedElapsedSeconds: Int
        var lastResumeAt: Date?
        var currentPage: Int
    }

    let bookID: UUID
    let bookTitle: String
    let bookAuthor: String
    let totalPages: Int
    let startedAt: Date
}
