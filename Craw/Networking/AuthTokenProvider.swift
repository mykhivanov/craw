import Foundation

protocol AuthTokenProvider: Sendable {
    func currentToken(forceRefresh: Bool) async throws -> String
}
