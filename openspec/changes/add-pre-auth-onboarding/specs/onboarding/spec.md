## ADDED Requirements

### Requirement: Pre-auth onboarding flow

The app SHALL present a six-step onboarding flow to any user who is not signed in, before the auth entry screen is shown. The steps SHALL appear in this fixed order: (1) Welcome, (2) Pick Goal, (3) Daily Reading Time, (4) How To Read, (5) Schedule, (6) Books Per Year. The flow SHALL be linear — there is no skip-all affordance, and the user MUST tap "Continue" on every step to advance.

#### Scenario: First-launch unsigned user enters the flow at step 1

- **WHEN** the app launches with no Clerk session restored
- **AND** `Clerk.isLoaded` becomes `true`
- **THEN** the splash is replaced by the onboarding flow at step 1 (Welcome)
- **AND** the auth entry screen is NOT yet visible

#### Scenario: Tapping Continue advances to the next step

- **WHEN** the user taps the primary "Continue" button on any step from 1 through 5
- **THEN** the next step in the fixed order replaces the current step
- **AND** the dot-progress indicator advances by one

#### Scenario: Tapping Continue on the final step routes to auth

- **WHEN** the user taps "Continue" on step 6 (Books Per Year)
- **THEN** the onboarding flow is replaced by the auth entry screen (`AuthView`) within the same gate decision
- **AND** the dot-progress indicator is no longer visible

### Requirement: Onboarding state is session-scoped only

The system SHALL hold all onboarding answers — selected goals, daily reading minutes, "how to read" acknowledgment, reading weekdays, reminder time, yearly-books target, and the current step index — in an in-memory `OnboardingState` observable. The system SHALL NOT write any onboarding answer to disk (SwiftData, `UserDefaults`, the Keychain, or the file system) and SHALL NOT send any onboarding answer over the network in this version.

#### Scenario: Cold launch always restarts the flow

- **WHEN** the user closes the app from the Welcome step (or any other step) by killing the process
- **AND** the user re-launches the app while still signed out
- **THEN** the onboarding flow starts at step 1 with no prior answers selected
- **AND** no `UserDefaults` key, SwiftData row, or network request relating to onboarding answers has been written

#### Scenario: Backgrounding within a session preserves answers

- **WHEN** the user is on step 4 with goals selected on step 2 and a daily-time value on step 3
- **AND** the user backgrounds the app and returns within the same process lifetime
- **THEN** the user is still on step 4
- **AND** the previously chosen goals and daily-time value are still selected

### Requirement: Onboarding completion is per-session

The system SHALL expose an `isCompleted` flag on `OnboardingState` that flips from `false` to `true` exactly when the user taps "Continue" on step 6. Once `isCompleted` is `true` within a process lifetime, the system SHALL NOT re-present the onboarding flow even if the user signs out and the gate returns to the unsigned branch. A subsequent cold launch SHALL reset `isCompleted` to `false`.

#### Scenario: Sign-out within the same session does not replay onboarding

- **WHEN** the user completes onboarding, signs in, then signs out via the Profile tab — all without killing the app
- **THEN** the gate returns to the unsigned branch
- **AND** the auth entry screen is shown immediately, NOT the onboarding flow

#### Scenario: Killing the app resets completion

- **WHEN** the user completes onboarding, signs in, then kills and re-launches the app while still signed in
- **THEN** the dashboard is shown (the user is signed in)
- **AND** if the user then signs out, the onboarding flow is shown again from step 1

### Requirement: Step 1 — Welcome

The Welcome step SHALL display the literal title `Welcome 👋` and the multi-paragraph intro copy from `.claude/ONBOARDING_DRAFT_DETAILS.md` styled as a **personal quote from the app's creator**. The quote SHALL be rendered with quotation framing (visible opening quote mark, italic body, or a distinct quote-block treatment per `DESIGN.md`) and SHALL be attributed to the creator. The attribution SHALL include a **circular avatar** loaded from the asset catalog via `Image("mike")` (the `mike.imageset` entry already present in `Craw/Assets.xcassets`) rendered alongside or above a name + role line (e.g., `Mike, creator of Craw`). The asset catalog image SHALL be used as-is — no SF Symbol or placeholder fallback. The step SHALL also display a single primary "Continue" button. No input controls SHALL be present.

