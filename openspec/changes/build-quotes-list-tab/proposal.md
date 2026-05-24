## Why

The Quotes tab currently renders a generic "Coming soon" placeholder, but users have already been able to capture quotes from reading sessions for several releases. Their quotes accumulate in the on-device SwiftData store with no way to revisit them outside of the per-book detail screen. This change ships the cross-book quotes browser previously deferred at the bottom of the `quotes-and-thoughts` spec, turning a dead tab into the primary review surface for everything the user has saved.

## What Changes

- Replace `PlaceholderTabView` inside `QuotesTab` with a real `QuotesListView` backed by the existing `Quote` SwiftData model — no new network endpoint, no separate fetcher.
- Show a flat, newest-first list of every quote across every book, with each row displaying the quote text, the source book's title and author, the captured-at date, and the page number when present.
- Add a persistent mascot header above the list with an encouraging "Keep it up!" message that scrolls with content when quotes exist.
- Add a mascot-driven empty state shown only when the user has zero quotes captured.
- Rows are read-only (no tap action, no edit/delete UI in this change).
- Resolve each quote's book by looking up the existing `Book` model via `bookID`; do not change the `Quote` schema unless a join requires it.
- **BREAKING (spec only)**: remove the "Browser and search out of scope" requirement from `quotes-and-thoughts` for the cross-book browser portion; cross-book search and editing remain out of scope.

## Capabilities

### New Capabilities

_None._

### Modified Capabilities

- `quotes-and-thoughts`: adds a new requirement for a cross-book quotes list surface, and narrows the existing "out of scope" requirement so it no longer forbids the browser (search, highlighting, edit, and delete remain out of scope).
- `app-shell`: replaces the Quotes-tab placeholder requirement with a requirement that the Quotes tab hosts the new `QuotesListView`.

## Impact

- **Code**: `Craw/AppShell/QuotesTab.swift` (swap placeholder for real view), new file `Craw/Quotes/QuotesListView.swift`, new file `Craw/Quotes/QuoteRow.swift`, new file `Craw/Quotes/QuotesMascotHeader.swift`, new file `Craw/Quotes/QuotesEmptyState.swift`. Optional touch-up to `Craw/Persistence/QuotesThoughtsReader.swift` to expose a non-book-scoped sort/query helper.
- **Data**: reuses the existing `Quote` SwiftData entity; no schema migration. Book lookup uses an additional `@Query [Book]` resolved into a `[UUID: Book]` dictionary at render time.
- **Sample data**: `SampleData.seedIfEmpty` already inserts quotes against the seeded books in DEBUG; no change required, but the Quotes tab will now visibly reflect them.
- **APIs / network**: none. Per `CLAUDE.md`, quotes remain local-only in SwiftData and the Clerk-authenticated `CrawAPIClient` is not involved.
- **Design system**: reuses `Theme.Typography`, `Theme.Palette`, `Theme.Spacing`, `tileCard()`, and the existing `mascot` image asset; no new tokens.
- **Tests**: there is no test target in the project; verification is manual via the simulator with `-CrawSeedSampleData YES` and the empty-state path with seeding disabled.
