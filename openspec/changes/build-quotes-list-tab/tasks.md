## 1. Scaffolding

- [ ] 1.1 Create the new feature folder `Craw/Quotes/` (no `project.pbxproj` edits — folder is covered by `PBXFileSystemSynchronizedRootGroup`)
- [ ] 1.2 Confirm `mascot` asset is present in `Assets.xcassets` and used by `MascotEmptyTile` so the same name is reusable

## 2. Mascot header

- [ ] 2.1 Add `Craw/Quotes/QuotesMascotHeader.swift` with a compact card containing the `mascot` image (≤ 80pt tall) and a single line of static copy "Keep it up!" using `Theme.Typography.titleSm` / `Theme.Palette.ink`
- [ ] 2.2 Style the card with `tileCard()` and `Theme.Spacing.md` internal spacing; mark the mascot image `accessibilityHidden(true)` and add an `accessibilityLabel` to the card summarizing the encouragement
- [ ] 2.3 Add a `#Preview` rendering the header with `.padding()`

## 3. Quote row

- [ ] 3.1 Add `Craw/Quotes/QuoteRow.swift` taking a `Quote` and a resolved `Book?` as inputs
- [ ] 3.2 Render the quote text in `Theme.Typography.bodyMd` ink; render the book title + " — " + author subtitle in `Theme.Typography.captionSm` muted; render captured-at date as `Date.FormatStyle` `.dateTime.day().month(.abbreviated).year()` aligned trailing in the metadata row
- [ ] 3.3 Render a trailing "page chip" using `Theme.Typography.captionSm` and `Theme.Palette.muted` when `Quote.pageNumber != nil`; render no chip when `nil`
- [ ] 3.4 When the resolved `Book` is `nil`, render the subtitle as "Unknown book"
- [ ] 3.5 Apply `.accessibilityElement(children: .combine)` and an `accessibilityLabel` composing quote text, book subtitle, page (when present), and date
- [ ] 3.6 Add a `#Preview` covering: (a) row with page, (b) row without page, (c) row with unknown book

## 4. Empty state

- [ ] 4.1 Add `Craw/Quotes/QuotesEmptyState.swift` reusing the `MascotEmptyTile` composition pattern (mascot image at ~160pt tall, title + body copy centered, no button)
- [ ] 4.2 Title copy: "No quotes yet". Body copy: "Capture a quote during your next reading session and it will land here."
- [ ] 4.3 Wrap the content with `tileCard()`-equivalent padding and place inside a `VStack` that fills available height so the mascot sits roughly centered on the canvas
- [ ] 4.4 Add a `#Preview`

## 5. Quotes list

- [ ] 5.1 Add `Craw/Quotes/QuotesListView.swift` exposing `@Query private var quotes: [Quote]` sorted by `QuotesThoughtsReader.quoteSortNewestFirst` (no predicate — fetch every quote)
- [ ] 5.2 Add a sibling `@Query private var books: [Book]` (no predicate); compute a `private var bookByID: [UUID: Book]` from `books` keyed by `Book.id`
- [ ] 5.3 If `quotes.isEmpty`, render `QuotesEmptyState` centered on the canvas
- [ ] 5.4 Otherwise render a `ScrollView` containing a `LazyVStack(spacing: Theme.Spacing.md)`: first child is `QuotesMascotHeader`, followed by a `ForEach(quotes)` that renders `QuoteRow(quote:, book: bookByID[quote.bookID])`
- [ ] 5.5 Wrap rows in `tileCard()` styling consistent with `BookDetailView`'s quote rows; ensure horizontal padding and the `Theme.Palette.canvas` background match the rest of the app shell
- [ ] 5.6 Ensure rows have NO `onTapGesture`, NO `NavigationLink`, and NO swipe actions — list is fully read-only
- [ ] 5.7 Apply a navigation title of "Quotes" using `.navigationTitle("Quotes")` and `.navigationBarTitleDisplayMode(.large)` (or `.inline` if that matches sibling tabs after visual review)

## 6. Wire into the app shell

- [ ] 6.1 Edit `Craw/AppShell/QuotesTab.swift` to replace `PlaceholderTabView(title: "Quotes", message: ...)` with `QuotesListView()` inside the existing `NavigationStack`
- [ ] 6.2 Verify `QuotesTab` is still referenced from `Craw/AppShell/RootView.swift` and that the tab icon/label are unchanged

## 7. Verification

- [ ] 7.1 Run a simulator build for an iPhone 17 destination via `xcodebuild` and confirm it builds clean
- [ ] 7.2 Launch the app with `-CrawSeedSampleData YES` and confirm the Quotes tab shows a non-empty list with the mascot header at the top, rows in newest-first order, page chips where present, and book title/author subtitles
- [ ] 7.3 Launch the app without `-CrawSeedSampleData` (after deleting the simulator app) and confirm the Quotes tab shows the mascot-led empty state with no list
- [ ] 7.4 Tap several rows and confirm no navigation, sheet, or alert is presented
- [ ] 7.5 Verify VoiceOver reads each row as a single combined element (quote text + book + page + date)
- [ ] 7.6 Confirm `swiftformat` / `swiftlint` PostToolUse hooks ran clean on all touched files (no manual invocation needed — hooks fire on Write/Edit)

## 8. Spec validation

- [ ] 8.1 Run `openspec validate build-quotes-list-tab` and resolve any reported issues
- [ ] 8.2 Update this file's checkboxes as tasks complete during `/opsx:apply`
