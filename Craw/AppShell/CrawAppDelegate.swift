import FirebaseCore
import FirebaseMessaging
import os
import UIKit
import UserNotifications

final class CrawAppDelegate: NSObject, UIApplicationDelegate {
    private let logger = Logger(subsystem: "com.mykhivanov.Craw", category: "AppDelegate")

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // FirebaseApp.configure() is invoked from CrawApp.init() before this delegate runs.
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        return true
    }

    func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        // Swizzling is disabled via FirebaseAppDelegateProxyEnabled=NO in Info.plist —
        // manually forward the APNs token so Firebase can pair it with the FCM registration.
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        logger.error("APNs registration failed: \(error.localizedDescription, privacy: .public)")
        Task { @MainActor in
            NotificationsService.shared.didReceiveFCMToken(nil)
        }
    }
}

extension CrawAppDelegate: MessagingDelegate {
    func messaging(_: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        logger.info("Received FCM token (length=\(fcmToken?.count ?? 0, privacy: .public))")
        Task { @MainActor in
            NotificationsService.shared.didReceiveFCMToken(fcmToken)
        }
    }
}

extension CrawAppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }
}
