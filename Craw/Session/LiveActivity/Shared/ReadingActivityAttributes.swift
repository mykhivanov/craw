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
    }

    let bookID: UUID
    let bookTitle: String
    let bookAuthor: String
    let startedAt: Date
}
