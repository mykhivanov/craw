import ClerkKit
import SwiftData
import SwiftUI

@main
struct CrawApp: App {
    let container: ModelContainer

    @State private var sessionEngine: SessionEngine = .shared

    init() {
        Self.configureURLCache()
        Self.configureClerk()
        container = CrawModelContainer.live()
        LiveActivityActionObserver.shared.start()
        #if DEBUG
            if SampleData.isLaunchArgumentEnabled {
                SampleData.seedIfEmpty(into: ModelContext(container))
            }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            AuthGate()
                .environment(sessionEngine)
                .environment(Clerk.shared)
        }
        .modelContainer(container)
    }

    private static func configureURLCache() {
        URLCache.shared = URLCache(
            memoryCapacity: 10 * 1024 * 1024,
            diskCapacity: 50 * 1024 * 1024,
            diskPath: "craw-url-cache"
        )
    }

    private static func configureClerk() {
        let key = AppEnvironment.clerkPublishableKey
        Clerk.configure(
            publishableKey: key,
            options: Clerk.Options(
                redirectConfig: .init(
                    redirectUrl: "com.mykhivanov.Craw://clerk-callback",
                    callbackUrlScheme: "com.mykhivanov.Craw"
                )
            )
        )
    }
}
