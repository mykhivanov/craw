## 1. Foundation extensions

- [ ] 1.1 Extend `Theme` with `Theme.Quiz.passThreshold = 3` (out of 4), `ReadingGoals.dailyMinutes = 30` (centralized; document that `add-goals-schedule` will replace this), and any new color/spacing tokens needed by the timer and quiz surfaces.
- [ ] 1.2 Confirm `FoundationModels` framework links via the existing target (no SPM change needed — it ships with the OS).

## 2. Persistence — new models

- [ ] 2.1 Add SwiftData `@Model ReadingSession`: `id` (UUID), `bookID` (UUID), `startedAt` (Date), `endedAt` (Date), `elapsedSeconds` (Int), `pagesRead` (Int), `verification` (raw `VerificationState` enum: `pending`, `verified`, `failed`, `skipped`, `unavailable`), `reflectionText` (String, default empty).
- [ ] 2.2 Add SwiftData `@Model SessionRetrospective`: `id` (UUID), `sessionID` (UUID), `startDifficulty` (Int 1–5), `focusDifficulty` (Int 1–5), `enjoyment` (Int 1–5), `createdAt` (Date).
- [ ] 2.3 Add SwiftData `@Model Quote`: `id` (UUID), `bookID` (UUID), `text` (String), `pageNumber` (Int?), `capturedAt` (Date).
- [ ] 2.4 Add SwiftData `@Model Thought`: `id` (UUID), `bookID` (UUID), `text` (String), `capturedAt` (Date).
- [ ] 2.5 Extend `CrawModelContainer` to register the four new models in both the live and in-memory variants.
- [ ] 2.6 Extend the debug `SampleData` seeder to include 4 historical sessions across the last 7 days (mix of verified/failed/skipped), 3 quotes, 5 thoughts, and 4 retrospectives matching them — enough to drive a "hard days = 2" derivation.

## 3. Active-session cache (background survival)

- [ ] 3.1 Define `ActiveSessionSnapshot` (`Codable`): `bookID`, `startedAt`, `accumulatedElapsedSeconds`, `currentPage`, `isPaused`, `lastCheckpointAt`.
- [ ] 3.2 Add `ActiveSessionCache` with `save(_:)`, `load() -> ActiveSessionSnapshot?`, `clear()` backed by a single `UserDefaults` key (small enough; no SwiftData needed).
- [ ] 3.3 Wire `SessionEngine` to call `cache.save(...)` on every state transition, on a 15-second timer while `running`, and on `scenePhase` changes to `.background` / `.inactive`. Clear on transition to `idle`.
- [ ] 3.4 On app launch (in `RootView`), if `cache.load()` returns non-nil, route directly to the timer screen and offer Resume / Stop-and-save.

## 4. Session engine

- [ ] 4.1 Implement `@Observable SessionEngine` with `state: SessionState` enum (`idle`, `running`, `paused`, `stopped`, `saving`). Expose `start(book:)`, `pause()`, `resume()`, `stop()`, `setCurrentPage(_:)`.
- [ ] 4.2 Track elapsed time as `accumulatedElapsedSeconds + (running ? now - lastResumeAt : 0)` so backgrounded apps return with correct totals.
- [ ] 4.3 Add unit tests covering: start→stop produces expected pagesRead based on start page and final page, pause/resume excludes paused time, scenePhase transitions trigger cache.save.

## 5. Quiz service

- [ ] 5.1 Define `@Generable struct GeneratedQuiz` with: `questions: [GeneratedQuestion]` (exactly 4), `reflectionPrompt: String`. `GeneratedQuestion`: `prompt`, `options: [String]` (exactly 4), `correctIndex: Int`.
- [ ] 5.2 Implement `QuizService.generate(book:pageStart:pageEnd:) async throws -> GeneratedQuiz` wrapping `FoundationModels.LanguageModelSession`. Build the prompt per `design.md` (book title, author, page range, scoping instructions, low temperature).
- [ ] 5.3 Add `QuizValidator.validate(_:) -> ValidationResult` enforcing the 5 sanity-check rules from the `session-quiz` spec. Reject generations failing any rule.
- [ ] 5.4 Implement `QuizService.gradeAnswers(_:against:) -> VerificationState` returning `.verified` when ≥ `Theme.Quiz.passThreshold` correct, else `.failed`.
- [ ] 5.5 Add an availability check that maps Foundation Models errors and validation failures to `.unavailable` upstream — the caller only sees `verified`, `failed`, or `unavailable`.
- [ ] 5.6 Add unit tests for: validator rejects 3-question output, validator rejects duplicate options, validator rejects out-of-range correctIndex, grader at threshold, grader below threshold.

## 6. Post-stop pipeline

