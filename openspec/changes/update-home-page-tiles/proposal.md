## Why

The Home feed today is a linear stack (greeting → live counter subline → 7-day strip → stat cards → Reading Now → Finished). It works, but it asks the user to scan the same scroll surface for very different intents — "what am I currently reading for fun?", "what am I studying?", "is the community reading right now?", "give me a moment of inspiration". We want to reshape Home as a **tile grid** that pulls those intents apart, gives the live "people reading now" number its own focus, and rewards users with a quote of the day plus a mascot moment on first launch. We also need the library to know whether a book is for *entertainment* or *study* — a one-time question asked when the user adds a book, reflecting their **attitude** toward it, not the book's genre.

## What Changes

- Reshape `HomeDashboardView` into a tile-based layout. The existing greeting, 7-day strip, and stat cards stay; the **book list sections, live counter, and a new "quote of the day" tile** all become tiles.
- Add a new **Entertainment book** tile that shows the user's current in-progress entertainment book (cover, title, author, progress). When no entertainment book is in progress, the tile shows an empty state with an "Add a book" call to action that opens `BookSearchView`.
- Add a new **Book to study** tile mirroring the same shape for study books.
- **BREAKING (model)**: Add a non-optional `attitude` attribute to the `Book` SwiftData model. Allowed values: `entertainment`, `study`. SwiftData lightweight migration will populate existing rows with a default of `entertainment`. (See `design.md` for the migration default rationale.)
- During the **Add a book** flow (`BookSearchView`), after the user picks a search result, ask one extra question — phrased around attitude, not genre — and store the answer on the new `Book`. The user cannot complete the add without choosing.
- Promote the **"people reading now" counter to its own tile** (currently rendered as a subline beneath the greeting). The tile SHALL update **every 10 seconds**, stay anchored around ~200 with small up/down drift, and use the on-device counter (no network). The old counter subline beneath the greeting is removed.
- Add a **Quote of the day** tile rendering a hardcoded quote and attribution for v1: *"In the end, it's not the years in your life that count. It's the life in your years." — Abraham Lincoln*, plus subtitle *"Remember, you can find quote closer too you in your next book!"*.
- Replace the **library-empty state** with a **Mascot** tile — uses the existing `mascot` image asset, has a call-to-action heading and "Add your first book" button, and replaces the Entertainment + Book-to-study + Quote-of-the-day tiles entirely when the user has zero books. (The greeting, 7-day strip, stat cards, and live-counter tile remain visible.)
- Preserve current visual language (white canvas, Rausch accent, card radius, card-soft surface, typography tokens). No new colors, no new fonts. Spacing for the grid uses existing `Theme.Spacing` tokens.

## Capabilities

### New Capabilities

_(none — all changes extend existing capabilities)_

### Modified Capabilities

- `home-dashboard`: The single-feed section list becomes a tile-based layout. The "live people reading now" subline becomes a dedicated tile with a 10-second tick. New tiles are added (Entertainment book, Book to study, Quote of the day, Mascot empty state). The flat Reading Now / Finished sections are replaced by the two attitude-scoped tiles plus the existing Finished section.
- `book-library`: The `Book` model gains a required `attitude` field (`entertainment` | `study`). Read-only queries gain attitude-scoped variants used by the new tiles.
- `book-search`: The add-a-book result-selection flow gains an attitude prompt; selection alone no longer inserts a book — the user must answer "Why are you adding this book?" first.

## Impact

- **Modified files** (Swift):
  - `Craw/Persistence/Book.swift` — add `attitude: BookAttitude` stored property, public enum `BookAttitude` (`entertainment`, `study`), update initializer.
  - `Craw/Persistence/BookLibraryReader.swift` — add attitude-scoped predicates (`inProgressEntertainmentPredicate`, `inProgressStudyPredicate`).
  - `Craw/Persistence/SampleData.swift` — set explicit attitude on each seeded book so the new tiles have content in DEBUG.
  - `Craw/Books/Search/BookSearchView.swift` — gate insertion behind an attitude-picker sheet; persist the answer on the new `Book`.
  - `Craw/Home/HomeDashboardView.swift` — replace `bookSections` with the new tile composition.
  - `Craw/Home/Sections/EmptyStateViews.swift` — repurpose / extend with a `MascotEmptyState`.
  - `Craw/Home/Sections/StatCardsSection.swift` — unchanged in behavior; same row stays.
  - `Craw/Home/Sections/GreetingSection.swift` — remove the "people reading now" subline that lives here today (the live counter moves to its own tile).
- **New files** (Swift):
  - `Craw/Home/Tiles/EntertainmentBookTile.swift`
  - `Craw/Home/Tiles/StudyBookTile.swift`
  - `Craw/Home/Tiles/LiveCounterTile.swift`
  - `Craw/Home/Tiles/QuoteOfTheDayTile.swift`
  - `Craw/Home/Tiles/MascotEmptyTile.swift`
  - `Craw/Books/Search/BookAttitudePicker.swift` (sheet presented after a search result is tapped)
- **Migration**: SwiftData lightweight migration sets `attitude = .entertainment` for any existing row at first launch on a build that introduces the field. No explicit `SchemaMigrationPlan` code is required.
- **No** networking changes, no new SwiftPM dependencies, no new `Info.plist` keys, no Clerk-side changes.
- **Manual verification only** (no test target). Launch arguments to exercise the variants: `-CrawSeedSampleData YES` (full Home), no flag (mascot empty state).
