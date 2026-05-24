import Foundation
import Observation

@Observable
@MainActor
final class AuthSessionStore {
    enum BootstrapStatus: Equatable {
        case idle
        case inFlight
        case ready(APIUser)
        case transientFailure(String)
    }

    private(set) var status: BootstrapStatus = .idle

    private let apiClient: CrawAPIClient
    private let onUnauthorized: @MainActor () -> Void

    init(apiClient: CrawAPIClient, onUnauthorized: @escaping @MainActor () -> Void) {
        self.apiClient = apiClient
        self.onUnauthorized = onUnauthorized
    }

    func bootstrapIfNeeded() {
        switch status {
        case .ready, .inFlight:
            return
        case .idle, .transientFailure:
            break
        }
        status = .inFlight
        Task { [weak self] in
            await self?.runBootstrap()
        }
    }

    func retryIfTransient() {
        if case .transientFailure = status {
            bootstrapIfNeeded()
        }
    }

    func reset() {
        status = .idle
    }

    private func runBootstrap() async {
        do {
            let user = try await apiClient.bootstrapSession()
            status = .ready(user)
        } catch APIError.unauthorized {
            onUnauthorized()
            status = .idle
        } catch APIError.cancelled {
            status = .idle
        } catch {
            let message: String = if let api = error as? APIError {
                api.userFacingMessage
            } else {
                "Couldn't reach the server."
            }
            status = .transientFailure(message)
        }
    }
}
