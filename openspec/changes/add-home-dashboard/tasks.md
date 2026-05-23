## 1. Foundation

- [x] 1.1 Add a `Theme` enum under `Craw/DesignSystem/` exposing the slice of `DESIGN.md` tokens this change consumes: `Theme.Color` (rausch, ink, body, muted, mutedSoft, hairline, hairlineSoft, surfaceSoft, surfaceCard, canvas), `Theme.Radius` (button = 8, card = 14, pill), `Theme.Spacing` (unit = 8), `Theme.Shadow` (single elevation tier), `Theme.Font` (Cereal with Inter fallback, weights and sizes used here). *(Implemented as `Theme.Palette`, `Theme.Radius`, `Theme.Spacing`, `Theme.Elevation`, `Theme.Typography`. Used `Palette` instead of `Color` to avoid namespacing collision with `SwiftUI.Color`.)*
- [x] 1.2 Add a SwiftUI `Color`-from-hex initializer used by `Theme.Color`.
- [x] 1.3 Confirm `swiftformat` and `swiftlint` pass on the new `DesignSystem` files (the `.claude/settings.json` PostToolUse hook will run them automatically on Write/Edit).

## 2. Persistence layer

- [x] 2.1 Add a `Persistence/` folder under `Craw/`.
- [x] 2.2 Define the SwiftData `Book` `@Model` with fields: `id` (UUID), `title` (String), `author` (String), `coverAssetName` (String?), `totalPages` (Int), `currentPage` (Int), `dateAdded` (Date).
- [x] 2.3 Add a derived computed `status: BookStatus` on `Book` returning `.inProgress` / `.finished` per the `book-library` spec (note: `.notStarted` is treated as in-progress for listing — encode that in the dashboard query, not on the model). *(Status returns `.notStarted` / `.inProgress` / `.finished`; the in-progress query in `BookLibraryReader` will include both `.notStarted` and `.inProgress` per spec.)*
- [x] 2.4 Define the SwiftData `ReadingDay` `@Model` with fields: `id` (UUID), `date` (Date, normalized to start-of-day in `Calendar.autoupdatingCurrent`), `minutesRead` (Int), `pagesRead` (Int). Enforce uniqueness on `date` via a fetch-then-update helper.
- [x] 2.5 Add a `ModelContainer` factory in `Persistence/CrawModelContainer.swift` returning a live container and an in-memory variant for previews and tests.

## 3. Read-only queries and derivations

- [x] 3.1 Add `BookLibraryReader` exposing `inProgress()` and `finished()` predicates suitable for SwiftUI `@Query`, where `inProgress()` includes books with `currentPage == 0`. *(Exposed as `inProgressPredicate` / `finishedPredicate` static `Predicate<Book>`s; the `currentPage < totalPages` form correctly includes both `.notStarted` and `.inProgress` books.)*
- [x] 3.2 Add `ReadingActivityReader` with `today()`, `lastSevenDays()`, `pagesDeltaVsYesterday()`, `currentStreak()`, `currentCalendarWeek()` — all pure functions over fetched `ReadingDay` rows. Encode the streak rules from the spec (anchor on yesterday when today is empty; break on any zero-minute gap in the streak window). `currentCalendarWeek()` returns an ordered seven-entry sequence aligned to `Calendar.autoupdatingCurrent.firstWeekday`, each entry tagged with weekday, hasActivity flag, isToday flag — distinct from `lastSevenDays()` which is rolling.
- [x] 3.3 Write deterministic unit tests for `pagesDeltaVsYesterday()`, `currentStreak()`, and `currentCalendarWeek()` using in-memory `ReadingDay` fixtures covering: positive change, negative change, yesterday=0, no activity at all, today-not-yet-logged-with-prior-streak, mid-window gap, week-with-only-Monday-activity, today-is-first-weekday-with-no-activity-yet. *(11 Swift Testing cases written into `CrawTests/ReadingActivityReaderTests.swift`. **Outstanding: the Xcode project has no test target yet; the user needs to add one via Xcode → File → New → Target → Unit Testing Bundle, name `CrawTests`, and add the existing `CrawTests/` folder to it. Tests will then run with `xcodebuild test`.** The file lives outside `Craw/` so it does not enter the app target.)*

## 4. Sample data (debug-only)

- [x] 4.1 Add `SampleData.swift` guarded by `#if DEBUG` with `seed(into:)` that inserts two in-progress books (one with cover asset, one without), one finished book, and 7 days of `ReadingDay` rows producing a visible 4-day streak and a positive pages-delta today. *(`seedIfEmpty(into:)` is idempotent — skips when any `Book` or `ReadingDay` row already exists.)*
- [x] 4.2 Wire the seeder behind launch argument `-CrawSeedSampleData YES`. Document the argument in CLAUDE.md.

## 5. App shell — navigation

- [x] 5.1 Replace `ContentView` usage in `CrawApp` with a new `RootView` containing the four-tab `TabView`.
- [x] 5.2 Build `HomeTab`, `QuotesTab`, `StatsTab`, `ProfileTab`. Three latter tabs render a shared `PlaceholderTabView(title:)` per the `app-shell` spec.
- [x] 5.3 Wrap each tab's root in `NavigationStack` so navigation state is tab-local.
- [x] 5.4 Apply `.tint(Theme.Color.rausch)` at the `TabView` so selected-state inherits the brand accent. Verify in light mode on iPhone 17 sim. *(Tint applied via `Theme.Palette.rausch`. Visual verification on simulator deferred to §9.)*
- [x] 5.5 Delete the legacy `ContentView.swift` once `RootView` is in place.

