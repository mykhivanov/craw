## MODIFIED Requirements

### Requirement: Authentication entry screen

The app SHALL present `AuthView(mode: .signInOrUp, isDismissable: false)` full-screen whenever Clerk reports `isLoaded == true && user == nil` AND the in-memory `OnboardingState.isCompleted` is `true` (or the DEBUG launch argument `-CrawSkipOnboarding YES` is set). While `OnboardingState.isCompleted` is `false` and the user is unsigned, the onboarding flow (per the `onboarding` capability) is presented instead. The view SHALL NOT be dismissable by the user; sign-in is the only path forward. The view SHALL appear after onboarding completes on first launch, and SHALL appear directly (without re-presenting onboarding) after sign-out within the same process.

#### Scenario: First-launch user sees onboarding, then the auth screen

- **WHEN** the app launches with no prior Clerk session on disk
- **THEN** after the splash, the user sees the onboarding flow
- **AND** the auth entry screen appears only after the user completes onboarding step 6
- **AND** the tab bar / dashboard is NOT visible at any point before sign-in

#### Scenario: Returning unsigned user (within same process) skips onboarding

- **WHEN** the user has completed onboarding earlier in the current process and then signs out
- **THEN** the auth entry screen is presented immediately
- **AND** the onboarding flow is NOT re-presented

#### Scenario: User cannot bypass the auth screen

- **WHEN** the auth entry screen is displayed
- **THEN** there is no swipe-down, no close button, and no system gesture that dismisses it
- **AND** backgrounding and foregrounding the app returns to the auth screen
