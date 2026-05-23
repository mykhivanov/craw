## Why

The post-session quiz is the spine of Craw's "Duolingo for reading" identity. A timer alone is Goodreads-with-a-stopwatch; what makes the product different is a lightweight comprehension check that *verifies* the user actually read. The quiz turns honest streaks into a meaningful signal and gives the streak system its teeth. The `add-home-dashboard` change established the surfaces (streak card, 7-day rings, book lists); this change introduces the *engine* that fills them.

Without this change there is no way to log a reading session, no verification primitive, no retrospective ratings, and no `ReadingDay` writes — meaning the dashboard cannot do anything except show seeded debug data.

## What Changes

- Introduce reading sessions as a first-class feature: start from a book detail screen, run a foreground timer with pause/resume/stop, track current page during the session, survive app backgrounding via auto-save, and save a `ReadingSession` record on stop.
- Capture in-session and post-session thoughts and quotes against the book being read.
- Introduce an AI-generated post-session quiz: **4 multiple-choice questions + 1 open-ended reflection prompt**, scoped to the page range read in this session, generated on-device via Apple's Foundation Models framework (iOS 26+).
- Define verification states for each session: `verified` (≥3 of 4 MC correct), `failed` (<3 of 4 correct), `skipped` (user dismissed the quiz), `unavailable` (model could not generate questions). `verified` is the only state that grants the public "✓ verified" badge; all others count toward private progress (streak, totals, rings) but render unverified.
- Run a post-quiz retrospective capturing three 1–5 ratings per session: enjoyment, how hard it was to **start**, how hard it was to **focus**. Define a per-day "hard day" derivation (any session that day rated start≥4 OR focus≥4) so the future Stats tab can render a "hard days this week" card.
- Trigger a full-screen streak celebration when a session brings the user's streak to exactly 7 consecutive days.
- Promote the book-detail placeholder from `add-home-dashboard` into a real book-detail screen containing title/author/cover, progress, the session-start CTA, and read-only lists of this book's quotes and thoughts.

## Capabilities

### New Capabilities

- `reading-session`: timer state machine (idle → running → paused → stopped), page-counter adjustments during the session, auto-save against backgrounding, session-record persistence on stop, and the single user-facing entry point ("Start reading session" on the book detail).
- `session-quiz`: on-device generation of 4 MC + 1 reflection per session using Apple Foundation Models with `@Generable` structured output, grading and threshold logic, and verification-state assignment. Handles model-unavailable and generation-failure paths gracefully.
- `session-retrospective`: the post-stop flow orchestration — thoughts prompt → quiz → three 1–5 ratings → streak celebration — and the per-day "hard day" derivation used by future stats surfaces.
- `quotes-and-thoughts`: domain model and persistence for quotes (text + optional page) and thoughts (text), each linked to a book, with capture entry points during a session and at the post-session thoughts prompt. The all-quotes browser and search are out of scope and deferred.
- `book-detail`: the real book-detail screen replacing the home-dashboard placeholder. Hosts the session-start CTA and read-only lists of this book's quotes and thoughts.

### Modified Capabilities

- `reading-activity`: add write-side requirements (sessions create or update the day's `ReadingDay` row, with cross-midnight splits per the existing local-bucketing rule), and add the per-day "hard day" derivation alongside the existing today-pages and streak derivations.

## Impact

- **Code**: New SwiftUI views for the timer/session screens, the post-stop flow (thoughts → quiz → retrospective → optional celebration), and the upgraded book detail. New SwiftData `@Model`s for `ReadingSession`, `SessionRetrospective`, `Quote`, `Thought`. New `QuizService` wrapping `FoundationModels.LanguageModelSession`.
- **Dependencies**: First use of Apple's `FoundationModels` framework (iOS 26+). No third-party SPM additions.
- **Data writes**: This change is the first source of `ReadingDay` writes outside of debug seeding. Establishes the convention that day rows are upserted, not duplicated.
- **Shared assumption inherited from `add-home-dashboard`**: the user's daily reading-time goal is hardcoded (30 minutes) until `add-goals-schedule` ships. Documented in design.
- **Privacy and offline**: Quiz generation is on-device; sessions and retrospectives never leave the device in this change. Compatible with airplane mode end-to-end except when the Foundation Model itself is unavailable on the device.
- **Surfaces this change does NOT touch**: lock-screen Live Activity widget for the active session (deferred — separate widget extension target), all-quotes browser and search (deferred), Stats tab UI (the data and derivations land here, the chrome lands in a future stats change), goals/schedule, notifications, settings, onboarding, paywall.
