# reading-activity Specification

## Purpose

`reading-activity` owns the `ReadingDay` aggregate that the home dashboard renders into the 7-day strip, the today-minutes stat card, and the streak counter. After the redesign-reading-session-flow change, the aggregate is denominated in minutes only — per-page tracking is removed at the model layer (`Book` and `ReadingSession`), so day-level page accounting goes too.

## Requirements

### Requirement: ReadingDay domain model

The system SHALL persist a `ReadingDay` entity keyed by a local-calendar date with the following fields: date (date-only, no time component) and total minutes read. There SHALL be at most one `ReadingDay` row per date. The previously-stored `pagesRead` field is removed.

#### Scenario: One row per date

- **WHEN** activity is logged on the same local date twice
- **THEN** a single `ReadingDay` row exists for that date with both minute contributions aggregated

### Requirement: Local-calendar day bucketing

All date assignments for `ReadingDay` SHALL use `Calendar.autoupdatingCurrent` to determine which day a moment in time belongs to. A reading moment that straddles the user's local midnight SHALL be attributed to whichever local day each portion fell into.

#### Scenario: Reading across midnight

- **WHEN** activity is logged spanning 23:45 to 00:30 local time
- **THEN** the portion before midnight contributes to the prior day's `ReadingDay`
- **AND** the portion after midnight contributes to the following day's `ReadingDay`

### Requirement: Today's metrics query

The system SHALL expose a read-only mechanism to retrieve today's `ReadingDay` minutes read. If today has no row, the response SHALL be zero rather than absent.

#### Scenario: No activity today

- **WHEN** today has no `ReadingDay` row
- **THEN** the today-metrics query returns minutes = 0

### Requirement: Last-7-days query

The system SHALL expose a read-only mechanism to retrieve `ReadingDay` data for the most recent seven local-calendar days inclusive of today, returned in oldest-first order. Days without rows SHALL be represented as zero-valued entries so consumers always receive exactly seven items.

#### Scenario: Sparse week

- **WHEN** the user has activity on only 2 of the last 7 days
- **THEN** the query returns 7 entries
- **AND** 5 of them have zero minutes

### Requirement: Day-over-day minutes delta

The system SHALL provide a derivation of today's minutes-read percentage change versus yesterday's minutes-read. The result SHALL distinguish three cases: a numeric percentage when yesterday had non-zero minutes; an "increase from zero" indicator when yesterday was zero and today is non-zero; an "unchanged" indicator when both are zero.

#### Scenario: Standard percentage

- **WHEN** today = 30 minutes and yesterday = 20 minutes
- **THEN** the derivation returns +50%

#### Scenario: Yesterday was zero

- **WHEN** yesterday = 0 minutes and today = 15 minutes
- **THEN** the derivation returns an "increase from zero" indicator
- **AND** no percentage value is exposed

#### Scenario: Both days zero

- **WHEN** yesterday = 0 minutes and today = 0 minutes
- **THEN** the derivation returns an "unchanged" indicator

### Requirement: Current streak derivation

The system SHALL derive the user's current streak as the count of consecutive local-calendar days, ending no later than today, with non-zero minutes read. If today has zero minutes, the derivation SHALL anchor the streak window at yesterday rather than treating the streak as broken.

#### Scenario: Five-day streak active

- **WHEN** the user has non-zero minutes on each of the last 5 days including today
- **THEN** the streak derivation returns 5

#### Scenario: Today not yet logged

- **WHEN** today has zero minutes and the prior 3 days each have non-zero minutes
- **THEN** the streak derivation returns 3 rather than 0

#### Scenario: Streak broken by gap

- **WHEN** the last 7 days are: non-zero, non-zero, zero, non-zero, non-zero, non-zero, non-zero (today)
- **THEN** the streak derivation returns 4

### Requirement: Current-calendar-week derivation

The system SHALL expose a read-only derivation describing the present calendar week — bounded by the user's `Calendar.autoupdatingCurrent` `firstWeekday` setting — as an ordered sequence of seven entries, each entry tagged with its weekday and a boolean indicating whether that day has any reading activity logged. Today's entry SHALL be marked as such so the UI can highlight it.

The "present calendar week" SHALL be the calendar week that contains today, not a rolling 7-day window. The current-week derivation is therefore distinct from the existing last-7-days query, which is rolling.

#### Scenario: Mid-week query

- **WHEN** today is Wednesday and the user's calendar starts weeks on Monday, with reading activity logged on Monday and Tuesday
- **THEN** the derivation returns seven entries beginning Monday and ending Sunday
- **AND** Monday and Tuesday are marked as having activity
- **AND** Wednesday is marked as today
- **AND** Thursday through Sunday are marked as having no activity

#### Scenario: First day of the week

- **WHEN** today is the first weekday of the calendar week and no activity has been logged yet
- **THEN** the derivation returns seven entries with today as the only highlighted day and no entry marked as having activity

### Requirement: Sessions write to ReadingDay

On completion of the post-stop pipeline, the system SHALL upsert a `ReadingDay` row for each local-calendar day the session touched. The row's `minutesRead` SHALL be incremented by the session's contribution to that day. A row SHALL be created if absent; an existing row SHALL be updated in place. There SHALL remain at most one `ReadingDay` per local date.

#### Scenario: Single-day session

- **WHEN** a session of 20 minutes stops on a day that has no `ReadingDay` row
- **THEN** a new `ReadingDay` row is created with `minutesRead = 20`

#### Scenario: Multiple sessions same day

- **WHEN** today already has a `ReadingDay` with `minutesRead = 10` and a new session of 25 minutes stops today
- **THEN** today's `ReadingDay` is updated in place to `minutesRead = 35`
- **AND** still exactly one `ReadingDay` row exists for today

### Requirement: Cross-midnight minute split

A session whose start and end span a local-midnight boundary SHALL contribute its minutes proportionally to each affected day's `ReadingDay`. There SHALL be no per-page attribution to consider, since per-session page state is no longer tracked.

#### Scenario: Session spans midnight

- **WHEN** a session starts at 23:40 local time and stops at 00:20 local time the next day
- **THEN** the prior day's `ReadingDay.minutesRead` is incremented by 20
- **AND** the new day's `ReadingDay.minutesRead` is incremented by 20

### Requirement: Writes happen exactly once per session

A session's contribution to `ReadingDay` SHALL be applied exactly once across the post-stop pipeline, even if the pipeline is interrupted and resumed. The system SHALL idempotently associate each `ReadingSession.id` with its `ReadingDay` write so a retry does not double-count.

#### Scenario: Pipeline interruption

- **WHEN** the post-stop pipeline begins writing a session's contribution and is interrupted, then resumes on next app launch
- **THEN** the affected `ReadingDay` rows reflect the session's contribution exactly once
- **AND** no duplicate contribution is applied
