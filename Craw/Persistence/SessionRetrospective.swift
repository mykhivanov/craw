import Foundation
import SwiftData

@Model
final class SessionRetrospective {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var startDifficulty: Int
    var focusDifficulty: Int
    var enjoyment: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        startDifficulty: Int,
        focusDifficulty: Int,
        enjoyment: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.startDifficulty = startDifficulty
        self.focusDifficulty = focusDifficulty
        self.enjoyment = enjoyment
        self.createdAt = createdAt
    }
}
