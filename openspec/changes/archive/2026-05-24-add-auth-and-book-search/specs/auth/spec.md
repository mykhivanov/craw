## ADDED Requirements

### Requirement: Clerk SDK initialization

The app SHALL configure the Clerk iOS SDK exactly once at process start by calling `Clerk.configure(publishableKey:options:)` with the publishable key read from `Info.plist["CLERK_PUBLISHABLE_KEY"]`. The redirect URL SHALL be `com.mykhivanov.Craw://clerk-callback` and the callback URL scheme SHALL be `com.mykhivanov.Craw`. The shared `Clerk.shared` instance SHALL be injected into the SwiftUI environment via `.environment(Clerk.shared)`.

#### Scenario: First launch initialization

- **WHEN** the app launches for the first time
- **THEN** `Clerk.configure` is called before any view is rendered
- **AND** the shared `Clerk` instance is available via `@Environment(Clerk.self)` in any view

#### Scenario: Missing publishable key in DEBUG

- **WHEN** the app is built without `CLERK_PUBLISHABLE_KEY` set in `Info.plist`
- **AND** the build configuration is DEBUG
- **THEN** an assertion fires at launch describing the missing key
- **AND** the app does not silently fall back to an unauthenticated mode

### Requirement: Authentication entry screen

The app SHALL present `AuthView(mode: .signInOrUp, isDismissable: false)` full-screen whenever Clerk reports `isLoaded == true` and `user == nil`. The view SHALL NOT be dismissable by the user; sign-in is the only path forward. The view SHALL appear before the dashboard on first launch and after sign-out.

#### Scenario: First-launch user sees the auth screen

- **WHEN** the app launches with no prior Clerk session on disk
- **THEN** after the splash, the user sees the auth entry screen
- **AND** the tab bar / dashboard is NOT visible

#### Scenario: User cannot bypass the auth screen

- **WHEN** the auth entry screen is displayed
- **THEN** there is no swipe-down, no close button, and no system gesture that dismisses it
- **AND** backgrounding and foregrounding the app returns to the auth screen

### Requirement: Splash during Clerk session restore

The app SHALL display a branded splash view while `Clerk.shared.isLoaded == false`. The splash SHALL render against the design-system canvas background, include the app logo, and include a `ProgressView`. The splash SHALL be replaced immediately when `isLoaded` becomes `true`.

#### Scenario: Cold launch shows splash briefly

- **WHEN** the app launches and Clerk is restoring session state from disk
- **THEN** the splash view is visible
- **AND** the splash hides as soon as `Clerk.shared.isLoaded` becomes `true`

### Requirement: Post-sign-in routing to dashboard

When `Clerk.shared.user` transitions from `nil` to a non-nil value, the app SHALL replace the auth entry screen with the dashboard (`RootView`) without requiring user action. No additional confirmation dialog SHALL be shown.

#### Scenario: Successful sign-in

- **WHEN** the user completes sign-in or sign-up via `AuthView`
- **THEN** `Clerk.shared.user` becomes non-nil
- **AND** the app immediately displays the dashboard
- **AND** the auth screen is dismissed without further user interaction

### Requirement: Session token retrieval

The system SHALL expose an `AuthTokenProvider` whose default implementation calls `Clerk.shared.auth.getToken()`. The provider SHALL surface the returned JWT to callers, SHALL allow forcing a refresh via `skipCache: true`, and SHALL throw when no session is active.

#### Scenario: Provider returns current token

- **WHEN** a caller invokes `currentToken()` while signed in
- **THEN** the provider returns the JWT string from `Clerk.shared.auth.getToken()`

#### Scenario: Provider throws when signed out

- **WHEN** a caller invokes `currentToken()` while `Clerk.shared.user` is nil
- **THEN** the provider throws an `APIError.unauthorized` (or equivalent typed error)

### Requirement: Backend session bootstrap after sign-in

When `Clerk.shared.user` transitions from `nil` to a non-nil value, the app SHALL issue a single authenticated `POST /v1/auth/session` request against the configured `CRAW_API_BASE_URL`. The request body SHALL be empty. The response SHALL be decoded as the contract's `User` resource and cached in-memory for the duration of the session. A failed bootstrap SHALL NOT prevent the user from reaching the dashboard, but SHALL be retried automatically on the next foreground transition.

#### Scenario: Successful bootstrap

- **WHEN** the user signs in for the first time
- **THEN** the app issues `POST /v1/auth/session` with the current Clerk JWT
- **AND** on 2xx the decoded `User` is cached in memory

#### Scenario: Bootstrap fails transiently

- **WHEN** `POST /v1/auth/session` returns a network error or 5xx
- **THEN** the dashboard is still presented
- **AND** the bootstrap is retried the next time the app returns to the foreground

#### Scenario: Bootstrap returns 401

- **WHEN** `POST /v1/auth/session` returns 401 after the API client's single retry
- **THEN** the app calls `Clerk.shared.auth.signOut()`
- **AND** the auth gate returns the user to the entry screen

### Requirement: Sign-out flow

The Profile tab SHALL contain a "Sign out" affordance that calls `Clerk.shared.auth.signOut()`. On success, the app SHALL return to the auth entry screen. Local SwiftData records SHALL NOT be deleted by sign-out in this version.

#### Scenario: User signs out from Profile tab

- **WHEN** the user taps "Sign out"
- **THEN** Clerk's sign-out method is invoked
- **AND** `Clerk.shared.user` becomes nil
- **AND** the auth entry screen replaces the dashboard
- **AND** previously persisted `Book`, `ReadingDay`, `ReadingSession`, `Quote`, and `Thought` rows remain in the local SwiftData store

#### Scenario: Sign-out network failure

- **WHEN** `Clerk.shared.auth.signOut()` throws
- **THEN** the user remains signed in
- **AND** a one-line error message is shown via the Profile tab
- **AND** the dashboard is still visible
