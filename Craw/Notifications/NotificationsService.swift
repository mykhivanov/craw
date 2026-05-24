import Foundation
import Observation
import UIKit
import UserNotifications

@Observable
@MainActor
final class NotificationsService {
    static let shared = NotificationsService()

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    private(set) var fcmToken: String?
    private(set) var lastRegistrationError: String?

    private let center: UNUserNotificationCenter
    private let reminderIdentifierPrefix = "craw.reminder.weekday."

    private init(center: UNUserNotificationCenter = .current()) {
        self.center = center
    }

    var pushDisabledViaLaunchArg: Bool {
        #if DEBUG
            return UserDefaults.standard.bool(forKey: "CrawDisablePushNotifications")
        #else
            return false
        #endif
    }

    func refreshAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async -> UNAuthorizationStatus {
        if pushDisabledViaLaunchArg {
            authorizationStatus = .denied
            return .denied
        }
        do {
            _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            lastRegistrationError = error.localizedDescription
        }
        await refreshAuthorizationStatus()
        return authorizationStatus
    }

    func registerForRemoteNotifications() {
        guard !pushDisabledViaLaunchArg else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func scheduleDailyReminders(weekdays: Set<Weekday>, time: DateComponents) async {
        await clearScheduledReminders()
        guard let hour = time.hour, let minute = time.minute else { return }
        for day in weekdays {
            var trigger = DateComponents()
            trigger.weekday = day.rawValue
            trigger.hour = hour
            trigger.minute = minute

            let content = UNMutableNotificationContent()
            content.title = "Time to read"
            content.body = "A small nudge — open Craw and chip away at your goal."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "\(reminderIdentifierPrefix)\(day.rawValue)",
                content: content,
                trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: true)
            )
            do {
                try await center.add(request)
            } catch {
                lastRegistrationError = error.localizedDescription
            }
        }
    }

    func clearScheduledReminders() async {
        let pending = await center.pendingNotificationRequests()
        let ids = pending.map(\.identifier).filter { $0.hasPrefix(reminderIdentifierPrefix) }
        guard !ids.isEmpty else { return }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    func didReceiveFCMToken(_ token: String?) {
        fcmToken = token
    }
}
