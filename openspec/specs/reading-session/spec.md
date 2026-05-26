# reading-session Specification

## Purpose

`reading-session` defines the state machine and persistence shape for a single reading session: lifecycle states, in-session capture affordances, auto-save against backgrounding, and the `ReadingSession` record committed on stop. The redesign-reading-session-flow change strips per-page tracking and thought capture from the session, renames "Stop" → "Finish", and adds an alternative "Book is finished" end-control that flips `Book.isFinished` as part of stopping.

## Requirements

### Requirement: Session lifecycle states

The system SHALL model a reading session as a state machine with the states `idle`, `running`, `paused`, `stopped`, and `saving`. Transitions SHALL be: `idle → running` (start), `running ⇄ paused` (pause / resume), `running → stopped` (stop from running), `paused → stopped` (stop from paused), `stopped → saving` (post-stop pipeline), `saving → idle` (pipeline complete). No other transitions SHALL be permitted.

#### Scenario: Start from idle

- **WHEN** the user taps a session-start entry on the home dashboard
- **THEN** the engine transitions from `idle` to `running`
- **AND** the timer begins counting elapsed seconds

#### Scenario: Pause then resume

- **WHEN** a session is `running` and the user taps pause, then taps resume
- **THEN** the engine transitions `running → paused → running`
- **AND** elapsed time accumulated while paused is not counted

#### Scenario: Stop from paused

- **WHEN** a session is `paused` and the user taps stop
- **THEN** the engine transitions `paused → stopped → saving`

### Requirement: Session entry point

The home dashboard's three session-start entry points (For fun, To study, All currently reading) SHALL be the only user-facing entry points for starting a reading session. Each entry point's tap target uses the Rausch brand accent for primary affordances. There is no book-detail screen — those have been removed in the redesign-reading-session-flow change.

#### Scenario: Start from For fun entry

- **WHEN** the user taps the For fun entry on Home and at least one in-progress for-fun book exists
- **THEN** the timer screen appears and the engine transitions from `idle` to `running` for the most-recently-added for-fun book

#### Scenario: Start from All currently reading entry

- **WHEN** the user taps a book row inside the "All currently reading" view
- **THEN** the timer screen appears and the engine transitions from `idle` to `running` for that book

### Requirement: Session record on stop

On transition into `saving`, the system SHALL create a `ReadingSession` record with: stable identifier, book identifier, start timestamp (UTC), end timestamp (UTC), accumulated elapsed seconds, an optional `sectionOrPageHint: String?` (set by the post-session quiz flow when the user picks a section or types a page; nil when the quiz was skipped or the book attitude was `.entertainment`), and an optional `quizMark: Int?` (1, 2, or 3 when the quiz was graded; nil otherwise). The record SHALL be persisted before any post-stop UI step begins.

#### Scenario: Record created before post-stop flow

- **WHEN** a session is stopped
- **THEN** a `ReadingSession` row is committed to storage before the post-stop UI is shown
- **AND** the row has `sectionOrPageHint = nil` and `quizMark = nil` at insert time

#### Scenario: Quiz hint populates after grading

- **WHEN** a study-attitude session completes the full quiz flow with `sectionOrPage = "Part 2: The Bridge"` and a server-returned mark of `2`
- **THEN** the `ReadingSession` row is updated with `sectionOrPageHint = "Part 2: The Bridge"` and `quizMark = 2`

### Requirement: Auto-save against backgrounding and termination

The system SHALL persist active session state (book identifier, start time, accumulated elapsed seconds, paused flag) at every state transition, every 15 seconds while `running`, and on every scenePhase transition into `.background` or `.inactive`. Persisted active state SHALL be cleared on transition to `idle`. The persisted snapshot no longer includes `startingPage` or `currentPage` — page state is no longer part of an active session.

#### Scenario: App backgrounded mid-session

- **WHEN** a session has been running for 8 minutes and the app moves to the background
- **THEN** an active-session snapshot is written before the scene becomes inactive
- **AND** the snapshot contains book identifier, start time, accumulated elapsed seconds, and paused flag

#### Scenario: App force-quit and relaunched

- **WHEN** the user force-quits the app during a session and relaunches it
- **THEN** the timer screen restores with the prior elapsed time and pause state intact
- **AND** the user is offered "Resume" or "Stop and save partial session"

#### Scenario: Crash between checkpoints

- **WHEN** the app crashes 12 seconds after the most recent auto-save checkpoint
- **THEN** on restore, up to 15 seconds of elapsed time MAY be lost
- **AND** the session is otherwise fully restorable

### Requirement: Quote capture during session

While a session is `running` or `paused`, the user SHALL have an affordance on the timer screen to quickly add a quote attached to the current book. Quotes captured here SHALL accept an optional page number that the user may type manually (since the session no longer tracks a current page). There SHALL be no in-session "Add thought" affordance — thought capture is removed entirely from the product.

#### Scenario: Quick add a quote

- **WHEN** the user taps the add-quote affordance during a running session, enters text, optionally types a page number, and confirms
- **THEN** a `Quote` row is persisted with the entered text, the optional page number, and the book identifier
- **AND** the session remains in its prior state (`running` or `paused`)

#### Scenario: No thought capture affordance

- **WHEN** a session is `running` or `paused`
- **THEN** the timer screen has no "Add thought" button or equivalent affordance

### Requirement: Finish vs Book-is-finished controls on the timer

The session timer screen SHALL render two end-session controls: a "Finish" button (renamed from "Stop") that ends the session and a "Book is finished" button that ends the session AND marks the active book as finished (`Book.isFinished = true`, `Book.finishedAt = Date.now`).

Both controls transition the engine through `running|paused → stopped → saving`. The post-session flow downstream branches on book attitude and on whether "Book is finished" was tapped (see `session-quiz` spec).

#### Scenario: Finish ends without marking the book

- **WHEN** the user taps "Finish" during a running session
- **THEN** the engine transitions to `stopped` then `saving`
- **AND** the active `Book.isFinished` remains unchanged

#### Scenario: Book is finished marks and ends

- **WHEN** the user taps "Book is finished" during a running session for a book that is not yet finished
- **THEN** the engine transitions to `stopped` then `saving`
- **AND** the active `Book.isFinished` becomes `true`
- **AND** the active `Book.finishedAt` is set to the current moment

#### Scenario: Book is finished is idempotent on already-finished books

- **WHEN** the user taps "Book is finished" for a book whose `isFinished` is already `true`
- **THEN** the engine transitions to `stopped` then `saving`
- **AND** `Book.finishedAt` retains its prior value
