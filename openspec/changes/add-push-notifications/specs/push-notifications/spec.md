## ADDED Requirements

### Requirement: Firebase initialization at process start

The app SHALL call `FirebaseApp.configure()` exactly once during `CrawApp.init()`, before any view is rendered and before `Clerk.configure(...)`. The `GoogleService-Info.plist` bundled with the app SHALL be the source of configuration. The Firebase method-swizzling proxy SHALL be disabled by setting `FirebaseAppDelegateProxyEnabled = false` in `Info.plist`; APNs token forwarding SHALL be performed manually in `CrawAppDelegate.application(_:didRegisterForRemoteNotificationsWithDeviceToken:)`.

#### Scenario: First launch initializes Firebase before any networking

- **WHEN** the app launches for the first time
- **THEN** `FirebaseApp.configure()` runs before `Clerk.configure(...)`
- **AND** `FirebaseApp.app()` is non-nil by the time the AppDelegate's `didFinishLaunchingWithOptions` runs

#### Scenario: Clerk URL-callback flow is preserved

- **WHEN** the user completes an OAuth sign-in via Clerk and the OS opens the app via `com.mykhivanov.Craw://clerk-callback`
- **THEN** SwiftUI's `.onOpenURL` receives the URL (because `CrawAppDelegate` does NOT implement `application(_:open:options:)`)
- **AND** Clerk completes the sign-in successfully

### Requirement: Notification permission request gated to user intent

The app SHALL NOT request notification authorization on launch. The system permission prompt SHALL only be triggered when the user explicitly toggles "Turn on reminders" ON in `ScheduleStep`. The toggle UI SHALL include inline copy explaining why reminders help (re-engagement / honoring the schedule the user just configured).

#### Scenario: Permission prompt only appears after explicit toggle

- **WHEN** the user reaches `ScheduleStep` during onboarding
- **THEN** the system permission prompt is NOT shown automatically
- **WHEN** the user toggles "Turn on reminders" ON
- **THEN** `UNUserNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])` is invoked exactly once

#### Scenario: Authorization granted schedules locals and registers for remote

- **WHEN** the system permission prompt returns `.authorized` or `.provisional`
- **THEN** `state.wantsReminders` is set to `true`
- **AND** one repeating `UNCalendarNotificationTrigger` is scheduled for each weekday in `state.readingWeekdays` at `state.reminderTime`
- **AND** `UIApplication.shared.registerForRemoteNotifications()` is invoked to kick off APNs token acquisition

#### Scenario: Authorization denied surfaces Settings deep-link

- **WHEN** the system permission prompt returns `.denied`
- **THEN** `state.wantsReminders` is reverted to `false`
- **AND** an inline note "Notifications are off. Enable them in Settings." is displayed under the toggle card
- **AND** an "Open Settings" button is shown that opens `UIApplication.openSettingsURLString`

### Requirement: Local reminder identifiers are stable

Each scheduled local reminder SHALL use the identifier `craw.reminder.weekday.<Weekday.rawValue>` so that re-scheduling replaces — rather than duplicates — the existing request for that weekday. `NotificationsService.clearScheduledReminders` SHALL remove only requests with this prefix, leaving any non-Craw pending requests untouched.

#### Scenario: Re-scheduling replaces in place

- **GIVEN** Monday is selected with reminder at 08:00 and the corresponding request is pending
- **WHEN** the user changes the reminder time to 09:00 with Monday still selected
- **THEN** the pending request count for `craw.reminder.weekday.2` remains exactly 1
- **AND** its trigger components reflect 09:00

#### Scenario: Removing a weekday removes only that request

- **GIVEN** Monday and Tuesday are selected with corresponding pending requests
- **WHEN** the user de-selects Tuesday
- **THEN** the request for Tuesday is removed
- **AND** the request for Monday remains pending unchanged

### Requirement: FCM token forwarded to backend only when session is ready

The `DeviceRegistrationCoordinator` SHALL POST the FCM token to `/devices` only when **both** the token has been received from Firebase AND the Clerk-backed session has bootstrapped (`AuthSessionStore.status == .ready`). The coordinator SHALL suppress duplicate posts by comparing against the last successfully sent token, and SHALL retry on the next state-change signal if the network call fails.

#### Scenario: Token arrives before session

- **GIVEN** Firebase delivers an FCM token while `AuthSessionStore.status == .idle`
- **WHEN** the session subsequently transitions to `.ready`
- **THEN** `POST /devices` is invoked exactly once with the cached token
- **AND** subsequent re-renders do not re-POST the same token

#### Scenario: Token rotation

- **GIVEN** a successful prior registration with token T1
- **WHEN** Firebase rotates the token to T2 and calls `messaging(_:didReceiveRegistrationToken:)`
- **THEN** `POST /devices` is invoked once with T2 (because T2 ≠ lastSentToken)

#### Scenario: Backend endpoint not yet deployed

- **GIVEN** the backend `/devices` endpoint returns `404`
- **WHEN** the coordinator attempts to register
- **THEN** the error is logged and `lastSentToken` is NOT updated
- **AND** the next session-ready or token-change signal triggers another attempt

### Requirement: Sign-out clears local reminders

When the user signs out (Clerk's `user` transitions from non-nil to nil), the app SHALL invoke `NotificationsService.clearScheduledReminders` and `DeviceRegistrationCoordinator.sessionDidReset`. Remote APNs un-registration is OUT OF SCOPE for v1; the server may retain the device record until a future cleanup change.

#### Scenario: Sign-out clears Craw's pending requests

- **GIVEN** the user is signed in with three scheduled weekday reminders
- **WHEN** the user signs out from the Profile tab
- **THEN** `getPendingNotificationRequests()` returns zero requests with the `craw.reminder.weekday.` prefix
- **AND** the device-registration coordinator's `lastSentToken` is cleared so a subsequent sign-in re-POSTs

### Requirement: Debug launch arg disables push prompts

In DEBUG builds, when the process is launched with the argument `-CrawDisablePushNotifications YES`, the system permission prompt SHALL NOT be shown and remote registration SHALL be skipped. Local notification scheduling SHALL still proceed (so the local-reminders code path can be exercised on simulator without prompting on every cold launch). This argument SHALL have no effect in RELEASE builds.

#### Scenario: Disable arg present

- **GIVEN** the app is launched in DEBUG with `-CrawDisablePushNotifications YES`
- **WHEN** the user toggles "Turn on reminders" ON
- **THEN** no system prompt appears
- **AND** `NotificationsService.requestAuthorization()` returns `.denied`
- **AND** `UIApplication.shared.registerForRemoteNotifications()` is NOT invoked
