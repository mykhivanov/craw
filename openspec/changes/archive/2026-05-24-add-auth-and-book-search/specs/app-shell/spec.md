## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Authentication gate at scene root

The app SHALL wrap `RootView` in an `AuthGate` view that observes `Clerk.shared.isLoaded` and `Clerk.shared.user`. The gate SHALL render exactly one of three branches at a time:
- Splash (per `auth` capability) when `isLoaded == false`.
- Auth entry screen (per `auth` capability) when `isLoaded == true && user == nil`.
- `RootView` when `isLoaded == true && user != nil`.

#### Scenario: Sign-in transitions gate to RootView

- **WHEN** the user completes sign-in and `Clerk.shared.user` becomes non-nil
- **THEN** the gate renders `RootView`
- **AND** no transient flash of `AuthView` is visible

#### Scenario: Sign-out transitions gate to AuthView

- **WHEN** the user signs out from the Profile tab and `Clerk.shared.user` becomes nil
- **THEN** the gate renders the auth entry screen
- **AND** `RootView` is removed from the view hierarchy

### Requirement: Profile tab exposes sign-out

The Profile tab SHALL contain a visible, labeled "Sign out" affordance. Tapping it SHALL trigger the sign-out flow defined in the `auth` capability. The placeholder content of the Profile tab MAY remain alongside the sign-out affordance until the Profile feature is built out.

#### Scenario: Sign-out affordance is visible

- **WHEN** the user navigates to the Profile tab
- **THEN** a row or button labeled "Sign out" is visible
- **AND** the row reads as a destructive action (e.g., red text or icon, per design tokens)