## 6. Home dashboard — composition

- [x] 6.1 Build `HomeDashboardView` as the root of `HomeTab`. Use a `ScrollView` + `LazyVStack` with section spacing from `Theme.Spacing`.
- [x] 6.2 Build `GreetingHeader` — derives part-of-day from `Calendar.autoupdatingCurrent` per the spec boundaries (04:00, 12:00, 18:00) and renders "Good {part}, {Weekday}". *(Implemented inside `GreetingSection.swift`.)*
- [x] 6.3 Build `LiveCounterLabel` driven by a `LiveCounterProvider` protocol with a concrete `DeterministicLiveCounter` implementation: smooth sinusoidal day-curve seeded with a stable per-device offset, bounded delta ≤ 5% per update, ticks on a `Timer.publish` cadence of 8 seconds. *(View ticks via `TimelineView(.periodic(from: .now, by: 8))`; provider clamps each update to ≤5% of the prior value.)*
- [x] 6.4 Build `WeekStrip` rendering seven `DayCell`s oldest-to-today. `DayCell` composes a `Circle().trim(...).stroke(...)` ring overlaid on a faded outline, weekday letter beneath. Today's cell uses a bold weekday label and an accent-colored ring track. *(Implemented as `WeekStripSection` + nested `DayCell`.)*
- [x] 6.5 Build `StatCardsRow` with two `StatCard`s side-by-side: today's pages with delta + trend arrow (per `home-dashboard` spec rules), and the streak card. The streak card has two visual regimes per spec: below 7 days renders a single "X days" metric; at 7+ days renders a current-calendar-week mini-strip (seven small day markers, today highlighted, days-with-activity filled) plus an adjacent "X day streak" total counter. Switch is purely a function of the current streak length. *(Implemented as `StatCardsSection` with `TodaysPagesCard` and `StreakCard`.)*
- [x] 6.6 Build `CurrentWeekMiniStrip` consumed by the streak card's 7+ regime: renders the seven entries from `currentCalendarWeek()` as small markers in calendar-week order (not rolling), today visually distinguished. Distinct component from the dashboard's primary 7-day rolling strip.
- [x] 6.7 Build `BookListSection(title:books:)` rendering header + rows. Header for "Reading Now" includes a trailing `+` button wired to a no-op `onAddBookTapped` closure for now.
- [x] 6.8 Build `BookRow` showing cover (or `CoverPlaceholder`), title, author, and a thin progress bar (only for in-progress books — finished books omit the bar).
- [x] 6.9 Wire row taps to push a `BookDetailPlaceholder(book:)` showing only the title onto the Home navigation stack. *(Wired via `NavigationLink(value: book)` + `.navigationDestination(for: Book.self)` on `HomeDashboardView`.)*

## 7. Empty states

- [x] 7.1 Build `LibraryEmptyState` — replaces both Reading Now and Finished when the library is fully empty. Includes the add-book affordance.
- [x] 7.2 Build `ReadingNowEmptyState` — shown inside the Reading Now section when finished books exist but in-progress is empty. Includes the add-book affordance.
- [x] 7.3 Verify the Finished section is hidden (not rendered) when there are zero finished books. *(`HomeDashboardView.bookSections` only renders Finished when `!finishedBooks.isEmpty`.)*

## 8. Previews

- [x] 8.1 Add `#Preview` configurations for: full dashboard with seeded data, fully-empty library, only-finished library, single-in-progress-no-finished. Use a preview-only in-memory `ModelContainer` from the persistence factory.
- [x] 8.2 Add `#Preview` for `WeekStrip` with a sparse week (only 2 of 7 days have activity) to confirm zero-day rings render as outlines.
- [x] 8.3 Add `#Preview` for the streak card in both regimes: streak = 3 (single-metric treatment) and streak = 12 (current-week mini-strip + "12 day streak" counter).

## 9. Manual verification

- [x] 9.1 Build and run on iPhone 17 simulator with `-CrawSeedSampleData YES` and confirm: all six dashboard sections render, today's tile is highlighted, stat cards show correct delta and streak, both book sections list seeded books, tab bar tint is Rausch. *(Verified via simctl screenshot at `/tmp/craw_seeded.png`: greeting "Good evening, Sunday", live counter "6.245 people reading now", 7 rings with today's accent track, "30 pages +50%" / "4 days" stat cards, Reading Now lists "Project Hail Mary" + "The Lord of the Rings" with progress bars, Finished lists "The Pragmatic Programmer", `+` add affordance present, Rausch-tinted Home tab.)*
- [x] 9.2 Launch without the seed flag and confirm the library-empty state shows on Home. *(Verified via simctl screenshot at `/tmp/craw_empty.png`: LibraryEmptyState with book-stack icon, "Your library is empty" + subtitle + Rausch "Add a book" CTA, all seven 7-day rings empty, stat cards show "0 pages no change" / "0 days", tab bar visible with all four tabs. Placeholder tabs not exercised — simctl has no tap; PlaceholderTabView is a trivial wrapper sharing the same template, code-reviewed only.)*
- [x] 9.3 ~~Run on iPad simulator~~ — **skipped per user request**. iPad simulator build was verified to succeed (`xcodebuild` on iPad mini A17 Pro destination returned `BUILD SUCCEEDED`); UI layout on iPad not visually verified.
- [x] 9.4 Run `xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 17' build` and confirm the build succeeds with no warnings beyond SwiftLint's existing rule set. *(`BUILD SUCCEEDED`. SwiftLint reports 0 violations across all source files.)*
