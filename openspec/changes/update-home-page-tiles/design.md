## Context

`HomeDashboardView` currently composes the Home tab as a single linear `LazyVStack`: `GreetingSection → WeekStripSection → StatCardsSection → BookListSection("Reading Now") → BookListSection("Finished")`. Live "people reading now" is a `captionSm` subline beneath the greeting (`LiveCounterLabel`, ticking every 8s) and the figure drifts between ~1000 and ~9000 based on hour of day. The library has no notion of *why* a book is on the shelf, so the two book lists are split purely by completion status, not by user intent.

Product wants Home to feel like a personal dashboard of tiles. Each tile owns one job:
- "What am I currently reading **for fun**?" → Entertainment tile.
- "What am I currently **studying**?" → Study tile.
- "Is the community reading right now?" → Live-counter tile (own focus, not a subline).
- "Inspire me." → Quote-of-the-day tile.
- On first run with an empty library, none of those four resolve — the user should see the **mascot** and a single call to action instead.

To support this, the `Book` model needs to know the user's **attitude** toward the book (entertainment vs. study). This is captured once, at add time, by a one-question sheet — it is intentionally a property of the *user's intent*, not the book's metadata, so it does not come from the backend search response.

## Goals / Non-Goals

**Goals:**

- Reshape Home into a tile grid while reusing every existing design token (`Theme.Palette`, `Theme.Typography`, `Theme.Radius`, `Theme.Spacing`) and the existing `crawCard()`-style card chrome.
- Make the live counter its own visual unit, ticking every 10 seconds, anchored ≈200 with small drift, no network call.
- Give books an `attitude` (`entertainment` | `study`) captured during the add-book flow and persisted in SwiftData.
- Render distinct empty states per attitude tile so the user always knows the next action.
- Replace the whole content area below the stat cards with a **Mascot** tile when the library is empty.

**Non-Goals:**

- Backend sync of the new `attitude` field — local-only for now. (`User` resource hydration in the API contract is unaffected.)
- Letting users change a book's attitude after adding it (no edit affordance in this change).
- Replacing the existing 7-day strip or stat cards row — those keep their current treatment.
- Real "people reading now" data from a server. Still on-device, still deterministic.
- Quote-of-the-day sourcing — v1 is a single hardcoded quote. No quote-of-the-day cycling, no remote source, no calendar-aware rotation yet.
- A "Finished" section. The existing Finished list is no longer rendered on Home; finished books are still queryable and still surface in book detail, but Home becomes about *active* reading attitudes plus the quote. (If product wants Finished back on Home, that becomes a follow-up tile.)
- Localizing the new copy (English only, matching the rest of the app).
- Reordering or restyling the greeting/week-strip/stat-cards row.

## Decisions

### Tile column layout

The tile area is a single-column **`VStack`** nested inside the page's existing `LazyVStack`. Every tile spans the full content-area width. There is **no `LazyVGrid`** and no side-by-side tile row anywhere in this band — the only multi-column structure on Home remains the existing `StatCardsSection` (Today's Pages + Streak). The page therefore mixes a 2-up stat row with full-width tiles below, giving the dashboard visual variety without a "column wall" feel.

Why full-width attitude tiles: when a book is present, its cover wants room (the cover-placeholder frame is comfortably 100–140 pt tall at full width); when no book is present, the empty-state CTA reads better at full width than squeezed into a 2-col cell.

The **Entertainment book** and **Book to study** tiles are **always rendered** regardless of library state. The Mascot tile is added at the top of the column only when the library is fully empty — it does not replace the attitude tiles, it accompanies them.

Final compositional order (top to bottom):

1. `GreetingSection` *(without the counter subline — see "Greeting cleanup" below)*
2. `WeekStripSection`
3. `StatCardsSection` (existing 2-up row)
4. **Tile column** (single-column `VStack`, `Theme.Spacing.md` between tiles):
   - **If library is empty**: `MascotEmptyTile` → `EntertainmentBookTile (empty state)` → `StudyBookTile (empty state)` → `LiveCounterTile` → `QuoteOfTheDayTile`
   - **If library has at least one book**: `EntertainmentBookTile` → `StudyBookTile` → `LiveCounterTile` → `QuoteOfTheDayTile`

Tile chrome reuses the existing pattern from `StatCardsSection` (`surfaceCard` background, `hairlineSoft` 1pt overlay, `Radius.card` rounding, `Spacing.base` padding). It is lifted into a shared `tileCard()` view modifier (in `Craw/Home/Tiles/TileCard.swift`) rather than re-declared in every tile file.

