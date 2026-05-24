## MODIFIED Requirements

### Requirement: Vertically scrolling single-feed layout

The Home tab SHALL present its content as a single vertically scrolling feed. The feed SHALL appear in this top-to-bottom order: (1) greeting, (2) 7-day calendar strip, (3) stat cards row, (4) **tile column**. Tiles in the tile column SHALL each span the full available width — tiles are NOT arranged as a multi-column grid — so each tile is free to use as much horizontal space as it needs (book covers, the live counter, the quote, the mascot).

The tile column SHALL contain, in this order:

- **When the library is empty (zero books, including zero finished)**: a Mascot tile, then the Entertainment book tile (in its empty state), then the Book to study tile (in its empty state), then the Live counter tile, then the Quote of the day tile.
- **When the library has at least one book**: the Entertainment book tile (showing its book or its empty state), then the Book to study tile (showing its book or its empty state), then the Live counter tile, then the Quote of the day tile. The Mascot tile SHALL NOT be rendered.

The previously-rendered "Reading Now" and "Finished" sections SHALL NOT be rendered on the Home tab.

#### Scenario: Section ordering with content

- **WHEN** the user views the Home tab with at least one book in the library
- **THEN** the sections render in the order: greeting, 7-day strip, stat cards, Entertainment book tile, Book to study tile, Live counter tile, Quote of the day tile
- **AND** the Mascot tile is NOT rendered

#### Scenario: Section ordering when library is empty

- **WHEN** the user views the Home tab and the library contains zero books
- **THEN** the sections render in the order: greeting, 7-day strip, stat cards, Mascot tile, Entertainment book tile (empty state), Book to study tile (empty state), Live counter tile, Quote of the day tile

#### Scenario: Tiles span full width

- **WHEN** the user views any tile in the tile column
- **THEN** the tile spans the full content-area width
- **AND** no two tiles in the tile column appear side-by-side in the same row

### Requirement: Live "people reading now" counter

The dashboard SHALL display an estimated "people reading now" count **as a dedicated full-width tile** inside the tile grid. The tile SHALL update its displayed value every 10 seconds. The value SHALL remain anchored near 200 (within the inclusive range 180–220), SHALL drift smoothly so two consecutive updates differ by at most 5, and SHALL be derivable on-device with no network call.

#### Scenario: Counter tile is visible

- **WHEN** the user views the Home tab
- **THEN** a tile labeled "People reading now" is visible inside the tile grid
- **AND** the tile shows a positive integer value

#### Scenario: Counter ticks every 10 seconds

- **WHEN** the user observes the counter tile for at least 30 seconds without leaving the screen
- **THEN** the displayed value updates at least twice
- **AND** each update arrives approximately 10 seconds after the previous one

#### Scenario: Counter stays in range and drifts smoothly

- **WHEN** the user observes consecutive counter values for at least one minute
- **THEN** every observed value is in the inclusive range 180–220
- **AND** no single update changes the value by more than 5

### Requirement: Empty states

The dashboard SHALL render dedicated empty states when content is absent:

- When zero books exist in total, a **Mascot tile** containing the bundled `mascot` image, a headline, body copy, and a primary "Add a book" call-to-action that opens the book-search sheet SHALL be rendered at the top of the tile column. The Entertainment book tile, Book to study tile, Live counter tile, and Quote of the day tile SHALL ALSO be rendered (the Mascot does not replace them) so the user still sees the dashboard's tile structure on first launch.
- When the library is not empty but no in-progress entertainment book exists, the Entertainment book tile SHALL display its own empty state with a call-to-action that opens the book-search sheet.
- When the library is not empty but no in-progress study book exists, the Book to study tile SHALL display its own empty state with a call-to-action that opens the book-search sheet.

The Entertainment book tile and Book to study tile SHALL always be rendered on the Home tab regardless of library state — their content varies (book or empty-state CTA) but they are never hidden.

#### Scenario: First-launch empty state

- **WHEN** the user opens the app and the library contains zero books
- **THEN** the Mascot tile is visible at the top of the tile column
- **AND** the Entertainment book tile is also visible, in its empty state, with an "Add a book" CTA
- **AND** the Book to study tile is also visible, in its empty state, with an "Add a book" CTA
- **AND** every tile's "Add a book" button opens the book-search sheet

#### Scenario: Library has only finished books

- **WHEN** the user has one or more finished books and zero in-progress books
- **THEN** the Mascot tile is NOT shown
- **AND** the Entertainment book tile renders its own empty-state CTA
- **AND** the Book to study tile renders its own empty-state CTA
- **AND** the Quote of the day tile is still visible

#### Scenario: Library has only an entertainment book in progress

