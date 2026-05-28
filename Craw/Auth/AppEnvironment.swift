import ClerkKit
import Foundation

enum AppEnvironment {
    static let apiBaseURL: URL = {
        let configured = Bundle.main.infoDictionary?["CRAW_API_BASE_URL"] as? String
        let resolved = configured?.isEmpty == false ? configured! : "https://api.craw.app/v1"
        guard let url = URL(string: resolved) else {
            fatalError("CRAW_API_BASE_URL is not a valid URL: \(resolved)")
        }
        return url
    }()

    static let clerkPublishableKey: String = {
        let value = Bundle.main.infoDictionary?["CLERK_PUBLISHABLE_KEY"] as? String ?? ""
        #if DEBUG
            assert(
                !value.isEmpty,
                "CLERK_PUBLISHABLE_KEY is missing from Info.plist — add it via Xcode build settings (INFOPLIST_KEY_CLERK_PUBLISHABLE_KEY)."
            )
        #endif
        return value
    }()

    static let revenueCatPublicKey: String = {
        let value = Bundle.main.infoDictionary?["REVENUECAT_PUBLIC_KEY"] as? String ?? ""
        #if DEBUG
            if value.isEmpty {
                return "appl_kcwccoejaIlFNlWwefZHjJTtfbm"
            }
        #else
            assert(
                !value.isEmpty,
                "REVENUECAT_PUBLIC_KEY is missing from Info.plist in a RELEASE build."
            )
        #endif
        return value
    }()

    static let liveAPIClient: CrawAPIClient = .init(
        baseURL: apiBaseURL,
        tokenProvider: ClerkAuthTokenProvider()
    )

    @MainActor
    static func makeAuthSessionStore() -> AuthSessionStore {
        AuthSessionStore(apiClient: liveAPIClient) {
            Task { try? await Clerk.shared.auth.signOut() }
        }
    }

    @MainActor
    static func makeSubscriptionStore() -> SubscriptionStore {
        let store = SubscriptionStore()
        Task { [weak store] in
            await liveAPIClient.setSubscriptionGate {
                await MainActor.run { store?.isEntitled ?? false }
            }
        }
        return store
    }

    @MainActor
    static func makeDeviceRegistrationCoordinator() -> DeviceRegistrationCoordinator {
        DeviceRegistrationCoordinator(apiClient: liveAPIClient)
    }

    @MainActor
    static func makeBookSearchStore() -> BookSearchStore {
        let service: BookSearchService
        #if DEBUG
            if UserDefaults.standard.bool(forKey: "CrawMockSearch") {
                service = MockBookSearchService()
            } else {
                service = LiveBookSearchService(client: liveAPIClient)
            }
        #else
            service = LiveBookSearchService(client: liveAPIClient)
        #endif
        return BookSearchStore(service: service) {
            Task { try? await Clerk.shared.auth.signOut() }
        }
    }

    static var quizService: QuizService {
        #if DEBUG
            return MockQuizService()
        #else
            return LiveQuizService(client: liveAPIClient)
        #endif
    }

    static var readingStatsService: ReadingStatsService {
        #if DEBUG
            if UserDefaults.standard.bool(forKey: "CrawMockStats") {
                return MockReadingStatsService()
            }
        #endif
        return LiveReadingStatsService(client: liveAPIClient)
    }

    @MainActor
    static func makeStatsViewModel() -> StatsViewModel {
        StatsViewModel(service: readingStatsService)
    }
}