**Alternatives considered**

- *2-column `LazyVGrid` for the attitude tiles with `gridCellColumns(2)` for full-width tiles.* Originally chosen; rejected after first round of design review because (a) it makes the dashboard read as "a 2-column grid all the way down" once the eye locks onto the attitude row, and (b) it shrinks covers into a constrained cell. Switched to single-column full-width tiles.
- *Hide Entertainment + Study tiles when the library is empty (Mascot only).* Originally chosen; rejected because the first-launch user gets no signal that the app structures books by attitude — they only see "your library is empty". Always rendering the attitude tiles, with their own empty-state CTAs, teaches the structure even before any books exist.
- *Mixed widths (some 2-up, some full).* Rejected for v1 — adds layout complexity for marginal benefit. The stat-cards row already provides a 2-up rhythm; everything else stays full-width for simplicity.

### `Book.attitude` model change

Add to `Book`:

```swift
enum BookAttitude: String, Codable, CaseIterable {
    case entertainment
    case study
}

@Attribute var attitude: BookAttitude
```

Stored as the enum's `rawValue` by SwiftData. Initializer adds a required `attitude: BookAttitude` parameter — there is no in-code default. The seeded sample data is updated to label its two in-progress books as `.entertainment` and `.study` (one each) so the new tiles have content out of the box in DEBUG.

**Lightweight migration for existing rows**: the proposal lists this as *BREAKING*, but in practice no user has shipped data yet (no test target, no TestFlight). For developer machines that already have on-device SwiftData rows, SwiftData's automatic lightweight migration will add the new column and we provide a **schema-default of `.entertainment`** via the `@Attribute(originalName:)` / default-value pattern (a `@Attribute` with an initializer-supplied default works for lightweight migration when paired with a non-optional enum-with-rawValue). Old rows therefore appear in the Entertainment tile, which is the safer of the two buckets to show by default since "study" implies intent the user did not actually express.

**Alternatives considered**

- *Make `attitude` optional.* Rejected — every queue tile in this design assumes attitude is set. Optional propagates "unknown attitude" everywhere.
- *Use `String` directly instead of an enum.* Rejected — the values are closed and small; enum gives compile-time safety in switches and predicates.
- *Source attitude from a backend signal (genre, category, etc.).* Rejected — the user told us this is about their **attitude**, not the book's metadata. The same book can be entertainment for one user and study for another.

### Attitude capture during add-book

`BookSearchView.insert(_:)` currently builds a `Book` and inserts immediately. We replace that with a two-step flow:

1. Tap a search result → present a sheet (`BookAttitudePicker`) with the question **"Why are you adding this book?"** and two large selectable option cards: *"For fun"* (subtitle: "Just to enjoy reading") and *"To study"* (subtitle: "Learning or growth"). A primary "Add to library" button is disabled until one option is selected.
2. On confirm, insert the `Book` with `attitude:` set to the chosen value, dismiss the picker, dismiss the search sheet.

Copy is intentionally framed in **first-person, attitude-language**, not "What genre is this?" — that matches the product brief.

The picker reuses `OnboardingSelectableCard` styling so it feels native to the existing in-app card vocabulary.

**Alternatives considered**

- *Default to `entertainment` and let the user change later.* Rejected for v1 — there is no "edit book" surface yet, so a wrong default sticks. Asking once at add-time is a one-tap cost for an unambiguous answer.
- *Picker inline above the "Add" button in `BookSearchResultRow`.* Rejected — would clutter the result list and force the user to scroll back to confirm.

### Live counter — own tile, 10s tick, ~200 anchor

Add a second provider conforming to `LiveCounterProvider`, call it `CommunityActivityCounter`. It produces an integer that:

- Stays inside `[180, 220]` for the "around 200 all the time" target.
- Updates every 10 seconds (driven by `TimelineView(.periodic(from: .now, by: 10))`).
- Drifts up and down via a low-frequency sine + a small bounded random delta. Concretely: `value = 200 + round(15 * sin(t / 30)) + bounded_jitter(±3)` where `t = Date.timeIntervalSince1970` and the jitter is clamped so successive frames never differ by more than 5 (`bounded_jitter` carries state via `lastValue` on the provider, identical to the clamp pattern already in `DeterministicLiveCounter`).
- Persists a per-device random phase in `UserDefaults` under a new key `CrawCommunityCounterSeed` so two users on the same wall-clock minute don't see identical numbers and the value is stable across relaunches.

