## Why

The first thing a new user currently sees is `AuthView`, a sign-in/up form with no framing of what the app does or why it's worth signing up. We need a short, opinionated onboarding flow that introduces the product, captures the user's intent (goal, daily reading time, schedule, yearly target), and warms the user up before the Clerk sign-in screen. Per product direction, the answers captured during onboarding are intentionally **session-scoped** in this first cut — they live only in memory and are discarded if the app is killed, so we can ship the UX without committing to a persistence schema or backend writes for onboarding state.

## What Changes

- Add a 6-step pre-auth onboarding flow rendered between the splash and the auth entry screen. Steps mirror the draft in `.claude/ONBOARDING_DRAFT_DETAILS.md` but are re-implemented in SwiftUI using Craw design tokens (no Lottie, no `BouncyCheckbox`, no inline RN styles).
- Introduce a new `OnboardingState` observable (in-memory only, no SwiftData, no `UserDefaults`) holding step index, selected goals, daily reading minutes, "how to read" acknowledgment, weekday + reminder time selection, and yearly-books target.
- Modify the `AuthGate` routing so that when `Clerk.isLoaded == true && user == nil`, the gate first renders `OnboardingView` and only swaps to `AuthView` after onboarding finishes within the current process. Cold-launching the app always restarts from step 1 — there is no resume.
- Replace the React-Native widgets from the draft with SwiftUI equivalents already idiomatic to this codebase: a top dot-progress indicator, primary button styled per `Theme`, native `DatePicker` (or wheel `Picker`) for time selection, weekday chip row, single-select cards with Rausch accent border for the yearly-goal step.
- Skip the Lottie animations from the draft for v1 (replace with SF Symbols or static illustration placeholders) — animated illustrations can be revisited in a follow-up if needed.
- Skip the notification permission request and `setupNotifications()` call from the RN draft. Onboarding only **captures** the desired schedule into in-memory state; actually scheduling local notifications and prompting for permission is out of scope for this change.

## Capabilities

### New Capabilities
- `onboarding`: Session-scoped, pre-auth introduction flow that walks the user through six steps (Welcome, Pick Goal, Daily Reading Time, How To Read, Schedule, Books Per Year) and hands off to the auth entry screen.

### Modified Capabilities
- `app-shell`: The auth gate gains a fourth routing branch — when `isLoaded == true && user == nil`, the gate renders `OnboardingView` until the in-memory `OnboardingState.isCompleted` flag is set, then swaps to `AuthView`.
- `auth`: The "Authentication entry screen" requirement is tightened — `AuthView` is presented when `isLoaded == true && user == nil` **and** onboarding is complete in the current session. Behavior on sign-out is unchanged (post-sign-out we return to the auth screen, not to onboarding, since onboarding only runs before the user's first sign-in attempt of the session).

## Impact

- **New files** (under `Craw/Onboarding/`): `OnboardingState.swift` (observable), `OnboardingView.swift` (host with dot-progress + step routing), one view per step (`WelcomeStep.swift`, `GoalStep.swift`, `DailyTimeStep.swift`, `HowToReadStep.swift`, `ScheduleStep.swift`, `YearlyGoalStep.swift`), plus small components (`OnboardingDotProgress.swift`, `OnboardingPrimaryButton.swift` if not satisfied by existing `Theme`).
- **Modified files**: `Craw/AppShell/AuthGate.swift` (new branch + `OnboardingState` instantiation), possibly `Craw/CrawApp.swift` if the state is hoisted higher.
- **No** changes to `CrawAPIClient`, SwiftData schema, Clerk configuration, networking, or `Info.plist`.
- **No** new SwiftPM dependencies. (Lottie is intentionally out.)
- **Tests**: There is no test target in the project yet, so verification is manual via simulator + the existing launch-arg conventions. A new debug launch argument `-CrawSkipOnboarding YES` is proposed so engineers iterating on post-auth flows don't have to click through onboarding every cold launch.
