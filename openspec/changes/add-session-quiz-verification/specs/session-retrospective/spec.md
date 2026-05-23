## ADDED Requirements

### Requirement: Post-stop flow sequence

After a session transitions to `saving`, the system SHALL present the user with a sequential post-stop flow in this order: (1) thoughts prompt, (2) quiz, (3) retrospective ratings, (4) optional streak celebration. Each step SHALL be dismissible to the next without blocking persistence of the underlying session record.

#### Scenario: Full flow

- **WHEN** the user stops a session and completes each step
- **THEN** the steps appear in order: thoughts → quiz → ratings → (celebration if eligible)
- **AND** dismissing any step still advances to the next

### Requirement: Thoughts prompt

The first post-stop screen SHALL ask "What thoughts did you capture?" and present a list editor. The editor SHALL allow adding multiple thought entries before continuing, each entered via a text field with an explicit "Add" action. Each added thought SHALL be persisted as a `Thought` row linked to the session's book. The user MAY continue with zero thoughts.

#### Scenario: User captures multiple thoughts

- **WHEN** the user adds three thoughts at the post-stop prompt and taps Continue
- **THEN** three `Thought` rows are persisted, each linked to the session's book

#### Scenario: User skips thoughts

- **WHEN** the user taps Continue without adding any thoughts
- **THEN** no `Thought` rows are written
- **AND** the flow advances to the quiz step

### Requirement: Three retrospective ratings

After the quiz step concludes, the system SHALL collect three independent 1–5 ratings on a single screen, in this order: how hard was it to **start** today, how hard was it to **focus**, how much did you **enjoy** the session. Each rating SHALL default to no selection; the user SHALL be required to select a value on each before Continue is enabled.

#### Scenario: All three ratings selected

- **WHEN** the user selects 2, 4, and 5 for start/focus/enjoyment respectively
- **THEN** a `SessionRetrospective` row is persisted with `startDifficulty = 2`, `focusDifficulty = 4`, `enjoyment = 5`, linked to the just-saved session

#### Scenario: Ratings cannot be partially submitted

- **WHEN** the user has selected only two of the three ratings
- **THEN** the Continue button is disabled

### Requirement: Hard-day derivation

The system SHALL derive a per-local-day boolean indicating whether a given day was "hard." A day SHALL be considered hard if at least one `SessionRetrospective` for any session that stopped on that local-calendar day has `startDifficulty >= 4` OR `focusDifficulty >= 4`. The derivation SHALL be a pure read over `SessionRetrospective` rows joined to `ReadingSession.endTimestamp`.

#### Scenario: Single hard session in a day

- **WHEN** a day has two completed sessions with start/focus ratings (1, 2) and (5, 3)
- **THEN** the day is reported as hard

#### Scenario: No hard sessions

- **WHEN** all retrospectives for a day are ≤ 3 on both start and focus
- **THEN** the day is reported as not hard

#### Scenario: Day with no sessions

- **WHEN** a given day has no completed sessions
- **THEN** the day is reported as not hard

### Requirement: Hard-days-this-week count

The system SHALL expose a derivation `hardDaysInLastSevenDays() -> Int` returning the count of hard days within the most recent seven local-calendar days inclusive of today. The result SHALL be in the range [0, 7].

#### Scenario: Mixed week

- **WHEN** the last seven days contain three hard days and four non-hard days
- **THEN** the count returns 3

### Requirement: Streak celebration trigger

The system SHALL present a full-screen streak-celebration view exactly when the just-completed session causes the user's current streak to transition from 6 to 7 consecutive local-calendar days with reading activity. The trigger SHALL be a function of the streak value before and after the session and SHALL NOT depend on whether the user has previously reached 7 — every 6 → 7 transition fires the celebration. The celebration SHALL NOT trigger for streak values above 7 in this change; the sustained-milestone state at streak ≥ 7 is handled by the home-dashboard streak card's persistent two-element treatment, not by repeated celebrations.

#### Scenario: First-ever edge into seven

- **WHEN** before this session the streak was 6 days, after this session the streak is 7, and the user has never previously reached a 7-day streak
- **THEN** the celebration view is shown as the final step of the post-stop flow

#### Scenario: Re-achievement of seven after a break

- **WHEN** before this session the streak was 6 days, after this session the streak is 7, and the user previously reached 7 days in the past before breaking the streak
- **THEN** the celebration view is shown as the final step of the post-stop flow
- **AND** no record of prior 7-day achievements is consulted to suppress the trigger

#### Scenario: Streak above seven does not retrigger

- **WHEN** before this session the streak was 8 days and after this session the streak is 9
- **THEN** the celebration view is NOT shown

#### Scenario: Streak below seven

- **WHEN** before this session the streak was 3 days and after this session the streak is 4
- **THEN** the celebration view is NOT shown

### Requirement: Verification state independence

The retrospective ratings, thoughts capture, and streak credit SHALL NOT depend on the quiz verification outcome. A session with `verification = .skipped`, `.failed`, or `.unavailable` SHALL still allow the user to record retrospective ratings and SHALL still contribute its minutes and pages to `ReadingDay` and to streak calculations.

#### Scenario: Failed quiz still credits the day

- **WHEN** the user fails the quiz and submits retrospective ratings
- **THEN** the session's minutes and pages are committed to today's `ReadingDay`
- **AND** the streak is updated as if the session were verified
- **AND** the session does not display the verified badge
