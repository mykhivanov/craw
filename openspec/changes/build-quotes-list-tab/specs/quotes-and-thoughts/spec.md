## ADDED Requirements

### Requirement: Cross-book quotes list surface

The system SHALL provide a cross-book quotes list view that displays every `Quote` persisted in the on-device SwiftData store as a single flat list ordered by `capturedAt` descending. Each row SHALL display the quote text, the source book's title and author (resolved from the local `Book` store via `Quote.bookID`), the captured-at date, and the page number when present. The list SHALL be reached via the root Quotes tab and SHALL NOT issue any network requests.

#### Scenario: Listing every quote across books

- **WHEN** the user opens the Quotes tab with three quotes captured against book A and two quotes captured against book B
- **THEN** the screen displays all five quotes in a single list ordered newest-first by `capturedAt`
- **AND** each row shows the quote text, the corresponding book's title and author, and the captured-at date

#### Scenario: Row with a page number

- **WHEN** a quote in the list has `pageNumber == 42`
- **THEN** the row renders a page indicator showing "42" in the trailing region of the row

#### Scenario: Row without a page number

- **WHEN** a quote in the list has `pageNumber == nil`
- **THEN** the row renders without any page indicator
- **AND** the rest of the row layout remains unchanged

#### Scenario: Quote whose book is missing from the local store

- **WHEN** a quote's `bookID` does not resolve to any `Book` in the local store
- **THEN** the row renders the quote text and a fallback subtitle of "Unknown book"
- **AND** the row is still tappable as a read-only row (no action is performed)

### Requirement: Mascot affordance on the Quotes tab

The Quotes tab SHALL render the `mascot` image asset paired with an encouraging static caption. When the user has at least one quote captured, the mascot SHALL appear as a compact header card above the list that scrolls with content. When the user has zero quotes captured, the list SHALL be replaced by a mascot-led empty state that uses the same `mascot` asset at a larger size and explains how to capture a first quote.

#### Scenario: Mascot header with quotes present

- **WHEN** the user opens the Quotes tab and at least one quote is persisted
- **THEN** a compact mascot header card is shown above the first row
- **AND** the header card scrolls together with the list as the user scrolls

#### Scenario: Mascot empty state with no quotes

- **WHEN** the user opens the Quotes tab and no quotes are persisted
- **THEN** the list is not rendered
- **AND** a mascot-led empty state is shown explaining that quotes are captured during a reading session

### Requirement: Quotes list is read-only

Quote rows in the cross-book quotes list SHALL be read-only. Tapping a row SHALL NOT navigate to any detail screen, open an edit/delete sheet, or trigger any other action in this change.

#### Scenario: Tapping a row has no effect

- **WHEN** the user taps any quote row in the Quotes tab list
- **THEN** no navigation occurs
- **AND** no sheet or alert is presented

## MODIFIED Requirements

### Requirement: Browser and search out of scope

This capability SHALL NOT define cross-book quote search, search-term highlighting, or any quote/thought editing or deletion UI. A cross-book quotes browser IS now defined by the "Cross-book quotes list surface" requirement; thoughts have no equivalent cross-book browser and remain out of scope.

#### Scenario: No cross-book search or edit affordance

- **WHEN** the user navigates the Quotes tab
- **THEN** no search field, highlight affordance, edit affordance, or delete affordance is presented
- **AND** thoughts are not surfaced anywhere on the Quotes tab
