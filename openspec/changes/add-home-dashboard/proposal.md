## Why

Craw is a SwiftUI iOS/iPadOS scaffold today — `ContentView` renders "Hello, world!" and no domain functionality exists. The product vision is "Duolingo for reading": streaks, gentle pressure, and verification keep users coming back. The Home dashboard is the surface that delivers that loop on every app launch — it shows progress, surfaces in-flight books, and serves as the launchpad into reading sessions. Without it, there is no app.

## What Changes

- Introduce the app's primary navigation shell: a 4-tab `TabView` (Home, Quotes, Stats, Profile). Only the Home tab is populated by this change; the other three are placeholder destinations to establish information architecture.
- Build the Home dashboard as a single vertically scrolling feed containing:
  - Daily greeting using the current weekday.
  - Estimated/fake "people reading now" live counter (sub-counter beneath greeting).
  - 7-day calendar strip with per-day progress rings (reading time vs. daily goal).
  - Two stat cards on a single row: today's pages read with % change vs. yesterday (trend arrow), and current weekly streak.
  - "Reading Now" section listing in-progress books with title, cover, and progress bar.
  - "Finished" section listing completed books.
  - Add-book entry point (`+` affordance in the Reading Now section header).
  - Empty states for: no books at all, no in-progress books, no finished books.
- Introduce a domain model for `Book` (title, author, cover, page counts, status) and `ReadingDay` (date, minutes read, page count) sufficient to drive the dashboard's reads. Persistence layer chosen and justified in `design.md`.
- Seed deterministic sample data behind a debug-only toggle so the dashboard can be exercised before book-management and session features land.

## Capabilities

### New Capabilities

- `app-shell`: Root `TabView` navigation skeleton and tab destinations (Home populated; Quotes/Stats/Profile placeholders that the future changes will fill in).
- `home-dashboard`: The Home tab's scrolling dashboard with greeting, live counter, weekly rings, stat cards, book lists, and empty states.
- `book-library`: Minimal `Book` domain model and persistence sufficient to power Reading Now / Finished lists on the dashboard. Book creation, editing, and deletion are deferred to a later change — this capability only owns the *shape* of a book and read access.
- `reading-activity`: Per-day reading-time and page totals needed to render the 7-day rings and today's stat card. Write-side (logging a session) is owned by the future session-quiz change; this capability owns the read model and the day-bucketing logic.

### Modified Capabilities

None — first change, no existing specs.

## Impact

- **Code**: New SwiftUI views under `Craw/` (Home tab, dashboard sections, tab shell, placeholder tabs). Replaces the existing `ContentView` stub with `RootView` as the app's entry point.
- **Data**: New persistence layer (SwiftData chosen — see `design.md`) introduces a `.store` file in the app sandbox. Schema migrations not yet a concern (greenfield).
- **Dependencies**: No new SPM packages. SwiftData and SwiftUI only.
- **Design system**: First real consumer of `DESIGN.md` tokens (Rausch accent, Cereal font fallback to Inter, pill/card radii, single shadow tier). May surface gaps in the spec — those get raised in `design.md`, not solved here.
- **Future changes**: Establishes the home for the streak chip, hard-days stat card, and verified badge that the session-quiz change will plug into. Locks navigation IA — later changes add destinations within tabs, not new tabs.
