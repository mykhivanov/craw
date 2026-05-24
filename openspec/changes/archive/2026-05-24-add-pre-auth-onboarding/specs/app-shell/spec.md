## MODIFIED Requirements

### Requirement: Authentication gate at scene root

The app SHALL wrap `RootView` in an `AuthGate` view that observes `Clerk.shared.isLoaded` and `Clerk.shared.user`, plus an in-memory `OnboardingState` instance owned by the gate. The gate SHALL render exactly one of four branches at a time:
- Splash (per `auth` capability) when `isLoaded == false`.
- Onboarding flow (per `onboarding` capability) when `isLoaded == true && user == nil && !onboardingState.isCompleted` and the debug-skip launch arg is not set.
- Auth entry screen (per `auth` capability) when `isLoaded == true && user == nil && (onboardingState.isCompleted || debug-skip launch arg is set)`.
- `RootView` when `isLoaded == true && user != nil`.

The `onboardingState` instance SHALL be created as `@State` on `AuthGate` and SHALL survive sign-in/sign-out within the same process; only a cold launch SHALL create a fresh instance. The `onboardingState` SHALL NOT be reset by sign-out.

#### Scenario: Cold launch unsigned shows onboarding

- **WHEN** the user opens the app from a closed state with no Clerk session
- **AND** `Clerk.isLoaded` becomes `true`
- **THEN** the gate renders the onboarding flow at step 1
- **AND** the auth entry screen is NOT visible

#### Scenario: Completing onboarding swaps in the auth screen

- **WHEN** the user taps "Continue" on the final onboarding step
- **AND** `Clerk.isLoaded == true && user == nil`
- **THEN** the gate renders the auth entry screen (`AuthView`)
- **AND** the onboarding view is removed from the hierarchy

#### Scenario: Sign-in transitions gate to RootView

- **WHEN** the user completes sign-in and `Clerk.shared.user` becomes non-nil
- **THEN** the gate renders `RootView`
- **AND** no transient flash of `AuthView` or the onboarding flow is visible

#### Scenario: Sign-out transitions gate to AuthView (not onboarding)

- **WHEN** the user signs out from the Profile tab within the same process
- **AND** `Clerk.shared.user` becomes nil
- **THEN** the gate renders the auth entry screen
- **AND** the onboarding flow is NOT re-presented because `onboardingState.isCompleted` is still `true` within this process

#### Scenario: Debug-skip launch argument bypasses onboarding

- **WHEN** a DEBUG build is launched with `-CrawSkipOnboarding YES` and no Clerk session
- **THEN** the gate renders the auth entry screen directly after the splash
- **AND** the onboarding flow is not rendered
