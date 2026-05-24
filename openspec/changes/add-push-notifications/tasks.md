## Setup (manual, Xcode UI)

- [ ] Add SwiftPM dep `https://github.com/firebase/firebase-ios-sdk` to the Craw target. Add products **FirebaseCore** + **FirebaseMessaging** only.
- [ ] Target → Signing & Capabilities → **+ Capability** → **Push Notifications**. Confirms `aps-environment` is wired and registers the capability in `project.pbxproj` (entitlements file already updated).
- [ ] Confirm `GoogleService-Info.plist` is included in the Craw target's "Copy Bundle Resources" build phase (it already lives at `Craw/GoogleService-Info.plist` and is auto-synced via `PBXFileSystemSynchronizedRootGroup`).

## App-level wiring

- [x] Add `Craw/AppShell/CrawAppDelegate.swift` — `UIApplicationDelegate` + `MessagingDelegate` + `UNUserNotificationCenterDelegate`. Manually forwards APNs token to `Messaging.messaging().apnsToken`.
- [x] `Craw/CrawApp.swift`: call `FirebaseApp.configure()` from `init()`, add `@UIApplicationDelegateAdaptor(CrawAppDelegate.self)`, inject `NotificationsService` + `DeviceRegistrationCoordinator` into the environment.
- [x] `Craw/Info.plist`: add `FirebaseAppDelegateProxyEnabled = false`.
- [x] `Craw/Craw.entitlements`: add `aps-environment = development`.

## Notifications service

- [x] Add `Craw/Notifications/NotificationsService.swift` — `@Observable @MainActor` singleton with `requestAuthorization`, `registerForRemoteNotifications`, `scheduleDailyReminders(weekdays:time:)`, `clearScheduledReminders`, `didReceiveFCMToken(_:)`, and an `onFCMTokenChange` forwarding hook for the coordinator.
- [x] Honor `-CrawDisablePushNotifications YES` in DEBUG (`UserDefaults.standard.bool(forKey:)`).
- [x] Use stable reminder identifier prefix `craw.reminder.weekday.<rawValue>` so re-scheduling can target only Craw's own pending requests.

## Device registration

- [x] Add `Craw/Notifications/DeviceRegistrationCoordinator.swift` — debounced POST `/devices` when **both** FCM token and `sessionDidBecomeReady()` have fired. Suppresses duplicate posts (compares against `lastSentToken`).
- [x] Tolerate `APIError.notFound` (404) gracefully — log and wait for next signal. Other errors surface via `lastRegistrationError`.
- [x] `Craw/Networking/APIModels.swift`: add `APIDevice` (Decodable, Equatable) + `APIDeviceRegistration` (Encodable) with snake_case `CodingKeys`.
- [x] `Craw/Networking/CrawAPIClient.swift`: add `registerDevice(token:platform:appVersion:locale:)` + a `performWithBody` helper that mirrors `performGet` (401 retry, JWT attach).
- [x] `Craw/Auth/AppEnvironment.swift`: add `makeDeviceRegistrationCoordinator()` factory.

## AuthGate integration

- [x] `Craw/Auth/AuthSessionStore.swift`: make `BootstrapStatus` `Equatable` so `.onChange` can observe it.
- [x] `Craw/AppShell/AuthGate.swift`: refresh auth status on appear, signal `deviceRegistration.sessionDidBecomeReady()` when `sessionStore.status` flips to `.ready`, call `notifications.clearScheduledReminders()` + `deviceRegistration.sessionDidReset()` on sign-out.

## Onboarding UI

- [x] `Craw/Onboarding/OnboardingState.swift`: add `wantsReminders: Bool = false` and `reminderAuthorizationStatus: UNAuthorizationStatus = .notDetermined`. Import `UserNotifications`.
- [x] `Craw/Onboarding/Steps/ScheduleStep.swift`: add third `reminderToggleCard` below `reminderCard`. Bell icon in rauschTint circle, inline "why" copy, `Toggle` bound to a custom `Binding` that triggers the async permission flow. On grant → schedule locals + register remote. On deny → revert toggle, show inline "Open Settings" affordance. `.onChange(of: state.readingWeekdays)` / `.onChange(of: state.reminderTime)` reschedule when active. `.task` calls `notifications.refreshAuthorizationStatus()`.
- [x] Update SwiftUI previews in `ScheduleStep.swift` + `OnboardingView.swift` to inject `NotificationsService.shared`.

## Backend contract

- [x] Define `POST /devices` in `api-contract.yaml` — idempotent upsert on `(user_id, token)`.

## Manual QA

- [ ] Simulator + `-CrawDisablePushNotifications YES`: walk onboarding to ScheduleStep, toggle on → no system prompt; pick a time ~2 minutes ahead → background app → local notification fires.
- [ ] Simulator without disable arg: toggle on → system prompt appears. Grant → reminders scheduled. Toggle off → `getPendingNotificationRequests` (via debugger) drops to zero.
- [ ] Simulator deny path: toggle on → system prompt → tap "Don't Allow" → toggle reverts off, inline "Open Settings" link visible.
- [ ] Real device with signed-in Clerk user: complete onboarding with reminders on. Watch console for `Received FCM token`; confirm `POST /devices` fires once session-ready signal also arrives. Force-quit + relaunch: confirm no duplicate POST (coordinator de-dupe).
- [ ] Edit reminder time after toggling on (re-open `ScheduleStep` in onboarding by relaunching): confirm re-scheduling fires by inspecting pending requests.
- [ ] Sign out from `RootView`: confirm pending Craw notifications are cleared (`UNUserNotificationCenter.current().getPendingNotificationRequests`).
- [ ] Apple sign-in callback URL still routes through `.onOpenURL` (i.e., Clerk's OAuth flow is unbroken).
