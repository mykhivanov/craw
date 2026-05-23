## ADDED Requirements

### Requirement: Sessions write to ReadingDay

On completion of the post-stop pipeline, the system SHALL upsert a `ReadingDay` row for each local-calendar day the session touched. The row's `minutesRead` and `pagesRead` SHALL be incremented by the session's contributions to that day. A row SHALL be created if absent; an existing row SHALL be updated in place. There SHALL remain at most one `ReadingDay` per local date.

#### Scenario: Single-day session

- **WHEN** a session of 20 minutes and 15 pages stops on a day that has no `ReadingDay` row
- **THEN** a new `ReadingDay` row is created with `minutesRead = 20` and `pagesRead = 15`

#### Scenario: Multiple sessions same day

- **WHEN** today already has a `ReadingDay` with `minutesRead = 10, pagesRead = 5` and a new session of 25 minutes and 12 pages stops today
- **THEN** today's `ReadingDay` is updated in place to `minutesRead = 35, pagesRead = 17`
- **AND** still exactly one `ReadingDay` row exists for today

### Requirement: Cross-midnight minute split

A session whose start and end span a local-midnight boundary SHALL contribute its minutes proportionally to each affected day's `ReadingDay`. Page contributions SHALL be attributed entirely to the day on which the session stopped, since per-moment page state is not tracked.

#### Scenario: Session spans midnight

- **WHEN** a session starts at 23:40 local time and stops at 00:20 local time the next day, with 8 pages read
- **THEN** the prior day's `ReadingDay.minutesRead` is incremented by 20
- **AND** the new day's `ReadingDay.minutesRead` is incremented by 20
- **AND** the new day's `ReadingDay.pagesRead` is incremented by 8
- **AND** the prior day's `ReadingDay.pagesRead` is unchanged

### Requirement: Hard-days derivation surface

The `ReadingActivityReader` SHALL expose a `hardDaysInLastSevenDays() -> Int` function whose definition aligns with the hard-day rule in `session-retrospective`: a day is hard if any session ending on it has `startDifficulty >= 4` OR `focusDifficulty >= 4`. The function SHALL return a value in [0, 7].

#### Scenario: Reader exposes hard-days count

- **WHEN** a caller invokes `hardDaysInLastSevenDays()` and three of the last seven days qualify as hard
- **THEN** the function returns 3

### Requirement: Writes happen exactly once per session

A session's contribution to `ReadingDay` SHALL be applied exactly once across the post-stop pipeline, even if the pipeline is interrupted and resumed. The system SHALL idempotently associate each `ReadingSession.id` with its `ReadingDay` write so a retry does not double-count.

#### Scenario: Pipeline interruption

- **WHEN** the post-stop pipeline begins writing a session's contribution and is interrupted, then resumes on next app launch
- **THEN** the affected `ReadingDay` rows reflect the session's contribution exactly once
- **AND** no duplicate contribution is applied
