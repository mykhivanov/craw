## ADDED Requirements

### Requirement: Book detail replaces the placeholder

The book-detail destination SHALL replace the `BookDetailPlaceholder` introduced by `add-home-dashboard`. Tapping a row in Reading Now or Finished SHALL push this real detail screen onto the Home tab's navigation stack.

#### Scenario: Tap pushes real detail

- **WHEN** the user taps a book row in Reading Now or Finished
- **THEN** the book-detail screen is pushed, not the placeholder

### Requirement: Detail content

The book-detail screen SHALL display: cover image (or placeholder), title, author, "current page / total pages" text, a circular progress indicator showing fractional completion, the "Start reading session" CTA, and two collapsible lists for quotes and thoughts on this book.

#### Scenario: Detail layout

- **WHEN** the user opens the book detail
- **THEN** the screen shows cover, title, author, page-progress text, circular progress, the Start CTA, a quotes list, and a thoughts list

### Requirement: Circular progress visual

The detail screen's circular progress SHALL reuse the day-cell ring composition from `add-home-dashboard` to maintain visual consistency. The ring SHALL fill in proportion to `currentPage / totalPages`, with totalPages of zero rendering as an unfilled outline.

#### Scenario: 45% complete

- **WHEN** a book has currentPage = 90 and totalPages = 200
- **THEN** the ring is filled to approximately 45% of its circumference

#### Scenario: Total pages unknown

- **WHEN** a book has totalPages = 0
- **THEN** the ring renders as an unfilled outline

### Requirement: Start CTA visibility

The "Start reading session" CTA SHALL be visible on the book detail regardless of the book's current status (in-progress, finished, or not-yet-started). For a finished book, starting a session SHALL be permitted — the user is re-reading.

#### Scenario: Finished book retains the CTA

- **WHEN** the user opens the detail for a book whose current page equals its total page count
- **THEN** the "Start reading session" CTA is still visible and tappable

### Requirement: Lists are read-only in this change

The quotes and thoughts lists on the book detail SHALL be read-only — no add, edit, or delete affordances on this screen. Capture happens during a session and at the post-session prompt; deletion and editing are out of scope until `add-quotes-browser`.

#### Scenario: No edit controls on detail lists

- **WHEN** the user views the quotes or thoughts list on the book detail
- **THEN** no controls are present to add, edit, or delete items from the list
