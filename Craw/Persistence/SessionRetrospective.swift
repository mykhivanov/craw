import Foundation
import SwiftData

@Model
final class SessionRetrospective {
    @Attribute(.unique) var id: UUID
    var sessionID: UUID
    var focusDifficulty: Int
    var createdAt: Date

    init(
        id: UUID = UUID(),
        sessionID: UUID,
        focusDifficulty: Int,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sessionID = sessionID
        self.focusDifficulty = focusDifficulty
        self.createdAt = createdAt
    }
}