The existing `DeterministicLiveCounter` (1000–9000 daily curve) **stays in the codebase** in case product wants the old behavior elsewhere, but is no longer wired into Home.

**Display**: tile title `People reading now`, big number formatted with `.formatted()`, and a small caption underneath. We do not need to label "live" — the number changing every 10s communicates that.

**Alternatives considered**

- *Reuse `DeterministicLiveCounter` with new constants (`base = 200`, `amplitude = ~20`).* Rejected — the daily peak-hour curve makes no sense for "always ~200". Cleaner to introduce a new provider with its own model.
- *Faster tick (1s) for "more alive" feel.* Rejected — the user explicitly said every 10 seconds.

### Greeting cleanup

`GreetingSection` currently embeds `LiveCounterLabel`. We remove that embedding so the live counter is only present once on screen — as its own tile. `GreetingSection`'s body becomes just `GreetingHeader`. `LiveCounterLabel` itself stays as a type (it is still useful for previews) but is unused on Home. Likewise `LiveCounterProvider` and `DeterministicLiveCounter` stay; only the embedding is removed.

### Quote of the day

A pure SwiftUI tile with no model layer. Hardcoded constants:

```swift
private enum QuoteOfTheDay {
    static let text = "In the end, it’s not the years in your life that count. It’s the life in your years."
    static let attribution = "— Abraham Lincoln"
    static let subtitle = "Remember, you can find quote closer too you in your next book!"
}
```

Composition: quote text in `displaySm` italic on `surfaceCard`, attribution `captionSm muted` right-aligned beneath, then a separator (`hairlineSoft` 1pt), then the engagement subtitle in `bodySm muted`. No tap target. Future iteration can lift these into a `QuoteCatalog` or backend call without changing the tile's interface.

Typo "closer too you" is preserved verbatim from the user-supplied copy. (Flagged in Risks below in case product wants it corrected.)

### Mascot empty state

A full-width tile that uses the existing `Image("mascot")` asset (`Assets.xcassets/mascot.imageset`). Composition: mascot image centered, then headline `Your library is empty`, then body copy *"Add your first book to start building a streak."*, then the existing `Rausch` primary button labeled *"Add a book"* that opens `BookSearchView` — identical action to the per-attitude tile empty states.

**Conditional rendering**: the existing two-bucket logic in `HomeDashboardView.bookSections` (empty-library top-level vs. per-section empty) collapses into a single `if library.isEmpty { MascotEmptyTile } else { /* attitude tiles */ }` check. "Library is empty" means **no books at all**, including finished. We do **not** render the Mascot if the library only has finished books — that case shows the attitude-tile empty states instead (since the user has shown they know how to add).

### File layout

```
Craw/Home/
├── HomeDashboardView.swift                 (modified — compose tiles)
├── LiveCounter/
│   ├── LiveCounterProvider.swift           (unchanged — protocol + DeterministicLiveCounter stays)
│   └── CommunityActivityCounter.swift      (new)
├── Sections/
│   ├── GreetingSection.swift               (modified — remove counter embed)
│   ├── StatCardsSection.swift              (unchanged)
│   ├── WeekStripSection.swift              (unchanged)
│   ├── CurrentWeekMiniStrip.swift          (unchanged)
│   ├── EmptyStateViews.swift               (kept — used inside attitude tiles)
│   └── BookListSection.swift               (unchanged — still used inside attitude tiles for the single-row treatment)
└── Tiles/
    ├── TileCard.swift                      (new — shared card chrome modifier, private to Home module)
    ├── EntertainmentBookTile.swift         (new)
    ├── StudyBookTile.swift                 (new)
    ├── LiveCounterTile.swift               (new)
    ├── QuoteOfTheDayTile.swift             (new)
    └── MascotEmptyTile.swift               (new)
```

`Craw/Books/Search/`:
- `BookAttitudePicker.swift` (new) — the post-selection sheet.
- `BookSearchView.swift` (modified) — present picker between selection and insert.

### Queries

Add two predicates to `BookLibraryReader`:

```swift
static var inProgressEntertainmentPredicate: Predicate<Book> {
    #Predicate { $0.currentPage < $0.totalPages && $0.attitude == .entertainment }
}

static var inProgressStudyPredicate: Predicate<Book> {
    #Predicate { $0.currentPage < $0.totalPages && $0.attitude == .study }
}
```

