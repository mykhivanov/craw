## MODIFIED Requirements

### Requirement: Book domain model

The system SHALL persist a `Book` entity with the following fields: stable identifier (`id`), optional backend identifier (`remoteID`), title, author, optional bundled cover-asset reference (`coverAssetName`), optional remote cover URL (`coverImageURL`), optional ISBN (`isbn`), total page count, current page count, date added, **and a required `attitude` (one of `entertainment`, `study`) capturing the user's reason for adding the book**. The model SHALL be persisted using the app's chosen on-device storage layer (SwiftData, per design). Adding `coverImageURL`, `isbn`, and `remoteID` as optional properties SHALL be handled by SwiftData's automatic lightweight migration; **adding `attitude` as a required field SHALL likewise be handled by SwiftData's automatic lightweight migration, with existing rows defaulting to `entertainment`**.

#### Scenario: Persisted book survives relaunch

- **WHEN** a book is added to the library and the app is relaunched
- **THEN** the book is still present with all its fields intact, including `coverImageURL`, `isbn`, `remoteID`, and `attitude`

#### Scenario: Existing seeded book after schema change

- **WHEN** the app launches with a previously-seeded book whose `coverImageURL`, `isbn`, and `remoteID` were never set
- **THEN** the book loads with all three optional properties equal to `nil`
- **AND** the cover renders from the existing `coverAssetName`

#### Scenario: Pre-existing row after attitude migration

- **WHEN** the app launches on a build that introduces the `attitude` field
- **AND** a previously-stored `Book` row exists from a prior build
- **THEN** the row loads successfully
- **AND** its `attitude` value is `entertainment`

### Requirement: Read-only library queries

The system SHALL expose a read-only mechanism to list books filtered by:

- derived status (in-progress, finished), AND
- the new `attitude` attribute (`entertainment`, `study`).

The system SHALL expose at least the following observable query shapes used by the Home tab:

- in-progress books (irrespective of attitude),
- in-progress books with `attitude == entertainment`,
- in-progress books with `attitude == study`,
- finished books.

Each query SHALL be SwiftUI-observable so dashboard sections update automatically when underlying data changes.

#### Scenario: Adding a book updates the dashboard

- **WHEN** a book is inserted into the persistence layer while the dashboard is on screen
- **THEN** the in-progress query result updates to include the new book without an explicit refresh action

#### Scenario: Attitude-scoped query reflects attitude

- **WHEN** a book is inserted with `attitude = entertainment`
- **THEN** it appears in the in-progress-entertainment query result
- **AND** it does NOT appear in the in-progress-study query result

## ADDED Requirements

### Requirement: Book attitude is required and immutable in v1

The `Book` model SHALL store an `attitude` value chosen from `entertainment` or `study`. The attitude SHALL be required on insertion — there is no nullable `attitude` and no in-code default for newly-constructed `Book` instances. In v1, no UI affordance permits changing a book's attitude after the book is inserted.

#### Scenario: Attitude is set at insertion

- **WHEN** a new `Book` is inserted via the add-book flow
- **THEN** its `attitude` is either `entertainment` or `study` based on the user's selection
- **AND** the value persists across relaunches

#### Scenario: No edit affordance exists in v1

- **WHEN** the user views a book's detail screen
- **THEN** there is no control that changes the book's attitude