- **WHEN** the user has one in-progress book with attitude `entertainment` and zero in-progress books with attitude `study`
- **THEN** the Entertainment book tile shows that book
- **AND** the Book to study tile shows its empty-state CTA

## ADDED Requirements

### Requirement: Entertainment book tile

The dashboard SHALL render a tile labeled around the user's current in-progress **entertainment** book. The tile SHALL show the book's cover (or the neutral placeholder when no cover is set), title, author, and a progress bar representing pages-read / total-pages. Tapping the tile body SHALL push the book detail destination onto the Home navigation stack. When more than one in-progress entertainment book exists, the tile SHALL show the most-recently-added one (`Book.dateAdded` descending).

#### Scenario: One in-progress entertainment book

- **WHEN** the user has exactly one in-progress book with attitude `entertainment`
- **THEN** the Entertainment book tile renders that book's cover, title, author, and progress bar

#### Scenario: Tapping the tile opens detail

- **WHEN** the user taps the body of the Entertainment book tile
- **THEN** the corresponding book detail view is pushed onto the Home navigation stack

#### Scenario: Multiple in-progress entertainment books

- **WHEN** the user has two in-progress books with attitude `entertainment`
- **THEN** the Entertainment book tile shows the one with the most recent `dateAdded`

### Requirement: Book to study tile

The dashboard SHALL render a tile labeled around the user's current in-progress **study** book. The tile SHALL show the book's cover (or the neutral placeholder), title, author, and a progress bar. Tapping the tile body SHALL push the book detail destination onto the Home navigation stack. When more than one in-progress study book exists, the tile SHALL show the most-recently-added one (`Book.dateAdded` descending).

#### Scenario: One in-progress study book

- **WHEN** the user has exactly one in-progress book with attitude `study`
- **THEN** the Book to study tile renders that book's cover, title, author, and progress bar

#### Scenario: Tapping the tile opens detail

- **WHEN** the user taps the body of the Book to study tile
- **THEN** the corresponding book detail view is pushed onto the Home navigation stack

### Requirement: Quote of the day tile

The dashboard SHALL render a tile that contains a quote-of-the-day block plus an engagement subtitle. For v1, the quote, attribution, and subtitle are hardcoded. The tile SHALL display:

- Quote text: *"In the end, it's not the years in your life that count. It's the life in your years."*
- Attribution: *"— Abraham Lincoln"*
- Subtitle: *"Remember, you can find quote closer too you in your next book!"*

The tile SHALL NOT be tappable in v1 and SHALL NOT make any network call.

#### Scenario: Quote of the day is visible

- **WHEN** the user views the Home tab with a non-empty library
- **THEN** a tile renders the quote text, attribution, and engagement subtitle exactly as specified above

#### Scenario: Quote of the day is visible even when library is empty

- **WHEN** the user views the Home tab and the library contains zero books
- **THEN** the Quote of the day tile is still rendered (below the Mascot tile and the Live counter tile)

### Requirement: Mascot tile is the empty-library hero

The Mascot tile SHALL use the bundled `mascot` image asset (`Assets.xcassets/mascot.imageset`), a headline communicating "Your library is empty", body copy inviting the user to add their first book, and a primary "Add a book" button styled with the Rausch accent color. Tapping the button SHALL open the book-search sheet. The Mascot tile SHALL render only when the library contains zero books and SHALL appear at the top of the tile column above the attitude tiles.

#### Scenario: Mascot tile renders for empty library

- **WHEN** the library contains zero books (in-progress or finished)
- **THEN** the Mascot tile is visible
- **AND** the tile contains the `mascot` image, a headline, body copy, and an "Add a book" button
- **AND** the Mascot tile is the first tile in the tile column (above the Entertainment and Study tiles)

#### Scenario: Mascot CTA opens search

- **WHEN** the user taps the "Add a book" button on the Mascot tile
- **THEN** the book-search sheet is presented

## REMOVED Requirements

### Requirement: Reading Now section

**Reason**: Replaced by the Entertainment book tile and Book to study tile, which split the same content along the user's stated attitude rather than along arbitrary list ordering.

**Migration**: The same in-progress books still surface on Home — they are now distributed across two attitude-scoped tiles based on each book's `Book.attitude`. Books added before this change default to `entertainment` (see book-library spec delta), so they appear in the Entertainment book tile.

### Requirement: Finished section

**Reason**: Home shifts focus to *active* reading attitudes. Finished books remain accessible from elsewhere (book-detail navigation, future Library tab), but are no longer rendered on the Home tab.

**Migration**: Finished `Book` rows are not deleted — they remain queryable via `BookLibraryReader.finishedPredicate`. They simply do not appear on Home anymore.