- [ ] 6.1 Define `PostSessionFlow` view orchestrator that drives the four steps: thoughts → quiz → ratings → optional celebration.
- [ ] 6.2 On entry (`saving` state), persist the `ReadingSession` record with `verification = .pending` and update the associated `Book.currentPage`. Then apply the `ReadingDay` upsert (single-day path; multi-day split per spec for sessions crossing midnight).
- [ ] 6.3 Implement idempotent `ReadingDay` writes: keep a small set of "session IDs already applied today" in `UserDefaults` (or a tiny SwiftData ledger) so a re-entry on relaunch doesn't double-count.
- [ ] 6.4 After the quiz step finalizes verification, update the `ReadingSession.verification` field in place.

## 7. UI — timer / active session

- [ ] 7.1 Build `SessionTimerView`: large elapsed-time read-out, current-page stepper, pause/resume button, stop button, two affordances (add quote / add thought). Reuses `Theme` tokens.
- [ ] 7.2 Build `QuickAddQuoteSheet` and `QuickAddThoughtSheet` — text fields, optional page prefilled from session for quotes, Save action persists and dismisses.
- [ ] 7.3 Ensure the page stepper updates `SessionEngine` in real time but never writes to `Book.currentPage` until stop.

## 8. UI — post-stop flow

- [ ] 8.1 Build `ThoughtsPromptView` with a list editor: text field + Add button + scrollable list of added chips with swipe-to-delete. Continue persists all entries.
- [ ] 8.2 Build `QuizView` — renders one `GeneratedQuestion` at a time with the 4 options as large tap targets, advances on selection, shows the reflection prompt as the 5th step (long text field, optional). Submit grades and updates verification.
- [ ] 8.3 Build `QuizUnavailableView` — single-tap "Skip verification this time" acknowledgment shown when generation returns `.unavailable`.
- [ ] 8.4 Build `RetrospectiveView` with three 1–5 rating rows in order (start difficulty, focus difficulty, enjoyment), Continue disabled until all three are selected.
- [ ] 8.5 Build `StreakCelebrationView` — full-screen confetti-style celebration shown on every 6 → 7 transition (including re-achievement after a previous break). No suppression based on prior 7-day achievements. Trigger logic lives in the post-stop pipeline and consults only `streakBefore` and `streakAfter`.

## 9. UI — book detail upgrade

- [ ] 9.1 Replace `BookDetailPlaceholder` with `BookDetailView`. Header: cover (or placeholder) + title + author. Body: page-progress text, circular progress (reuse `DayCell` ring composition), "Start reading session" CTA in Rausch.
- [ ] 9.2 Two collapsible sections beneath the CTA: "Quotes (n)" and "Thoughts (n)", driven by per-book read queries on `Quote` / `Thought`. Read-only; no add/edit/delete affordances on this screen.
- [ ] 9.3 Update the Home dashboard's `BookRow` tap handler to push `BookDetailView` instead of the placeholder.

## 10. Read-side extensions

- [ ] 10.1 Extend `ReadingActivityReader` with `hardDaysInLastSevenDays() -> Int` per the spec: a day is hard if any `SessionRetrospective` for a session that ended on that local day has `startDifficulty >= 4 OR focusDifficulty >= 4`.
- [ ] 10.2 Add per-book read queries on `Quote` and `Thought` ordered by `capturedAt` descending.
- [ ] 10.3 Unit tests: hard-day count over 7 days with mixed retrospectives (zero hard days, all hard days, mid-window hard day, day with both hard and non-hard sessions).

## 11. Cross-midnight handling

- [ ] 11.1 Implement a `MidnightSplitter` that, given a session's start/end timestamps and `Calendar.autoupdatingCurrent`, returns `[(date, seconds)]` for each local day the session touched.
- [ ] 11.2 Wire `MidnightSplitter` into the `ReadingDay` upsert step so multi-day sessions split minutes per spec, attributing pages entirely to the stop-day.
- [ ] 11.3 Unit tests: same-day session returns one bucket, session spanning midnight returns two buckets with correct minute distribution.

## 12. Manual verification

- [ ] 12.1 With `-CrawSeedSampleData YES`, open a seeded book → Start session → log a quote and a thought → adjust page → Stop. Confirm the thoughts prompt appears, then a quiz, then ratings. Verify the book's `currentPage` updates and the dashboard's stat cards refresh.
- [ ] 12.2 Force-quit the app mid-session and relaunch. Confirm the timer screen restores with the correct elapsed time and offers Resume / Stop-and-save.
- [ ] 12.3 Test with a book the on-device model does not know (use an obscure title via the debug seeder). Confirm the flow gracefully shows the `QuizUnavailableView` and proceeds to retrospective.
- [ ] 12.4 Seed a state where the user has exactly 6 days of streak heading into a session. Complete the session and confirm the `StreakCelebrationView` shows.
- [ ] 12.5 Build and run on iPad simulator and confirm the timer and post-stop flow layouts do not break.
- [ ] 12.6 Run `xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 16' build` and confirm a clean build.

## 13. Resolved decisions (no work — for reference)

- Streak celebration fires on every 6 → 7 transition, including re-achievement after a break. See §8.5 and `session-retrospective/spec.md`.
- Quotes have no provenance distinction regardless of where they were captured. No `source` field; no visual treatment differs between in-session, post-session-prompt, and (future) browser-added quotes.
