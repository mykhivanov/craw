## Context

The Quotes tab is one of four root tabs in `RootView`, currently hosting `PlaceholderTabView(title: "Quotes", message: "Capture quotes during a reading session.")`. Quotes themselves have been a first-class domain since the `quotes-and-thoughts` capability landed: a `Quote` SwiftData `@Model` stores `id: UUID`, `bookID: UUID`, `text: String`, `pageNumber: Int?`, and `capturedAt: Date`, and is registered in `CrawModelContainer.schema`. `BookDetailView` already consumes the quotes via `@Query` filtered by `bookID`, using `QuotesThoughtsReader.quotesPredicate(for:)` and `quoteSortNewestFirst`.

Per `CLAUDE.md`, quotes are local-only — they do not flow through `CrawAPIClient` and the backend's `User` resource only carries library structure for future sync. Consequently the "user model" backing this list is the on-device SwiftData store, not a remote endpoint.

The cross-book browser was explicitly carved out as future work in the existing `quotes-and-thoughts` spec ("Browser and search out of scope" → "deferred to a future `add-quotes-browser` change"). This change implements the browser half of that deferral; cross-book search, highlight, edit, and delete remain out of scope.

Design constraints from `DESIGN.md`: white canvas (`Theme.Palette.canvas`), Rausch accent reserved for primary actions, single shadow tier, `tileCard()` for grouped content, generous rounding. The `mascot` asset is already in the asset catalog and is used by `MascotEmptyTile`.

## Goals / Non-Goals

**Goals:**

- Render every quote the user has captured in a single flat, newest-first list inside the Quotes tab.
- Show each row with quote text, source book title + author, captured-at date, and page number when present, resolved entirely from local SwiftData.
- Provide a persistent mascot header above the list ("Keep it up!" message) that scrolls with content.
- Provide a mascot-led empty state when the user has no quotes captured.
- Reuse existing tokens (`Theme.*`, `tileCard()`) and the existing `mascot` asset; no new design tokens.
- Avoid any new network calls — read directly from the existing `Quote` and `Book` SwiftData entities.

**Non-Goals:**

- No cross-book search or highlighting.
- No edit, delete, share, or copy-to-clipboard affordances on rows.
- No navigation from a row to the book detail or session detail (rows are read-only per user direction).
- No grouping by book or by date (flat chronological only).
- No backend sync, no remote endpoint, no `CrawAPIClient` involvement.
- No schema migration; the existing `Quote` model is sufficient.

## Decisions

### Decision 1: Resolve book metadata via a separate `@Query` rather than a SwiftData relationship

Each row needs the source book's title and author, but the `Quote` model only stores `bookID: UUID`. Two implementation paths:

- **Chosen**: add a sibling `@Query private var books: [Book]` to `QuotesListView`, build a `[UUID: Book]` dictionary at render time, and look up each quote's book by `bookID`.
- Rejected: add a `@Relationship` from `Quote → Book`. This would require a SwiftData schema migration. Since the existing `Quote` model has shipped to users (sample data alone is enough to invalidate "we can wipe the store"), and the lookup dictionary is O(quotes) per render with negligible constants for a personal library, the relationship buys us nothing the dictionary doesn't already give us.

Quotes whose `bookID` does not resolve to a book in the local store (theoretically possible only if a book is later deleted — there is no delete-book UI today) SHALL still render with a fallback subtitle "Unknown book". This keeps the list resilient against future delete flows without forcing this change to also define cascade behavior.

### Decision 2: Mascot header is a sticky-by-position card above the `List`, not a `safeAreaInset`

The user asked for "both — header always + empty state". The persistent header is structured as the first cell in a `ScrollView` + `LazyVStack` composition rather than a `safeAreaInset(edge: .top)` overlay because:

- It should scroll with the list (clarified in this design pass — a pinned header would steal vertical space from the small list of items most users will have early on).
- `safeAreaInset` overlays would also fight `NavigationStack`'s large-title behavior.

The empty state replaces the list entirely (not just the rows) and reuses the mascot at a larger size, mirroring the existing `MascotEmptyTile` composition pattern.

### Decision 3: New `Craw/Quotes/` directory, no top-level placeholder rewrite

`QuotesTab.swift` lives under `Craw/AppShell/` alongside the other top-level tabs and stays small (only swaps the body view). The real surface lives in a new feature folder `Craw/Quotes/` containing:

- `QuotesListView.swift` — the main `@Query`-backed list.
- `QuoteRow.swift` — a single row.
- `QuotesMascotHeader.swift` — the persistent encouragement card.
- `QuotesEmptyState.swift` — the mascot-led empty view.

This mirrors how `Craw/Books/`, `Craw/Home/`, and `Craw/Session/` are organized. Because `Craw/` uses `PBXFileSystemSynchronizedRootGroup`, adding files under `Craw/Quotes/` automatically adds them to the target — no `project.pbxproj` edits.

### Decision 4: Extend `QuotesThoughtsReader` with non-book-scoped sort, do not duplicate

`QuotesThoughtsReader.quoteSortNewestFirst` already exists and is the correct sort for this list. No new helper is needed for the sort. A new helper `QuotesThoughtsReader.allQuotesSortNewestFirst` is **not** introduced — we reuse `quoteSortNewestFirst` directly. We only extend the reader if a non-trivial predicate is needed; for "all quotes" the predicate is omitted from `@Query` entirely.

### Decision 5: Date formatting per row uses `Date.FormatStyle` with `.dateTime.day().month(.abbreviated).year()`

Matches the captured-at presentation style used elsewhere in the app (BookDetailView's quote list rendering). No new date-formatting utility introduced.

### Decision 6: Page number, when present, is rendered as a trailing chip styled with `Theme.Typography.captionSm` and `Theme.Palette.muted`

When absent, no chip is shown — the row collapses to just text + book subtitle + date. This matches the BookDetailView convention.

## Risks / Trade-offs

- **Risk**: A user with hundreds of quotes hits SwiftUI `List` performance issues. **Mitigation**: rely on `List`'s built-in cell recycling; if needed, switch to `LazyVStack` in a `ScrollView`. Not optimizing prematurely — typical readers will have tens of quotes.
- **Risk**: The `[UUID: Book]` dictionary is rebuilt every render of `QuotesListView`. **Mitigation**: it's keyed by a small number of books (the user's library), constructed once per body re-evaluation, and SwiftUI's diffing keeps re-renders limited. If profiling shows it, memoize behind a computed property on a `@State` cache keyed by `books.count`.
- **Risk**: The persistent mascot header competes with content for screen real estate on smaller devices. **Mitigation**: keep the header compact (mascot ≤ 80pt tall, single line of copy), and have it scroll with content so it doesn't pin space.
- **Risk**: "Unknown book" fallback exposes orphaned quotes if a future delete-book change ships without cascading. **Mitigation**: documented in this design; the future delete flow owns cascade behavior, not this change.
- **Trade-off**: No tap-to-navigate. Loses a discoverability path to the book detail, but matches the user's explicit "read-only" directive and keeps scope small.
- **Trade-off**: No grouping by book. Users with many quotes per book see repetition of the book subtitle, but the flat newest-first ordering is the simplest mental model and matches per-book ordering already used in BookDetailView.

## Migration Plan

No data migration required. The change is additive on the UI side and removes the placeholder. Rollback is a one-commit revert of `QuotesTab.swift` plus deletion of the new `Craw/Quotes/` folder.

## Open Questions

- Should the mascot header copy ("Keep it up!") vary based on streak state (e.g., reference the user's current reading streak)? — Treated as out of scope for this change; copy is static. Can be revisited once the Stats tab ships a shared streak model.
