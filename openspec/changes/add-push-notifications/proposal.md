## Why

Craw's onboarding `ScheduleStep` already asks the user to pick reading days and a reminder time — but the app doesn't act on the answers. The whole step is a UI promise the app can't keep. At the same time we have no re-engagement channel for the backend: if a user goes silent for a week, there's no way for the server to bring them back. Both gaps point to the same missing infrastructure — push notifications.

This change wires up local daily reading reminders (delivering on the schedule the user already configures) AND server-targetable remote push via Firebase Cloud Messaging. The Firebase project is already provisioned (`GoogleService-Info.plist` is in the bundle with `IS_GCM_ENABLED = true`); only the SDK and the in-app plumbing are missing.

The permission prompt is surfaced inline in the existing `ScheduleStep` as a "Turn on reminders" toggle, rather than as a new dedicated onboarding step — keeping the funnel at six steps and tying the prompt directly to the schedule the user just configured.

## What Changes

- **Add Firebase SDK** (`FirebaseCore` + `FirebaseMessaging`) via SwiftPM. No Analytics, no Crashlytics — push only.
- **Configure Firebase** in `CrawApp.init()` via `FirebaseApp.configure()` before Clerk configures. Disable method swizzling (`FirebaseAppDelegateProxyEnabled = NO` in `Info.plist`) and forward APNs tokens to `Messaging.messaging().apnsToken` manually, so Clerk's deep-link handling stays untouched.
- **Add `CrawAppDelegate`** wired via `@UIApplicationDelegateAdaptor` on `CrawApp`. Conforms to `UIApplicationDelegate`, `MessagingDelegate`, `UNUserNotificationCenterDelegate`. Forwards FCM token + APNs token; presents foreground notifications as banners.
- **Add `NotificationsService`** (`@Observable @MainActor`, singleton): tracks `authorizationStatus`, holds the latest `fcmToken`, requests authorization, schedules and clears local reminders. Honors `-CrawDisablePushNotifications` in DEBUG (matches existing `-CrawMockSearch` / `-CrawSkipOnboarding` patterns).
- **Add local daily reminders** via `UNCalendarNotificationTrigger` — one repeating trigger per selected `Weekday`, request identifier `craw.reminder.weekday.<rawValue>` for stable replacement. Re-scheduled automatically when the user edits weekdays or reminder time.
- **Add `DeviceRegistrationCoordinator`** (`@Observable @MainActor`) that POSTs the FCM token to a new `POST /devices` backend endpoint **only when both** the FCM token has arrived AND the Clerk-backed session has bootstrapped. Suppresses duplicate posts (compares to last sent token); handles token rotation; tolerates `404` from a not-yet-deployed backend.
- **Extend `CrawAPIClient`** with `registerDevice(token:platform:appVersion:locale:)` that POSTs to `/devices` and decodes an `APIDevice` response. Reuses the existing `sendOnce` pipeline (JWT attach, 401-retry).
- **Update `ScheduleStep` UI** with a third `reminderToggleCard` below the existing reminder time card. Bell icon, "Turn on reminders" title, inline copy explaining *why* ("We'll send a gentle nudge at this time so a missed day doesn't become a missed week."), `Toggle`. Toggle-on triggers system permission prompt → grant schedules locals + registers for remote; deny reverts the toggle and surfaces an inline "Open Settings" link.
- **Extend `OnboardingState`** with `wantsReminders: Bool` and `reminderAuthorizationStatus: UNAuthorizationStatus` — in-memory only, matching the existing pattern (onboarding answers don't persist; iOS remembers the real auth grant).
- **Wire `AuthGate`** to refresh authorization status on appear, signal `DeviceRegistrationCoordinator.sessionDidBecomeReady()` when `AuthSessionStore.status` transitions to `.ready`, and clear local reminders + reset the coordinator on sign-out.
- **Update entitlements** — add `aps-environment = development` to `Craw.entitlements` (Xcode flips to `production` for release archives once the Push Notifications capability is enabled in Signing & Capabilities).
- **Define the backend `/devices` contract** in `api-contract.yaml`: `POST /devices` with `{ token, platform: "ios", app_version, locale }`, idempotent on `(user_id, token)`, returns the persisted `Device` record. `User.devices[]` is left as a future optional extension to avoid breaking the existing `APIUser` decoder.

## Capabilities

### New Capabilities
- `push-notifications`: local reading reminders + Firebase Cloud Messaging registration, with a Settings-deep-link fallback when permission is denied.

### Modified Capabilities
- `onboarding`: `ScheduleStep` gains an inline reminders toggle that triggers the system permission prompt and arms local reminders.
- `auth`: `AuthSessionStore.BootstrapStatus` becomes `Equatable` so views can observe transitions via `.onChange`. On sign-out, scheduled local reminders are cleared.
- `api-client`: gains `POST /devices` for device registration.

## Impact

- **New code:** `Craw/Notifications/NotificationsService.swift`, `Craw/Notifications/DeviceRegistrationCoordinator.swift`, `Craw/AppShell/CrawAppDelegate.swift`.
- **Modified code:** `Craw/CrawApp.swift` (Firebase configure + AppDelegate adaptor + env injection), `Craw/AppShell/AuthGate.swift` (auth-status refresh + session-ready signal + sign-out cleanup), `Craw/Onboarding/OnboardingState.swift` (new fields), `Craw/Onboarding/Steps/ScheduleStep.swift` (reminderToggleCard + onChange reschedule), `Craw/Onboarding/OnboardingView.swift` (preview env), `Craw/Networking/CrawAPIClient.swift` (`registerDevice` + `performWithBody` helper), `Craw/Networking/APIModels.swift` (`APIDevice`, `APIDeviceRegistration`), `Craw/Auth/AppEnvironment.swift` (`makeDeviceRegistrationCoordinator` factory), `Craw/Auth/AuthSessionStore.swift` (`BootstrapStatus: Equatable`).
- **Configuration:** `Craw/Craw.entitlements` adds `aps-environment`. `Craw/Info.plist` adds `FirebaseAppDelegateProxyEnabled = false`.
- **Dependencies (SwiftPM):** add `https://github.com/firebase/firebase-ios-sdk` — products `FirebaseCore` + `FirebaseMessaging`.
- **Xcode capability:** enable **Push Notifications** in target → Signing & Capabilities (only Xcode UI can register the capability flag in `project.pbxproj`).
- **Backend contract:** see `api-contract.yaml` — single new endpoint `POST /devices`, idempotent on `(user_id, token)`.
- **DEBUG launch arg:** `-CrawDisablePushNotifications YES` short-circuits the system prompt and APNs registration so simulator iteration doesn't prompt every cold launch. Local reminders still schedule (and fire on simulator).

## Non-goals

- A Settings screen to edit weekdays / reminder time post-onboarding (today the only way to change them is to reinstall; iOS Settings is the only escape if the user denies permission).
- Silent / background push (`UIBackgroundModes = remote-notification`) for data sync.
- Push-driven Live Activities (the existing `NSSupportsLiveActivities` key is unrelated; remote-driven LA updates use a separate APNs channel).
- Server-side device deregister on sign-out (client clears local reminders only).
- Rich notification payloads, deep links into specific books, or audience segmentation.
- Analytics on notification opens or delivery.
