# book-library Specification

## Purpose
TBD - created by archiving change add-home-dashboard. Update Purpose after archive.
## Requirements
### Requirement: Book domain model

The system SHALL persist a `Book` entity with the following fields: stable identifier (`id`), optional backend identifier (`remoteID`), title, author, optional bundled cover-asset reference (`coverAssetName`), optional remote cover URL (`coverImageURL`), optional ISBN (`isbn`), total page count, current page count, date added. The model SHALL be persisted using the app's chosen on-device storage layer (SwiftData, per design). Adding `coverImageURL`, `isbn`, and `remoteID` as optional properties SHALL be handled by SwiftData's automatic lightweight migration; no explicit migration plan code is required.

#### Scenario: Persisted book survives relaunch

- **WHEN** a book is added to the library and the app is relaunched
- **THEN** the book is still present with all its fields intact, including `coverImageURL`, `isbn`, and `remoteID` when set

#### Scenario: Existing seeded book after schema change

- **WHEN** the app launches with a previously-seeded book whose `coverImageURL`, `isbn`, and `remoteID` were never set
- **THEN** the book loads with all three optional properties equal to `nil`
- **AND** the cover renders from the existing `coverAssetName`

### Requirement: Derived reading status

A book's status SHALL be derived from its page counts, not stored:
- `inProgress` when current page is greater than 0 and less than total page count.
- `finished` when current page is greater than or equal to total page count.
- `notStarted` when current page is 0.

For dashboard listing purposes (Reading Now / Finished), `notStarted` books SHALL be treated as in-progress and appear in the Reading Now section so newly added books are visible immediately.

#### Scenario: Newly added book appears in Reading Now

- **WHEN** a book is added with current page 0
- **THEN** its status is treated as in-progress for listing
- **AND** it appears in the Reading Now section of the dashboard

#### Scenario: Book reaches its page total

- **WHEN** a book's current page count is set to a value equal to or greater than its total page count
- **THEN** its status is finished
- **AND** it appears in the Finished section of the dashboard

### Requirement: Read-only library queries

The system SHALL expose a read-only mechanism to list books filtered by derived status (in-progress, finished). The query SHALL be SwiftUI-observable so dashboard sections update automatically when underlying data changes.

#### Scenario: Adding a book updates the dashboard

- **WHEN** a book is inserted into the persistence layer while the dashboard is on screen
- **THEN** the Reading Now section updates to include the new book without an explicit refresh action

### Requirement: Cover placeholder fallback

When a book has no cover-image reference, the UI SHALL render a neutral placeholder that uses design-system tokens (muted surface fill, no brand color). The placeholder SHALL be sized identically to a real cover image so layout does not shift.

#### Scenario: Book without cover

- **WHEN** a book has no cover-image reference
- **THEN** the row renders a neutral placeholder of equal size to a cover image

### Requirement: Books may be inserted from external sources

The library SHALL accept new `Book` rows inserted by other capabilities — currently `book-search`. Inserted books SHALL be observable by the existing read-only library queries (in-progress / finished) without any additional refresh action by the caller.

#### Scenario: Inserted book appears in Reading Now

- **WHEN** another capability inserts a new `Book` with `currentPage = 0`
- **THEN** the book appears in the Reading Now section of the dashboard immediately
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

