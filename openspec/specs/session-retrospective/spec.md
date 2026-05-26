# session-retrospective Specification

## Purpose

`session-retrospective` is the brief end-of-session moment that captures a single subjective signal — how hard was it to focus — and triggers a streak celebration when the user just edged into a 7-day run. After the redesign-reading-session-flow change, the retrospective collapses to one question with single-tap submit. The whole post-session flow now branches on book attitude: for-fun sessions go straight to the retrospective; study sessions can run a server-driven quiz first (see `session-quiz`).

## Requirements

### Requirement: Post-stop flow sequence

After a session transitions to `saving`, the system SHALL present the user with a sequential post-stop flow in this order: (1) quiz (study books only — see `session-quiz`), (2) retrospective, (3) optional streak celebration. The thoughts prompt is removed entirely. Each step SHALL be dismissible to the next without blocking persistence of the underlying session record.

For books with `attitude == .entertainment`, the quiz step is skipped and the flow goes directly from session-end to retrospective.

#### Scenario: Study-book full flow

- **WHEN** the user finishes a study session and completes each step
- **THEN** the steps appear in order: quiz section picker → quiz questions → quiz feedback → retrospective → (celebration if eligible)

#### Scenario: For-fun book minimal flow

- **WHEN** the user finishes a for-fun session
- **THEN** the next screen is the retrospective (no quiz)

#### Scenario: Skip advances the flow

- **WHEN** the user dismisses any quiz step
- **THEN** the flow advances to the retrospective

### Requirement: Single retrospective rating with single-tap submit

After the quiz step concludes (or is skipped, or did not run because the book is for-fun), the system SHALL present a single rating screen asking "How hard was it to focus?" with five tappable values labeled 1 through 5. There SHALL be no Continue button. Tapping any value SHALL persist a `SessionRetrospective` row with `focusDifficulty` equal to the tapped value and SHALL immediately advance the flow to the next step (streak celebration check or finish).

There SHALL be no confirmation modal, no undo affordance, and no requirement to wait for an animation.

#### Scenario: Tap commits and advances

- **WHEN** the retrospective screen is on-screen and the user taps the "4" button
- **THEN** a `SessionRetrospective` row is persisted with `focusDifficulty = 4` linked to the just-saved session
- **AND** the flow advances to the next step in the same tick

#### Scenario: No multi-question screen

- **WHEN** the retrospective screen is on-screen
- **THEN** only one question ("How hard was it to focus?") is presented
- **AND** no other rating questions are present

### Requirement: Hard-day derivation

The system SHALL derive a per-local-day boolean indicating whether a given day was "hard." A day SHALL be considered hard if at least one `SessionRetrospective` for any session that stopped on that local-calendar day has `focusDifficulty >= 4`. The derivation SHALL be a pure read over `SessionRetrospective` rows joined to `ReadingSession.endTimestamp`.

#### Scenario: Single hard session in a day

- **WHEN** a day has two completed sessions with focus ratings of `2` and `5`
- **THEN** the day is reported as hard

#### Scenario: No hard sessions

- **WHEN** all retrospectives for a day have `focusDifficulty <= 3`
- **THEN** the day is reported as not hard

#### Scenario: Day with no sessions

- **WHEN** a given day has no completed sessions
- **THEN** the day is reported as not hard

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

### Requirement: Quiz outcome independence

The retrospective rating and streak credit SHALL NOT depend on whether the user took, skipped, or aborted the quiz. A session with `quizMark = nil` SHALL still allow the user to record a retrospective rating and SHALL still contribute its minutes to `ReadingDay` and to streak calculations.

#### Scenario: Skipped quiz still credits the day

- **WHEN** the user skips every quiz step and submits a retrospective rating
- **THEN** the session's minutes are committed to today's `ReadingDay`
- **AND** the streak is updated as if the quiz had been completed
