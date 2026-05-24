import ClerkKit
import FirebaseCore
import RevenueCat
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
    @State private var subscriptionStore: SubscriptionStore = AppEnvironment.makeSubscriptionStore()

    init() {
        Self.configureFirebase()
        Self.configureURLCache()
        Self.configureClerk()
        Self.configureRevenueCat()
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
                .environment(subscriptionStore)
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

    private static func configureRevenueCat() {
        #if DEBUG
            Purchases.logLevel = .info
        #else
            Purchases.logLevel = .warn
        #endif
        Purchases.configure(withAPIKey: AppEnvironment.revenueCatPublicKey)
    }
}
