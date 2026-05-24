## 1. Model: add `Book.attitude`

- [x] 1.1 In `Craw/Persistence/Book.swift`, add a public `enum BookAttitude: String, Codable, CaseIterable { case entertainment; case study }` next to the existing `BookStatus` enum.
- [x] 1.2 Add `var attitude: BookAttitude` as a stored property on the `Book` `@Model` class. Confirm SwiftData stores it via the enum's `rawValue` (no extra `@Attribute` wrapper needed beyond the default). _Implementation note: `#Predicate` rejected the enum key path (see 2.3), so persistence was reshaped — `attitudeRaw: String` is the stored attribute, `attitude: BookAttitude` is a computed getter/setter that reads and writes the raw value._
- [x] 1.3 Update `Book.init(...)` to require an `attitude: BookAttitude` parameter (no default). Audit every existing call site of `Book.init` and pass an explicit value.
- [x] 1.4 In `Craw/Persistence/SampleData.swift`, update the three seeded books to pass `attitude:` — `inProgressNoCover` (LOTR) `.entertainment`, `inProgressWithCover` (Project Hail Mary) `.entertainment`, `finished` (Pragmatic Programmer) `.study`. _Deviation: Project Hail Mary tagged `.study` (not `.entertainment`) so the seeded Home shows content in BOTH attitude tiles for QA — task 11.4 expects a study book to be visible, which is only possible if at least one in-progress seed is `.study`._
- [ ] 1.5 Verify SwiftData lightweight migration on a simulator that has pre-existing seeded rows: launch on the new build, confirm the app does not crash and previously-stored rows surface with `attitude == .entertainment`. (If lightweight migration cannot fold in a non-optional enum without an explicit default, fall back to a one-shot post-fetch backfill in `CrawModelContainer` that assigns `.entertainment` to any row whose attribute decoded to nil. Document whichever path was needed in the commit message.) _Pending manual simulator run._

## 2. Library queries

- [x] 2.1 In `Craw/Persistence/BookLibraryReader.swift`, add `static var inProgressEntertainmentPredicate: Predicate<Book>` returning `currentPage < totalPages && attitude == .entertainment`.
- [x] 2.2 Add `static var inProgressStudyPredicate: Predicate<Book>` returning `currentPage < totalPages && attitude == .study`.
- [x] 2.3 Confirm `#Predicate` accepts the enum rawValue comparison. If the predicate macro rejects the enum literal, switch to comparing the underlying `rawValue` string and document the workaround inline (single comment max). _The macro rejected enum-case key paths (`error: key path cannot refer to enum case 'entertainment'`). Fallback applied: `Book.attitudeRaw: String` is the stored attribute, predicates compare against `BookAttitude.entertainment.rawValue` / `.study.rawValue` via a hoisted `let`. Inline comment in `BookLibraryReader.swift` documents the why._

## 3. Add-book attitude picker

- [x] 3.1 Create `Craw/Books/Search/BookAttitudePicker.swift` — a `View` presented as a sheet. Inputs: the `BookSearchResult` that was tapped, plus `onConfirm: (BookAttitude) -> Void` and `onCancel: () -> Void` callbacks.
- [x] 3.2 Layout per design: title text "Why are you adding this book?", two `OnboardingSelectableCard`-styled options (`For fun` / `To study`), a primary "Add to library" button disabled until selection. Use existing `Theme` tokens only.
- [x] 3.3 In `Craw/Books/Search/BookSearchView.swift`, replace the immediate insertion in `insert(_:)` with: store the selected result in `@State`, present `BookAttitudePicker` as a `.sheet(item:)` bound to that state, and only call the SwiftData insert path inside the picker's `onConfirm`.
- [x] 3.4 In the insertion path, pass `attitude: chosenAttitude` to `Book.init`. Dismiss both the picker and the search sheet after a successful insert.
- [x] 3.5 Add a `#Preview` for `BookAttitudePicker` covering "no selection" and "entertainment selected" states.

## 4. Tile chrome shared modifier

