# quotes-and-thoughts Specification

## Purpose
TBD - created by archiving change add-session-quiz-verification. Update Purpose after archive.
## Requirements
### Requirement: Quote domain model

The system SHALL persist a `Quote` entity with the following fields: stable identifier, book identifier (foreign reference), text, optional page number, captured-at timestamp. Quotes SHALL be persisted in the app's on-device SwiftData store.

#### Scenario: Persisted quote survives relaunch

- **WHEN** a quote is captured during a session and the app is relaunched
- **THEN** the quote is still present with all fields intact

### Requirement: Thought domain model

The system SHALL persist a `Thought` entity with the following fields: stable identifier, book identifier (foreign reference), text, captured-at timestamp. Thoughts SHALL be persisted in the app's on-device SwiftData store.

#### Scenario: Persisted thought survives relaunch

- **WHEN** a thought is captured at the post-session prompt and the app is relaunched
- **THEN** the thought is still present with all fields intact

### Requirement: Quote and thought capture entry points

Quote capture SHALL be available from the timer screen during an active session. Thought capture SHALL be available from the timer screen during an active session AND from the post-session thoughts prompt. No other entry points SHALL exist in this change.

#### Scenario: In-session quote affordance

- **WHEN** a session is `running` or `paused`
- **THEN** the timer screen shows an affordance to add a quote

#### Scenario: In-session thought affordance

- **WHEN** a session is `running` or `paused`
- **THEN** the timer screen shows an affordance to add a thought

#### Scenario: Post-stop thoughts prompt

- **WHEN** the session enters the post-stop flow
- **THEN** the thoughts prompt screen allows adding zero or more thoughts before continuing

### Requirement: Read-only listing per book

The system SHALL expose read-only queries to list all quotes for a given book and all thoughts for a given book, each ordered by captured-at timestamp descending. The book-detail screen SHALL consume these queries.

#### Scenario: Book detail shows quotes and thoughts

- **WHEN** the user opens a book's detail screen for a book with two quotes and three thoughts
- **THEN** the screen displays both quotes and all three thoughts in collapsible lists, ordered newest-first

### Requirement: Browser and search out of scope

This capability SHALL NOT define a cross-book quotes browser, cross-book quote search, search-term highlighting, or any quote/thought editing or deletion UI. Those are deferred to a future `add-quotes-browser` change.

#### Scenario: No cross-book browser in this change

- **WHEN** the user navigates anywhere in this change
- **THEN** no screen presents quotes or thoughts from more than one book at a time

