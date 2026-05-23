## Context

Craw targets iOS/iPadOS 26.5, Swift 5.10, SwiftUI only — no UIKit interop required for any dashboard need. The codebase is a Hello-World scaffold; this change introduces the navigation shell and a real persistence layer for the first time. The product's defining loop ("Duolingo for reading") depends on a Home tab that feels alive on every launch: streaks, rings, in-flight books, with a clear add-book affordance.

Constraints worth pinning before deciding anything:
- `DESIGN.md` is locked: Rausch (`#ff385c`) is the only accent; type runs Cereal-with-Inter-fallback at modest weights; one shadow tier; pill-shaped search and 14px card radii.
- Universal target (iPhone + iPad, `TARGETED_DEVICE_FAMILY = "1,2"`).
- No backend in this change — everything is on-device.
- Other tabs (Quotes, Stats, Profile) are out of scope for content but in scope for *existence* — later changes need somewhere to plug in.

## Goals / Non-Goals

**Goals:**
- Establish the app's navigation IA so future changes can add destinations without restructuring.
- Render a complete Home dashboard from real persisted data, including empty states.
- Pick a persistence stack now and commit to it — the session-quiz change depends on it.
- Apply `DESIGN.md` tokens systematically (extract them into Swift types as a side effect).

**Non-Goals:**
- Book creation, editing, deletion (deferred to `add-book-management`).
- Logging a reading session (deferred to `add-session-quiz-verification`, which writes into `reading-activity`).
- Quotes browser, Stats tab content, Settings — these are placeholder tabs only.
- Onboarding, paywall, auth — explicitly excluded by the user.
- iPad split-view / sidebar layout — universal target, but iPad gets the same single-column dashboard at first. Adaptive layout is a follow-up.

## Decisions

### Persistence: SwiftData

Use SwiftData (`@Model` macro) for `Book` and `ReadingDay`. iOS 26.5 deployment makes SwiftData a default-safe choice; it is SwiftUI-native (`@Query`, `modelContainer`) and avoids the boilerplate of Core Data. The data shapes here are small and relational only at the edges, so SwiftData's gaps (complex predicates, migration tooling) won't bite.

**Alternatives considered:** Core Data (more mature but heavier, less SwiftUI-idiomatic), JSON files via `FileManager` (loses query capability, painful for stat aggregation), GRDB (extra dependency, no benefit at this scale).

### Navigation: `TabView` + per-tab `NavigationStack`

Root view is a `TabView` with four tabs. Each tab wraps its content in a `NavigationStack` so push transitions stay tab-local — a standard SwiftUI pattern. Selected tab tint is Rausch.

**Alternatives considered:** `NavigationSplitView` (right for iPad sidebars but premature; we don't yet know what lives in the sidebar). Custom tab bar (no reason to fight the system one — it already matches the warm-and-friendly DESIGN.md vibe).

### Live counter: deterministic pseudo-live, not random

The "people reading now" counter must feel alive but never jarring. A purely random number is a tell — users will reload and see it leap unnaturally. Instead, derive it from a smooth function of wall-clock time (sinusoidal day-curve peaking in the evening, baseline floor, slow drift) seeded with a stable per-device offset. Updates every 5–10 seconds with bounded delta so changes look organic.

**Honesty constraint:** the source of truth for this number is a function, not a server. If/when there's a real DAU signal, swap the implementation behind the same `LiveCounterProvider` protocol. No UI change.

### Stat-card delta and streak: derive on read, don't store

Today-vs-yesterday % change and the current weekly streak are pure functions over `ReadingDay` rows. Compute them in a view-model on demand rather than maintaining denormalized counters that can drift out of sync. SwiftData's `@Query` + an in-memory reducer is plenty fast for the 7–30 days we ever look at.

### Day bucketing: user's local calendar

Sessions log UTC timestamps; aggregations bucket by the user's *current* `Calendar.autoupdatingCurrent` day boundary. Crossing midnight while reading splits the session across two days for stat purposes. Documented now so the session-quiz change inherits the convention.

### Rings: hand-rolled `Circle().trim(...)`, not Charts

The 7-day strip needs tight control over color, stroke, and concentric layering to match `DESIGN.md`. A `Shape` + `.trim(from:to:)` + `.stroke` composition is ~30 lines and pixel-perfect; Swift Charts is overweight here and won't ride the design tokens cleanly.

### Streak stat card has two regimes

The streak card switches visual treatment at the 7-day mark: below 7 it shows a single "X days" metric; at 7+ it shows the current calendar week's activity strip plus an adjacent total-days counter. This is a *persistent* milestone treatment, not a one-time celebration — once a user has earned a sustained week, the card permanently surfaces both "this week" and the lifetime streak length so the milestone keeps paying off. Falling below 7 reverts the card to the simpler treatment without ceremony.

**Why distinct from the 7-day rolling strip above:** the rolling strip is calendar-day-rolling (always shows the last 7 days). The streak card's week visualization is calendar-week-aligned (Monday–Sunday or Sunday–Saturday per the user's `firstWeekday`). They convey different signals: "have you been reading recently" vs. "how is this *week* going."

### Design tokens: extract to a `Theme` enum on first use

`DESIGN.md` is a spec, not code. This change is the first consumer, so we materialize the slice we need: `Theme.Color.rausch`, `Theme.Spacing.unit`, `Theme.Radius.card`, `Theme.Shadow.one`, etc. Only extract what this change uses — no premature full port.

### Sample data: debug-only seeder

A `SampleData.seed(into:)` helper, guarded by `#if DEBUG`, populates the container with two in-progress books, one finished book, and 7 days of reading activity so previews and the running app exercise the dashboard before real book-management exists. Wired behind a launch argument (`-CrawSeedSampleData YES`) so unmodified debug runs stay empty.

## Risks / Trade-offs

- **SwiftData schema lock-in**: any model change before launch means wiping the dev container. → Acceptable while pre-1.0; document a "delete the simulator app" instruction in CLAUDE.md if it bites.
- **Live counter cynicism**: if a user inspects network or notices the lack of variance under airplane mode, the illusion breaks. → Keep the function high-quality and replace with real data the moment we have a backend.
- **Universal layout punt**: iPhone-shaped dashboard on iPad will look stretched. → Acceptable for MVP; explicitly call this out as a follow-up so it isn't forgotten.
- **Design-token coverage drift**: extracting tokens piecemeal risks duplication across future changes. → Mitigated by keeping `Theme` central — every future change extends it rather than redefining.
- **`#Preview` vs SwiftData**: previews need their own in-memory model container. → Provide a `Theme.previewContainer` helper alongside `SampleData`.

## Open Questions

- None blocking. Cover-image source (book API vs. local asset vs. SF Symbol placeholder) is deferred to `add-book-management`; this change renders whatever the model exposes, falling back to a neutral placeholder.
