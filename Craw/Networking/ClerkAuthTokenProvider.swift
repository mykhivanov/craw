import ClerkKit
import Foundation

struct ClerkAuthTokenProvider: AuthTokenProvider {
    func currentToken(forceRefresh: Bool) async throws -> String {
        guard Clerk.shared.user != nil else {
            throw APIError.unauthorized
        }
        guard let token = try await Clerk.shared.auth.getToken(.init(skipCache: forceRefresh)) else {
            throw APIError.unauthorized
        }
        return token
    }
}