#### Scenario: Welcome renders the intro as a creator quote

- **WHEN** the user is on step 1
- **THEN** the screen shows the title `Welcome 👋`
- **AND** the intro copy is rendered as a quote (quotation framing + italic or block treatment) attributed to the creator
- **AND** a circular avatar loaded via `Image("mike")` is visible next to the attribution line
- **AND** a single "Continue" button is visible

#### Scenario: Welcome contains no input controls

- **WHEN** the user is on step 1
- **THEN** no toggles, fields, pickers, or selectable cards are present
- **AND** the only interactive element is the "Continue" button

### Requirement: Step 2 — Pick Goal (multi-select)

The Pick Goal step SHALL display the title `Pick your goal 📋` and the following five options as a tappable list, allowing **multi-select**:

- Make reading my new habit
- Make me smarter
- Make me reading consistently
- Track progress and statistics
- Replace doom scrolling reels

Tapping an option SHALL toggle its selected state; the selected state SHALL be visually distinct using the Rausch accent token. Continue SHALL be enabled regardless of how many options are selected (zero allowed).

#### Scenario: Toggling options

- **WHEN** the user taps two distinct goal rows
- **THEN** both rows render in the selected style
- **AND** `OnboardingState.selectedGoals` contains exactly those two goal identifiers

#### Scenario: Continue is always enabled

- **WHEN** the user is on step 2 with no goals selected
- **THEN** the "Continue" button is enabled and tappable

### Requirement: Step 3 — Daily Reading Time

The Daily Reading Time step SHALL display the title `Let's rock! 🎸`, the subtitle `How much time do you want to read per day?`, and a large tap-target showing the currently selected duration formatted as `Xh Ym` or `Y min`. Tapping the target SHALL present a picker (sheet or inline wheel) allowing the user to choose a duration between 5 and 120 minutes in 5-minute increments. The initial value SHALL be 15 minutes. The chosen value SHALL be written to `OnboardingState.dailyReadingMinutes` as an `Int`.

#### Scenario: Default value is 15 minutes

- **WHEN** the user reaches step 3 for the first time in a session
- **THEN** the tap-target displays `15 min`
- **AND** `OnboardingState.dailyReadingMinutes` equals `15`

#### Scenario: Selecting a value updates the display

- **WHEN** the user opens the picker and selects `45 min`
- **AND** confirms the selection
- **THEN** the tap-target displays `45 min`
- **AND** `OnboardingState.dailyReadingMinutes` equals `45`

### Requirement: Step 4 — How To Read

The How To Read step SHALL display the title `How to read` and a bulleted list of five reading-discipline tips (typo-corrected version of the copy from the RN draft). The step SHALL NOT collect any input. The "Continue" button SHALL be present and always enabled.

#### Scenario: Static informational screen

- **WHEN** the user is on step 4
- **THEN** the screen shows the title, five bullets, an illustration, and a "Continue" button
- **AND** no input control is present

### Requirement: Step 5 — Schedule

