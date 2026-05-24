import ClerkKit
import FirebaseCore
import SwiftData
import SwiftUI

@main
struct CrawApp: App {
    let container: ModelContainer

    @UIApplicationDelegateAdaptor(CrawAppDelegate.self) private var appDelegate

    @State private var sessionEngine: SessionEngine = .shared
    @State private var notifications: NotificationsService = .shared
    @State private var deviceRegistration: DeviceRegistrationCoordinator = AppEnvironment
        .makeDeviceRegistrationCoordinator()

    init() {
        Self.configureFirebase()
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
                .environment(notifications)
                .environment(deviceRegistration)
        }
        .modelContainer(container)
    }

    private static func configureFirebase() {
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
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
