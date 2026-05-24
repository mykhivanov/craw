# app-shell Specification

## Purpose
TBD - created by archiving change add-home-dashboard. Update Purpose after archive.
## Requirements
### Requirement: Root tab-based navigation

The app SHALL present a root `TabView` with exactly four tabs in this order: Home, Quotes, Stats, Profile. The Home tab SHALL be selected on first launch and on every cold start until tab-state restoration is introduced. The `TabView` SHALL only be rendered when an authenticated Clerk session is active; while no session is active, the auth entry screen owned by the `auth` capability is presented instead.

#### Scenario: Cold launch when signed in lands on Home

- **WHEN** the user opens the app from a closed state with a valid Clerk session restored
- **THEN** the Home tab is the selected tab
- **AND** the Home dashboard is visible

#### Scenario: Cold launch when signed out shows auth screen

- **WHEN** the user opens the app from a closed state with no valid Clerk session
- **THEN** the `TabView` is NOT rendered
- **AND** the auth entry screen is shown instead (per the `auth` capability)

#### Scenario: All four tabs are present when signed in

- **WHEN** the user views the tab bar after sign-in
- **THEN** the tab bar shows four tabs labeled Home, Quotes, Stats, Profile in that order
- **AND** each tab has a distinct SF Symbol icon

### Requirement: Selected-tab tint uses brand accent

The tab bar's selected-state foreground color SHALL be the Rausch accent (`#ff385c`) as defined in `DESIGN.md`. Unselected tabs SHALL use the muted ink color from the design tokens.

#### Scenario: Active tab indicator

- **WHEN** any tab is the currently selected tab
- **THEN** its icon and label render in the Rausch accent color
- **AND** non-selected tabs render in the muted color

### Requirement: Per-tab navigation isolation

Each tab SHALL host its own `NavigationStack` so push navigation within one tab does not affect the navigation state of another tab. Switching tabs SHALL preserve each tab's navigation state for the duration of the app session.

#### Scenario: Pushed view persists when switching away and back

- **WHEN** the user pushes a detail view inside Home, switches to Stats, and switches back to Home
- **THEN** the previously pushed detail view is still visible

### Requirement: Placeholder destinations for non-Home tabs

The Quotes, Stats, and Profile tabs SHALL each render a placeholder view containing the tab name and a short "coming soon" message. Placeholder views SHALL be replaced by later changes and MUST NOT contain interactive behavior beyond rendering.

#### Scenario: Quotes tab placeholder

- **WHEN** the user selects the Quotes tab
- **THEN** a placeholder screen is shown identifying the Quotes feature as not yet implemented

#### Scenario: Stats tab placeholder

- **WHEN** the user selects the Stats tab
- **THEN** a placeholder screen is shown identifying the Stats feature as not yet implemented

#### Scenario: Profile tab placeholder

- **WHEN** the user selects the Profile tab
- **THEN** a placeholder screen is shown identifying the Profile feature as not yet implemented

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

### Requirement: Profile tab exposes sign-out

The Profile tab SHALL contain a visible, labeled "Sign out" affordance. Tapping it SHALL trigger the sign-out flow defined in the `auth` capability. The placeholder content of the Profile tab MAY remain alongside the sign-out affordance until the Profile feature is built out.

#### Scenario: Sign-out affordance is visible

- **WHEN** the user navigates to the Profile tab
- **THEN** a row or button labeled "Sign out" is visible
- **AND** the row reads as a destructive action (e.g., red text or icon, per design tokens)

