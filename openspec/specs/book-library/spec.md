# book-library Specification

## Purpose

The local book library is the on-device source of truth for what the user is reading. Books are inserted via `book-search` and surfaced to the user via `home-dashboard`. After the redesign-reading-session-flow change, a book's in-progress vs finished status is an explicit user-controlled flag (`isFinished`), not a derivation from page counts — there is no per-page progress tracking on the client.

## Requirements

### Requirement: Book domain model

The system SHALL persist a `Book` entity with the following fields: stable identifier (`id`), optional backend identifier (`remoteID`), title, author, optional bundled cover-asset reference (`coverAssetName`), optional remote cover URL (`coverImageURL`), optional ISBN (`isbn`), total page count (`totalPages`), date added (`dateAdded`), attitude (`attitudeRaw` persisted as a String mirroring `BookAttitude`), finished flag (`isFinished: Bool` defaulting to `false`), and optional finished-at timestamp (`finishedAt: Date?`). The model SHALL be persisted using the app's chosen on-device storage layer (SwiftData, per design).

The previously-persisted `currentPage` field is removed in the redesign-reading-session-flow change. Removing a field is not a lightweight migration; the app SHALL hard-reset the local SwiftData store on first launch of the new schema version (see `app-shell` / `CrawModelContainer` for the wipe mechanic).

#### Scenario: Persisted book survives relaunch

- **WHEN** a book is added to the library and the app is relaunched within the same schema version
- **THEN** the book is still present with all its fields intact, including `isFinished` and `finishedAt` when set

#### Scenario: Newly added book defaults to unfinished

- **WHEN** a new `Book` is inserted via any code path
- **THEN** the book has `isFinished = false`
- **AND** `finishedAt = nil`

### Requirement: Derived reading status

A book's status SHALL be derived from the `isFinished` flag, not from page counts:
- `finished` when `isFinished == true`.
- `inProgress` when `isFinished == false`.

The `notStarted` state is removed — newly added books are simply `inProgress` until the user explicitly marks them finished. For dashboard listing purposes (For fun / To study / All currently reading entry points), only `inProgress` books are listed; finished books appear in the Finished section.

#### Scenario: Newly added book is in-progress

- **WHEN** a book is added with `isFinished = false`
- **THEN** its status is `inProgress`
- **AND** it is eligible to appear under the For fun, To study, and All currently reading entry points based on attitude

#### Scenario: Book marked finished

- **WHEN** a book's `isFinished` is set to `true`
- **THEN** its status is `finished`
- **AND** it appears in the Finished section of the dashboard
- **AND** it does NOT appear under any session-start entry point

### Requirement: Read-only library queries

The system SHALL expose a read-only mechanism to list books filtered by derived status (in-progress, finished) and by attitude (entertainment, study). Queries SHALL be SwiftUI-observable so dashboard sections update automatically when underlying data changes. The in-progress queries SHALL be sorted most-recently-added first (`dateAdded DESC`) so the For fun / To study entry points consistently surface the newest book of that attitude.

#### Scenario: Adding a book updates the dashboard

- **WHEN** a book is inserted into the persistence layer while the dashboard is on screen
- **THEN** the relevant entry point updates without an explicit refresh action

#### Scenario: Most-recently-added book sorts first

- **WHEN** the user has three study books with `dateAdded` of yesterday, two days ago, and today
- **THEN** the in-progress study query returns today's book first

### Requirement: Cover placeholder fallback

When a book has no cover-image reference, the UI SHALL render a neutral placeholder that uses design-system tokens (muted surface fill, no brand color). The placeholder SHALL be sized identically to a real cover image so layout does not shift.

#### Scenario: Book without cover

- **WHEN** a book has no cover-image reference
- **THEN** the row renders a neutral placeholder of equal size to a cover image

### Requirement: Books may be inserted from external sources

The library SHALL accept new `Book` rows inserted by other capabilities — currently `book-search`. Inserted books SHALL be observable by the existing read-only library queries (in-progress / finished) without any additional refresh action by the caller.

#### Scenario: Inserted book appears in dashboard

- **WHEN** another capability inserts a new `Book` with `isFinished = false`
- **THEN** the book appears under the relevant attitude entry point on the dashboard immediately
- **AND** the in-progress query result updates without an explicit refresh

### Requirement: Cover render fallback order

The cover-rendering layer SHALL prefer `coverImageURL` when non-nil, fall back to `coverAssetName` when `coverImageURL` is nil, and fall back to the neutral placeholder when both are nil. While a remote image is loading or if it fails to load, the neutral placeholder SHALL occupy the same frame.

#### Scenario: Both cover sources present

- **WHEN** a book has a non-nil `coverImageURL` AND a non-nil `coverAssetName`
- **THEN** the cover renders from `coverImageURL`
- **AND** `coverAssetName` is not used

#### Scenario: Only the bundled asset is present

- **WHEN** a book has nil `coverImageURL` AND a non-nil `coverAssetName`
- **THEN** the cover renders from the bundled asset

#### Scenario: Remote cover fails to load

- **WHEN** `coverImageURL` is non-nil AND the network image fails to load
- **THEN** the neutral placeholder is shown
- **AND** `coverAssetName` is not used as a secondary fallback

### Requirement: Mark book as finished

The system SHALL expose a write operation that marks a `Book` as finished by setting `isFinished = true` and `finishedAt = Date.now`. The "Book is finished" button on the session timer screen SHALL invoke this operation as part of the session-stop transition (see `reading-session` spec).

#### Scenario: Mark finished writes both fields

- **WHEN** the mark-finished operation is invoked on a `Book`
- **THEN** the book's `isFinished` becomes `true`
- **AND** the book's `finishedAt` is set to the current moment

#### Scenario: Already-finished book is idempotent

- **WHEN** the mark-finished operation is invoked on a `Book` that is already finished
- **THEN** the book remains finished
- **AND** `finishedAt` retains its prior value (the original finish time is preserved)