The Schedule step SHALL display the title `Let's schedule reading 📅`, a row of seven weekday chips (Mon–Sun, in the user's locale order), and a time tap-target showing a 12-hour formatted time (e.g., `8:00 AM`). Tapping the time SHALL present a native time picker (`DatePicker` with `.hourAndMinute`). The default selection SHALL be Monday through Friday at `8:00 AM`. The chosen weekdays and time SHALL be written to `OnboardingState.readingWeekdays` (a `Set<Weekday>`) and `OnboardingState.reminderTime` (a `Date` or `DateComponents` containing hour + minute). The system SHALL NOT request notification permission or schedule any `UNNotificationRequest` in this step.

#### Scenario: Default selection on first visit

- **WHEN** the user reaches step 5 for the first time in a session
- **THEN** Monday through Friday chips are selected
- **AND** the time tap-target displays `8:00 AM`

#### Scenario: Toggling a weekday chip

- **WHEN** the user taps the Saturday chip
- **THEN** the chip switches between selected and unselected
- **AND** `OnboardingState.readingWeekdays` reflects the new selection

#### Scenario: No notification permission prompt

- **WHEN** the user advances past step 5
- **THEN** no `UNUserNotificationCenter` authorization prompt has been shown
- **AND** no `UNNotificationRequest` has been scheduled

### Requirement: Step 6 — Books Per Year (single-select)

The Books Per Year step SHALL display the title `Final goal 📚`, the subtitle `How many books do you want to finish this year?`, and exactly four single-select option cards in this order: "You tell me", "1–6 books", "7–12 books", "12+ books". The selected card SHALL render with a Rausch accent border; unselected cards SHALL render with the design-system hairline border. The selected option SHALL be written to `OnboardingState.yearlyGoal` as an enum value. No option SHALL be pre-selected; "Continue" SHALL be disabled until the user picks one.

#### Scenario: Continue disabled until a selection is made

- **WHEN** the user is on step 6 with no card selected
- **THEN** the "Continue" button is visibly disabled and non-interactive

#### Scenario: Selecting a card enables Continue

- **WHEN** the user taps the "7–12 books" card
- **THEN** that card renders with the Rausch accent border
- **AND** the previously selected card (if any) loses the accent border
- **AND** the "Continue" button becomes enabled

### Requirement: Dot-progress indicator

The onboarding host SHALL display a horizontal row of six dots above the step content, with the dot corresponding to the current step rendered in the Rausch accent and the others rendered in the design-system muted/hairline color. The indicator SHALL update synchronously with step transitions.

#### Scenario: Indicator reflects the current step

- **WHEN** the user is on step 3
- **THEN** the third dot is rendered in the accent color
- **AND** the other five dots are rendered in the muted/hairline color

### Requirement: Onboarding uses Craw design tokens

The onboarding flow SHALL source every color, text font, corner radius, and shadow from `Theme` / `DESIGN.md` tokens. The flow SHALL NOT introduce ad-hoc hex color literals or new shadow tiers. Text typography SHALL use `Theme.Typography` tokens; new tokens MAY be added to `Theme.Typography` when a needed display size (e.g., ornamental quote glyph, large numeric display) is not yet present. Inline `.font(.system(size:))` calls on `Image(systemName:)` icons are permitted, matching the existing codebase convention (`Craw/Home/Sections/*.swift`, `Craw/AppShell/SplashView.swift`). The primary button SHALL match the design-system primary button (Rausch fill, `Theme.Radius.button`, `Theme.Typography.buttonMd`).

#### Scenario: No ad-hoc text-typography or color literals

- **WHEN** a reviewer inspects any file under `Craw/Onboarding/`
- **THEN** no `Color(hex:)` or `Color.red` literal appears
- **AND** no `.font(.system(size:))` call appears on a `Text` view (icon `Image(systemName:)` sizing is allowed per codebase convention)

### Requirement: Debug skip launch argument

In DEBUG builds, the system SHALL honor the launch argument `-CrawSkipOnboarding YES`. When present, the onboarding host SHALL be bypassed entirely: the gate's unsigned branch SHALL render the auth entry screen directly without the user seeing the onboarding flow. The launch argument SHALL have no effect in release builds.

#### Scenario: Debug bypass renders auth screen directly

- **WHEN** a developer launches a DEBUG build with `-CrawSkipOnboarding YES`
- **AND** there is no Clerk session
- **THEN** after the splash, the auth entry screen is shown immediately
- **AND** the onboarding flow is not rendered

#### Scenario: Release builds ignore the launch arg

- **WHEN** a release build is launched with `-CrawSkipOnboarding YES`
- **AND** there is no Clerk session
- **THEN** the onboarding flow is shown normally starting at step 1
