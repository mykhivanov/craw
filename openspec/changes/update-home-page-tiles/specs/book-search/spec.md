## MODIFIED Requirements

### Requirement: Result mapping from backend response

The backend SHALL return a JSON envelope `{ "items": [SearchBook], "next_offset": Int? }` where each `SearchBook` has the fields documented by the `Book` schema in `api-contract.yaml`. When the user selects a result **and confirms an attitude in the book-attitude picker**, the system SHALL insert a new `Book` row into the on-device library mapped as follows:

- `remoteID` ← `SearchBook.id`
- `title` ← `SearchBook.title`
- `author` ← `SearchBook.author` (the backend pre-joins authors and substitutes "Unknown author" if missing)
- `totalPages` ← `SearchBook.totalPages` (the backend supplies a non-zero default if missing upstream)
- `coverImageURL` ← `SearchBook.coverImageURL` (already HTTPS, never `http://`)
- `isbn` ← `SearchBook.isbn` (preferring ISBN-13)
- `currentPage` ← 0
- `dateAdded` ← the time of insertion
- **`attitude` ← the value the user picked in the book-attitude picker (`entertainment` or `study`)**

#### Scenario: Adding a result

- **WHEN** the user selects a returned `SearchBook`
- **AND** confirms an attitude in the book-attitude picker
- **THEN** a new `Book` is inserted with the fields mapped exactly per the rules above, including `attitude`
- **AND** the book-attitude picker dismisses
- **AND** the search sheet dismisses
- **AND** the new book appears in the corresponding attitude-scoped tile on the Home tab

#### Scenario: Empty items array

- **WHEN** the response is `{"items": [], "next_offset": null}`
- **THEN** the view enters `empty` state with a message referencing the current query

## ADDED Requirements

### Requirement: Book attitude picker gates insertion

After the user selects a `SearchBook` from the results list, the system SHALL present a modal **book-attitude picker** before inserting any `Book` into the library. The picker SHALL ask the question framed around the user's intent (not the book's genre) — e.g., *"Why are you adding this book?"* — and SHALL offer exactly two selectable options labeled around attitude: one for `entertainment` and one for `study`. The primary "Add to library" action SHALL be disabled until the user picks one option. Dismissing the picker without confirming SHALL NOT insert the book and SHALL return the user to the search results, with the search sheet still open.

#### Scenario: Picker appears after selecting a result

- **WHEN** the user taps a search result row
- **THEN** the book-attitude picker is presented as a modal
- **AND** no `Book` is inserted yet
- **AND** the search sheet remains in the navigation stack beneath the picker

#### Scenario: Confirm inserts with chosen attitude

- **WHEN** the user picks the entertainment option in the picker
- **AND** taps the "Add to library" primary action
- **THEN** a new `Book` is inserted with `attitude = entertainment`
- **AND** both the picker and the search sheet dismiss

#### Scenario: Cancel does not insert

- **WHEN** the user dismisses the book-attitude picker without confirming
- **THEN** no `Book` is inserted into the library
- **AND** the user remains on the search results screen

#### Scenario: Primary action is disabled before selection

- **WHEN** the picker is presented and the user has not yet picked an option
- **THEN** the "Add to library" primary action is disabled
- **AND** tapping it has no effect
