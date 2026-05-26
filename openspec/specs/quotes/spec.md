# quotes Specification

## Purpose

`quotes` is the capability for capturing the user's favorite passages from books they're reading. Captured during a session via a quick-add affordance, persisted on-device, and surfaced for reading later. The redesign-reading-session-flow change narrowed this capability from `quotes-and-thoughts` to quotes-only — the `Thought` concept and all its capture surfaces have been removed from the product.

Per-book quote browsing UI is owned by a future `add-quotes-page` change; this capability defines the model and the read-only query that a future browser will consume.

## Requirements

### Requirement: Quote domain model

The system SHALL persist a `Quote` entity with the following fields: stable identifier, book identifier (foreign reference), text, optional page number, captured-at timestamp. Quotes SHALL be persisted in the app's on-device SwiftData store.

#### Scenario: Persisted quote survives relaunch

- **WHEN** a quote is captured during a session and the app is relaunched
- **THEN** the quote is still present with all fields intact

### Requirement: Quote capture entry points

Quote capture SHALL be available from the timer screen during an active session. There SHALL be no thought-capture entry points anywhere in the app — the `Thought` concept is removed entirely.

#### Scenario: In-session quote affordance

- **WHEN** a session is `running` or `paused`
- **THEN** the timer screen shows an affordance to add a quote

#### Scenario: No thought affordance during session

- **WHEN** a session is `running` or `paused`
- **THEN** the timer screen does NOT show any "Add thought" affordance

#### Scenario: No post-stop thoughts prompt

- **WHEN** a session enters the post-stop flow
- **THEN** no thoughts prompt screen is shown

### Requirement: Read-only listing per book

The system SHALL expose a read-only query to list all quotes for a given book, ordered by captured-at timestamp descending. There SHALL be no per-book thoughts listing because the `Thought` concept is removed.

Per-book quotes browsing UI is out of scope in this capability; a future `add-quotes-page` change owns the quotes browsing surface.

#### Scenario: Query returns quotes newest-first

- **WHEN** a caller invokes the per-book quotes query for a book with three quotes captured at 09:00, 10:00, 11:00 local
- **THEN** the query returns the 11:00 quote first

#### Scenario: No thoughts query exists

- **WHEN** any caller attempts to query per-book thoughts
- **THEN** no such API exists in the codebase

### Requirement: Browser and search out of scope

This capability SHALL NOT define a cross-book quotes browser, cross-book quote search, search-term highlighting, or any quote editing or deletion UI. Those are deferred to a future `add-quotes-page` change.

#### Scenario: No cross-book browser in this capability

- **WHEN** the user navigates anywhere in the current product
- **THEN** no screen presents quotes from more than one book at a time
