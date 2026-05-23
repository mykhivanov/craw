# reading-session Specification

## Purpose
TBD - created by archiving change add-session-quiz-verification. Update Purpose after archive.
## Requirements
### Requirement: Session lifecycle states

The system SHALL model a reading session as a state machine with the states `idle`, `running`, `paused`, `stopped`, and `saving`. Transitions SHALL be: `idle → running` (start), `running ⇄ paused` (pause / resume), `running → stopped` (stop from running), `paused → stopped` (stop from paused), `stopped → saving` (post-stop pipeline), `saving → idle` (pipeline complete). No other transitions SHALL be permitted.

#### Scenario: Start from idle

- **WHEN** the user taps "Start reading session" from the book detail
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

The book-detail screen SHALL be the only user-facing entry point for starting a reading session. The entry point SHALL be a primary CTA labeled "Start reading session" using the Rausch brand accent.

#### Scenario: CTA on book detail

- **WHEN** the user opens any book's detail screen
- **THEN** a "Start reading session" CTA is visible

### Requirement: Page-counter adjustments during a session

While a session is `running` or `paused`, the user SHALL be able to set the current page to any integer between the session's starting page and the book's total page count, inclusive. The book's `currentPage` SHALL only be persisted on session stop, not on each in-session change.

#### Scenario: User updates page during session

- **WHEN** a session starts at page 40 and the user sets the page to 67 during the session, then stops
- **THEN** the saved `ReadingSession` records `pagesRead = 27`
- **AND** the associated book's `currentPage` is updated to 67

#### Scenario: User does not change page

- **WHEN** a session starts at page 40 and the user stops without adjusting the page
- **THEN** the saved `ReadingSession` records `pagesRead = 0`
- **AND** the associated book's `currentPage` remains 40

### Requirement: Auto-save against backgrounding and termination

The system SHALL persist active session state (book identifier, start time, accumulated elapsed seconds, current page, paused flag) at every state transition, every 15 seconds while `running`, and on every scenePhase transition into `.background` or `.inactive`. Persisted active state SHALL be cleared on transition to `idle`.

#### Scenario: App backgrounded mid-session

- **WHEN** a session has been running for 8 minutes and the app moves to the background
- **THEN** an active-session snapshot is written before the scene becomes inactive

#### Scenario: App force-quit and relaunched

- **WHEN** the user force-quits the app during a session and relaunches it
- **THEN** the timer screen restores with the prior elapsed time, current page, and pause state intact
- **AND** the user is offered "Resume" or "Stop and save partial session"

#### Scenario: Crash between checkpoints

- **WHEN** the app crashes 12 seconds after the most recent auto-save checkpoint
- **THEN** on restore, up to 15 seconds of elapsed time MAY be lost
- **AND** the session is otherwise fully restorable

### Requirement: Session record on stop

On transition into `saving`, the system SHALL create a `ReadingSession` record with: stable identifier, book identifier, start timestamp (UTC), end timestamp (UTC), accumulated elapsed seconds, pages read, and an initial `verification = .pending` value to be finalized by the quiz pipeline. The record SHALL be persisted before any post-stop UI step begins.

#### Scenario: Record created before post-stop flow

- **WHEN** a session is stopped
- **THEN** a `ReadingSession` row is committed to storage before the post-stop thoughts prompt is shown

### Requirement: Quote and thought capture during session

While a session is `running` or `paused`, the user SHALL have an affordance on the timer screen to quickly add a quote or a thought attached to the current book. Quotes captured here SHALL accept an optional page number defaulting to the session's current page.

#### Scenario: Quick add a quote

- **WHEN** the user taps the add-quote affordance during a running session, enters text, and confirms
- **THEN** a `Quote` row is persisted with the entered text, the session's current page as the default page, and the book identifier
- **AND** the session remains in its prior state (`running` or `paused`)

#### Scenario: Quick add a thought

- **WHEN** the user taps the add-thought affordance during a session, enters text, and confirms
- **THEN** a `Thought` row is persisted with the entered text and the book identifier

