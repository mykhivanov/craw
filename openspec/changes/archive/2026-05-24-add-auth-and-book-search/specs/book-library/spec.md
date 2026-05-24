## MODIFIED Requirements

### Requirement: Book domain model

The system SHALL persist a `Book` entity with the following fields: stable identifier (`id`), optional backend identifier (`remoteID`), title, author, optional bundled cover-asset reference (`coverAssetName`), optional remote cover URL (`coverImageURL`), optional ISBN (`isbn`), total page count, current page count, date added. The model SHALL be persisted using the app's chosen on-device storage layer (SwiftData, per design). Adding `coverImageURL`, `isbn`, and `remoteID` as optional properties SHALL be handled by SwiftData's automatic lightweight migration; no explicit migration plan code is required.

#### Scenario: Persisted book survives relaunch

- **WHEN** a book is added to the library and the app is relaunched
- **THEN** the book is still present with all its fields intact, including `coverImageURL`, `isbn`, and `remoteID` when set

#### Scenario: Existing seeded book after schema change

- **WHEN** the app launches with a previously-seeded book whose `coverImageURL`, `isbn`, and `remoteID` were never set
- **THEN** the book loads with all three optional properties equal to `nil`
- **AND** the cover renders from the existing `coverAssetName`

## REMOVED Requirements

### Requirement: Book write operations are out of scope

**Reason**: This change introduces a production-supported add-book path sourced from the custom backend's book search. Book creation is therefore in scope for the library capability; subsequent changes will define edit and delete.

**Migration**: The previously-stub "coming soon" add-book affordance on `HomeDashboardView` is now wired to present the search sheet defined in the `book-search` capability. No data migration is required — books inserted via search use the same `Book` model the seeded sample data uses.

## ADDED Requirements

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