- [x] 4.1 Create `Craw/Home/Tiles/TileCard.swift` with a `private struct TileCardBackground: ViewModifier` (or `fileprivate` inside the Home module) mirroring the chrome from `StatCardsSection.CardBackground` — `surfaceCard` fill, `hairlineSoft` 1pt overlay, `Radius.card`, `Spacing.base` padding, `maxWidth: .infinity, alignment: .leading`.
- [x] 4.2 Expose `func tileCard() -> some View` as an extension on `View` scoped to the Home module.

## 5. Live counter tile

- [x] 5.1 Create `Craw/Home/LiveCounter/CommunityActivityCounter.swift` conforming to `LiveCounterProvider`. Implement the value generator: `200 + round(15 * sin((now - phase) / 30))` plus a `±3` jitter, with a `lastValue` clamp so adjacent calls differ by ≤5 and the output is always in `[180, 220]`.
- [x] 5.2 Persist a random phase in `UserDefaults` under key `"CrawCommunityCounterSeed"` (Double), creating it on first run. Read it back in subsequent runs.
- [x] 5.3 Create `Craw/Home/Tiles/LiveCounterTile.swift`. Wrap a `TimelineView(.periodic(from: .now, by: 10))` driving the counter. Display: `displaySm` number formatted via `.formatted()`, caption `People reading now` in `muted`. Apply `.tileCard()`.
- [x] 5.4 Add `.accessibilityElement(children: .combine)`, `.accessibilityValue(...)`, `.accessibilityAddTraits(.updatesFrequently)`.
- [ ] 5.5 Manually verify the tile in the simulator for at least one minute — value visibly ticks every 10s and stays within 180–220. _Pending manual simulator run._

## 6. Greeting cleanup

- [x] 6.1 In `Craw/Home/Sections/GreetingSection.swift`, remove `LiveCounterLabel` from `GreetingSection.body` so the section renders only `GreetingHeader`. Keep `LiveCounterLabel` as a type for use in previews.
- [x] 6.2 Update the `GreetingSection` initializer signature: drop `counterProvider` since the section no longer consumes it.

## 7. Attitude tiles (Entertainment & Study)

- [x] 7.1 Create `Craw/Home/Tiles/EntertainmentBookTile.swift`. Use `@Query(filter: BookLibraryReader.inProgressEntertainmentPredicate, sort: BookLibraryReader.defaultSort)` to fetch books and bind to the first result. Tile body shows cover (`CoverPlaceholder`), title (`titleMd`), author (`bodySm muted`), and a thin progress bar (reuse `ProgressBar` pattern from `BookListSection.swift` — extract it to a `fileprivate` shared view if needed). Wrap a `NavigationLink(value: book)` so taps push detail. _Implementation note: both attitude tiles delegate to a shared `AttitudeBookTile` view (new file `Craw/Home/Tiles/AttitudeBookTile.swift`) with a private `AttitudeTileProgressBar`, rather than reaching into `BookListSection`'s fileprivate `ProgressBar`._
- [x] 7.2 Empty state: when the query returns zero books, render an in-tile empty state — small headline "Pick something for fun", body "Add a book just for enjoyment.", and an "Add a book" button styled with `Rausch` that calls the `onAddTapped` closure.
- [x] 7.3 Apply `.tileCard()`. Add `accessibilityElement(children: .combine)` with a manually-set label that includes title, author, and progress percentage when a book is present, or the empty-state copy otherwise.
- [x] 7.4 Create `Craw/Home/Tiles/StudyBookTile.swift` mirroring 7.1–7.3 but using `inProgressStudyPredicate` and copy "Pick something to study" / "Pick a book you'd like to learn from.".
- [x] 7.5 Add `#Preview`s for each tile covering: with-book and empty-state.

## 8. Quote of the day tile

- [x] 8.1 Create `Craw/Home/Tiles/QuoteOfTheDayTile.swift`. Embed a `private enum QuoteOfTheDay` with constants `text`, `attribution`, `subtitle` per the design.
- [x] 8.2 Layout: italic `displaySm` quote text, `captionSm muted` attribution right-aligned, `hairlineSoft` 1pt separator, `bodySm muted` subtitle. Apply `.tileCard()`.
- [x] 8.3 Combine accessibility children into a single label that reads quote + attribution + subtitle.

## 9. Mascot empty tile