Each attitude tile fetches with its own `@Query` and takes the first result. **Tile selection rule**: most-recently-added in-progress book of that attitude (the existing `defaultSort` ordering already handles this — `dateAdded` descending).

The "library is empty" decision needs *all* books, not just the in-progress ones. We add one more `@Query` at the `HomeDashboardView` level that returns the total count (or just a non-empty boolean) — keep using the existing two-predicate queries for the conditional, but compute `isLibraryEmpty = inProgressBooks.isEmpty && finishedBooks.isEmpty` exactly as today.

### Accessibility

- Each tile is a `VStack` and gets one combined `accessibilityElement(children: .combine)` with a manually-set `accessibilityLabel` (e.g., "Entertainment book — Project Hail Mary by Andy Weir, 12% read"). Empty-state tiles get a single combined label plus a button label on the CTA.
- The Live counter tile sets `accessibilityValue` from the current number and `accessibilityAddTraits(.updatesFrequently)` so VoiceOver doesn't re-announce every 10s by default.

## Risks / Trade-offs

- **[Risk] Lightweight migration default for `attitude`.** Existing on-device rows from developer simulators end up labelled `entertainment` even if the developer meant them as study. → **Mitigation**: documented in the change; in practice the only data is from `SampleData.seed` (DEBUG only) and ad-hoc rows from `BookSearchView`. Wipe-the-sim is the dev workaround.
- **[Risk] Both attitude tiles in their empty state at once feels redundant ("Add a book" appears twice).** → **Mitigation**: each tile gets a slightly different headline ("Pick something for fun" / "Pick something to study") and the same single CTA. We accept the duplication on the "library has finished books only" edge case rather than collapsing to one tile, because product wants the attitude split visible.
- **[Risk] Locale & date arithmetic for live counter drift.** None — the new provider does not touch `Calendar`; it's purely `timeIntervalSince1970`. No risk.
- **[Risk] Performance of `TimelineView` ticking every 10s on the Home tab when offscreen.** → **Mitigation**: `TimelineView` automatically pauses when the view is not on screen (SwiftUI behavior). No extra wiring required.
- **[Risk] The hardcoded quote contains a grammar slip ("closer too you").** → **Mitigation**: preserved verbatim per the user-supplied copy; flagged here so product can change in a one-line follow-up. No spec ties to the typo.
- **[Trade-off] Removing the Finished section from Home reduces visibility of completion**. → Accepted. Book Detail and Library views still surface finished books; Home becomes about *active* attitudes + a moment of inspiration.
- **[Trade-off] No "edit attitude" affordance.** → Accepted for v1; we will add it the first time a user asks. Until then, the attitude is "the user's snap intent at add time".

## Migration Plan

1. Land `Book.attitude` and the `BookAttitude` enum behind the SwiftData lightweight migration. Verify on a simulator that has pre-existing rows that everything still opens.
2. Land the attitude picker in `BookSearchView` — gate the existing insertion behind it. All new books from this point on are tagged.
3. Land tile views and the new live counter provider in parallel — neither depends on the model change to compile, only to render meaningful content.
4. Land the `HomeDashboardView` recomposition. Drop the existing `GreetingSection`-embedded counter at the same commit so the user never sees the counter rendered twice.
5. Update `SampleData.seed` to set explicit attitudes (`Project Hail Mary` → entertainment, `Lord of the Rings` → entertainment, `Pragmatic Programmer` → study).
6. Manual QA via `-CrawSeedSampleData YES` (full home) and an unflagged launch (mascot empty state).

Rollback: revert the `HomeDashboardView` and `BookSearchView` commits. The `attitude` field can stay on the model with no consumers and will be a no-op for users.

## Open Questions

- Should the mascot tile retain the *Live counter* + *Quote of the day* tiles beneath it (current design) or completely take over the area? — **Defaulted to: keep counter and quote visible even in empty state**, on the theory that they're "moments" the user can enjoy regardless of library state. Flag if product wants otherwise.
- Do we want a tiny "Why?" affordance on the attitude tiles explaining what "entertainment vs. study" means? Skipped for v1; revisit if first-week analytics show confusion.
- Should we cap the live counter to whole numbers above 0 with no leading zeros? Yes — `.formatted()` already does this. No design choice needed.
