## ADDED Requirements

### Requirement: Book domain model

The system SHALL persist a `Book` entity with the following fields: stable identifier, title, author, optional cover-image reference, total page count, current page count, date added. The model SHALL be persisted using the app's chosen on-device storage layer (SwiftData, per design).

#### Scenario: Persisted book survives relaunch

- **WHEN** a book is added to the library and the app is relaunched
- **THEN** the book is still present with all its fields intact

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

### Requirement: Book write operations are out of scope

This capability SHALL NOT define book creation, editing, or deletion. Those operations are owned by a future `add-book-management` change. Within this change, books MAY be seeded via a debug-only sample-data path to exercise the dashboard.

#### Scenario: No user-facing add or delete

- **WHEN** the user interacts with any Home-tab surface in this change
- **THEN** no production code path creates, edits, or deletes a book
- **AND** the add-book affordance is wired to a "coming soon" no-op placeholder