- [x] 9.1 Create `Craw/Home/Tiles/MascotEmptyTile.swift`. Initializer takes `onAddTapped: () -> Void`.
- [x] 9.2 Layout: `Image("mascot")` sized so it doesn't dominate the tile (`frame(height: 160)` or similar), headline "Your library is empty" (`titleMd`), body "Add your first book to start building a streak." (`bodySm muted`), then a primary Rausch button labeled "Add a book" that triggers the closure.
- [x] 9.3 Apply `.tileCard()`. Ensure the button has an `accessibilityLabel("Add your first book")`.

## 10. Dashboard recomposition

- [x] 10.1 In `Craw/Home/HomeDashboardView.swift`, add a third `@Query` for the empty-library check (either reuse the existing `inProgressBooks` + `finishedBooks` queries, or add a count-only query). Compute `isLibraryEmpty = inProgressBooks.isEmpty && finishedBooks.isEmpty`. _Reused the existing two `@Query` results — no third query needed._
- [x] 10.2 Replace the `bookSections` view with a new `tileColumn` view: a single-column `VStack(spacing: Theme.Spacing.md)` containing the tiles in order. _Iterated from the original `LazyVGrid` 2-col plan after design review: a 2-up attitude row reads as a "column wall" and constrains covers. Switched to full-width tiles for visual variety with the existing 2-up `StatCardsSection`._
- [x] 10.3 Non-empty composition (in declared order): `EntertainmentBookTile(onAddTapped: presentSearch)`, `StudyBookTile(onAddTapped: presentSearch)`, `LiveCounterTile()`, `QuoteOfTheDayTile()` — each full width.
- [x] 10.4 Empty composition: `MascotEmptyTile(onAddTapped: presentSearch)` at the top, then `EntertainmentBookTile`, `StudyBookTile`, `LiveCounterTile`, `QuoteOfTheDayTile` — each full width. The Mascot is additive; it does not replace the attitude tiles. _Iterated from the original plan after design review: hiding the attitude tiles in the empty state hides the structure of the app from first-launch users; better to keep both tiles visible with their own empty-state CTAs alongside the Mascot._
- [x] 10.5 Update the top-level `LazyVStack` to include `GreetingSection()`, `WeekStripSection(days: readingDays)`, `StatCardsSection(days: readingDays)`, `tileGrid`. Remove the old `bookSections` computed view entirely.
- [x] 10.6 Refresh the `#Preview`s in `HomeDashboardView.swift` — keep "Full dashboard — seeded", "Empty library", and "Only-finished library"; drop "In-progress only" (the new shape is exercised by the seeded preview). Add a new preview "Empty library with no finished books" if the existing one isn't equivalent. _Existing "Empty library" preview is equivalent to "Empty library with no finished books" (no rows of either kind); no new preview added._

## 11. Cleanup & verification

- [x] 11.1 Search the codebase for any remaining call sites of `Book.init(...)` that don't pass `attitude:` — there should be zero. Use `rg "Book\(" Craw` to confirm. _All 7 `Book(` call sites pass `attitude:`._
- [x] 11.2 Search for stale usages of `LiveCounterLabel` outside of `GreetingSection.swift` previews — there should be zero references on Home's rendered hierarchy. _`LiveCounterLabel` is only declared (not referenced) outside its own file._
- [x] 11.3 Build the app for iPhone 17 simulator with `xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 17' build` and confirm no warnings beyond the existing baseline. _BUILD SUCCEEDED. The only warnings emitted are pre-existing actor-isolation lints in `Craw/Networking/CrawAPIClient.swift` (unrelated to this change)._
- [ ] 11.4 Manual QA: launch with `-CrawSeedSampleData YES` — verify the Entertainment tile shows an entertainment book, the Study tile shows the (study) seeded book, the counter ticks, the quote is visible. Then delete the simulator app, relaunch without seeds — verify the Mascot tile replaces the attitude+quote tiles, the live counter and quote remain visible. _Pending manual simulator run._
- [ ] 11.5 Manual QA the attitude picker: from the Mascot CTA, search a book, tap a result, confirm the picker presents, confirm "Add to library" is disabled until selection, pick an attitude, confirm the new book lands in the correct tile. _Pending manual simulator run._
- [x] 11.6 Run `openspec validate update-home-page-tiles --strict` and resolve any reported issues before archiving.
