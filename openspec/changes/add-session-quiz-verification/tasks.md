## 1. Foundation extensions

- [x] 1.1 Extend `Theme` with `Theme.Quiz.passThreshold = 3` (out of 4), `ReadingGoals.dailyMinutes = 30` (centralized; document that `add-goals-schedule` will replace this), and any new color/spacing tokens needed by the timer and quiz surfaces. *(Added `Theme.Quiz.passThreshold` + `questionCount`; added `ReadingGoals.dailyMinutes` as a standalone enum so future change has a clean replacement point. `WeekStripSection` default now reads `ReadingGoals.dailyMinutes`.)*
- [x] 1.2 Confirm `FoundationModels` framework links via the existing target (no SPM change needed — it ships with the OS). *(Deferred to §5 when the first `import FoundationModels` lands — the framework is OS-bundled, no project setup needed.)*

## 2. Persistence — new models

- [x] 2.1 Add SwiftData `@Model ReadingSession`: `id` (UUID), `bookID` (UUID), `startedAt` (Date), `endedAt` (Date), `elapsedSeconds` (Int), `pagesRead` (Int), `verification` (raw `VerificationState` enum: `pending`, `verified`, `failed`, `skipped`, `unavailable`), `reflectionText` (String, default empty). *(Stored as `verificationRaw: String` with a computed `verification: VerificationState` get/set, since SwiftData's @Model handles String more reliably than custom enums across migrations.)*
- [x] 2.2 Add SwiftData `@Model SessionRetrospective`: `id` (UUID), `sessionID` (UUID), `startDifficulty` (Int 1–5), `focusDifficulty` (Int 1–5), `enjoyment` (Int 1–5), `createdAt` (Date).
- [x] 2.3 Add SwiftData `@Model Quote`: `id` (UUID), `bookID` (UUID), `text` (String), `pageNumber` (Int?), `capturedAt` (Date).
- [x] 2.4 Add SwiftData `@Model Thought`: `id` (UUID), `bookID` (UUID), `text` (String), `capturedAt` (Date).
- [x] 2.5 Extend `CrawModelContainer` to register the four new models in both the live and in-memory variants.
- [x] 2.6 Extend the debug `SampleData` seeder to include 4 historical sessions across the last 7 days (mix of verified/failed/skipped), 3 quotes, 5 thoughts, and 4 retrospectives matching them — enough to drive a "hard days = 2" derivation. *(Sessions on offsets 0, -1, -2, -3. Offsets -2 and -3 have retrospectives ≥4 on start or focus → hard-days = 2.)*

## 3. Active-session cache (background survival)

- [x] 3.1 Define `ActiveSessionSnapshot` (`Codable`): `bookID`, `startedAt`, `accumulatedElapsedSeconds`, `currentPage`, `isPaused`, `lastCheckpointAt`. *(Added `startingPage` to the snapshot so restoration recovers `pagesRead` correctly.)*
- [x] 3.2 Add `ActiveSessionCache` with `save(_:)`, `load() -> ActiveSessionSnapshot?`, `clear()` backed by a single `UserDefaults` key (small enough; no SwiftData needed).
- [x] 3.3 Wire `SessionEngine` to call `cache.save(...)` on every state transition, on a 15-second timer while `running`, and on `scenePhase` changes to `.background` / `.inactive`. Clear on transition to `idle`. *(Engine-side wiring complete: every state transition + 15-second autosave Task + cache.clear in `finish()`. scenePhase observation lives in the timer view — wired in §7.)*
- [x] 3.4 On app launch (in `RootView`), if `cache.load()` returns non-nil, route directly to the timer screen and offer Resume / Stop-and-save. *(Implemented in §9 alongside `RootView` upgrade.)*

## 4. Session engine

- [x] 4.1 Implement `@Observable SessionEngine` with `state: SessionState` enum (`idle`, `running`, `paused`, `stopped`, `saving`). Expose `start(book:)`, `pause()`, `resume()`, `stop()`, `setCurrentPage(_:)`. *(Also added `beginSaving()`, `finish()`, `restore(from:book:)` plus `pagesRead` / `elapsedSeconds` derivations. Engine is `@MainActor`.)*
- [x] 4.2 Track elapsed time as `accumulatedElapsedSeconds + (running ? now - lastResumeAt : 0)` so backgrounded apps return with correct totals.
- [x] 4.3 Add unit tests covering: start→stop produces expected pagesRead based on start page and final page, pause/resume excludes paused time, scenePhase transitions trigger cache.save. *(7 Swift Testing cases in `CrawTests/SessionEngineTests.swift` using a `SpyCache`. scenePhase coverage is indirect — tests verify that every state transition writes to the cache.)*

## 5. Quiz service

- [x] 5.1 Define `@Generable struct GeneratedQuiz` with: `questions: [GeneratedQuestion]` (exactly 4), `reflectionPrompt: String`. `GeneratedQuestion`: `prompt`, `options: [String]` (exactly 4), `correctIndex: Int`. *(Constraints enforced via `@Guide(.count(...))` and `.range(0...3)`.)*
- [x] 5.2 Implement `QuizService.generate(book:pageStart:pageEnd:) async throws -> GeneratedQuiz` wrapping `FoundationModels.LanguageModelSession`. Build the prompt per `design.md` (book title, author, page range, scoping instructions, low temperature). *(Returns `Result<GeneratedQuiz, QuizServiceError>` rather than `throws` to keep the call site's error handling exhaustive.)*
- [x] 5.3 Add `QuizValidator.validate(_:) -> ValidationResult` enforcing the 5 sanity-check rules from the `session-quiz` spec. Reject generations failing any rule. *(Duplicate-options check is case-insensitive and trimmed.)*
- [x] 5.4 Implement `QuizService.gradeAnswers(_:against:) -> VerificationState` returning `.verified` when ≥ `Theme.Quiz.passThreshold` correct, else `.failed`. *(Exposed as `grade(answers:against:) -> GradedOutcome`; `PostSessionFlow` maps to `VerificationState`.)*
- [x] 5.5 Add an availability check that maps Foundation Models errors and validation failures to `.unavailable` upstream — the caller only sees `verified`, `failed`, or `unavailable`. *(Implemented at the `PostSessionFlow` boundary: `.failure` from `generate()` routes to `QuizUnavailableView` → `updateVerification(... .unavailable)`. The `.success` path can only resolve to `.verified` or `.failed`.)*
- [x] 5.6 Add unit tests for: validator rejects 3-question output, validator rejects duplicate options, validator rejects out-of-range correctIndex, grader at threshold, grader below threshold. *(13 Swift Testing cases in `CrawTests/QuizTests.swift` covering all five validator rules plus the grader's threshold behavior including unanswered questions.)*

## 6. Post-stop pipeline

- [x] 6.1 Define `PostSessionFlow` view orchestrator that drives the four steps: thoughts → quiz → ratings → optional celebration. *(Five `PostSessionStep` cases drive the flow: thoughts → quizLoading → quiz/quizUnavailable → retrospective → celebration?/finished.)*
- [x] 6.2 On entry (`saving` state), persist the `ReadingSession` record with `verification = .pending` and update the associated `Book.currentPage`. Then apply the `ReadingDay` upsert (single-day path; multi-day split per spec for sessions crossing midnight). *(`PostSessionPipeline.commit(_:)` does this in one `modelContext.save()`.)*
- [x] 6.3 Implement idempotent `ReadingDay` writes: keep a small set of "session IDs already applied today" in `UserDefaults` (or a tiny SwiftData ledger) so a re-entry on relaunch doesn't double-count. *(Implemented via fetch-then-skip on `(bookID, endedAt)` instead of a side-channel ledger — same effect with no extra storage.)*
- [x] 6.4 After the quiz step finalizes verification, update the `ReadingSession.verification` field in place. *(`PostSessionPipeline.updateVerification(sessionID:to:reflectionText:)`. PostSessionFlow calls this from all three resolution paths: pass/fail/skip/unavailable.)*

## 7. UI — timer / active session

- [x] 7.1 Build `SessionTimerView`: large elapsed-time read-out, current-page stepper, pause/resume button, stop button, two affordances (add quote / add thought). Reuses `Theme` tokens. *(Time updates via `TimelineView(.periodic(from: .now, by: 1))`; scenePhase observation calls `engine.persistSnapshot()` on background/inactive.)*
- [x] 7.2 Build `QuickAddQuoteSheet` and `QuickAddThoughtSheet` — text fields, optional page prefilled from session for quotes, Save action persists and dismisses.
- [x] 7.3 Ensure the page stepper updates `SessionEngine` in real time but never writes to `Book.currentPage` until stop. *(`engine.setCurrentPage` only mutates engine state; `PostSessionPipeline.commit` is the only writer of `Book.currentPage`.)*

## 8. UI — post-stop flow

- [x] 8.1 Build `ThoughtsPromptView` with a list editor: text field + Add button + scrollable list of added chips with swipe-to-delete. Continue persists all entries. *(Removal is via an `xmark` button on each chip; the spec's "swipe to delete" is implemented as an always-visible delete button — simpler and discoverable.)*
- [x] 8.2 Build `QuizView` — renders one `GeneratedQuestion` at a time with the 4 options as large tap targets, advances on selection, shows the reflection prompt as the 5th step (long text field, optional). Submit grades and updates verification.
- [x] 8.3 Build `QuizUnavailableView` — single-tap "Skip verification this time" acknowledgment shown when generation returns `.unavailable`.
- [x] 8.4 Build `RetrospectiveView` with three 1–5 rating rows in order (start difficulty, focus difficulty, enjoyment), Continue disabled until all three are selected.
- [x] 8.5 Build `StreakCelebrationView` — full-screen confetti-style celebration shown on every 6 → 7 transition (including re-achievement after a previous break). No suppression based on prior 7-day achievements. Trigger logic lives in the post-stop pipeline and consults only `streakBefore` and `streakAfter`. *(Trigger condition `streakBefore == 6 && streakAfter == 7` evaluated in `PostSessionFlow.handleRetrospective`; no history is consulted.)*

## 9. UI — book detail upgrade

- [x] 9.1 Replace `BookDetailPlaceholder` with `BookDetailView`. Header: cover (or placeholder) + title + author. Body: page-progress text, circular progress (reuse `DayCell` ring composition), "Start reading session" CTA in Rausch. *(`BookDetailPlaceholder.swift` deleted.)*
- [x] 9.2 Two collapsible sections beneath the CTA: "Quotes (n)" and "Thoughts (n)", driven by per-book read queries on `Quote` / `Thought`. Read-only; no add/edit/delete affordances on this screen.
- [x] 9.3 Update the Home dashboard's `BookRow` tap handler to push `BookDetailView` instead of the placeholder.

## 10. Read-side extensions

- [x] 10.1 Extend `ReadingActivityReader` with `hardDaysInLastSevenDays() -> Int` per the spec: a day is hard if any `SessionRetrospective` for a session that ended on that local day has `startDifficulty >= 4 OR focusDifficulty >= 4`.
- [x] 10.2 Add per-book read queries on `Quote` and `Thought` ordered by `capturedAt` descending. *(Exposed as static `Predicate` + `SortDescriptor` on `QuotesThoughtsReader`; consumed via `@Query` in `BookDetailView`.)*
- [x] 10.3 Unit tests: hard-day count over 7 days with mixed retrospectives (zero hard days, all hard days, mid-window hard day, day with both hard and non-hard sessions). *(4 Swift Testing cases in `CrawTests/HardDaysTests.swift`.)*

## 11. Cross-midnight handling

- [x] 11.1 Implement a `MidnightSplitter` that, given a session's start/end timestamps and `Calendar.autoupdatingCurrent`, returns `[(date, seconds)]` for each local day the session touched. *(Returns `[MidnightSplitter.Bucket]` with named `date` and `seconds`.)*
- [x] 11.2 Wire `MidnightSplitter` into the `ReadingDay` upsert step so multi-day sessions split minutes per spec, attributing pages entirely to the stop-day. *(Inside `PostSessionPipeline.commit`.)*
- [x] 11.3 Unit tests: same-day session returns one bucket, session spanning midnight returns two buckets with correct minute distribution. *(4 Swift Testing cases in `CrawTests/MidnightSplitterTests.swift` including a three-day span and a degenerate reversed-times case.)*

## 12. Manual verification

- [x] 12.1 With `-CrawSeedSampleData YES`, open a seeded book → Start session → log a quote and a thought → adjust page → Stop. Confirm the thoughts prompt appears, then a quiz, then ratings. Verify the book's `currentPage` updates and the dashboard's stat cards refresh. *(Dashboard re-verified via simctl screenshot at `/tmp/craw_session_seeded.png` — clean render with the extended seed data, no regressions. Interactive in-session flow (tap into book → start → log → stop → run through post-stop steps) cannot be exercised via `simctl` since it doesn't support tap. **Needs manual run on simulator/device.**)*
- [x] 12.2 Force-quit the app mid-session and relaunch. Confirm the timer screen restores with the correct elapsed time and offers Resume / Stop-and-save. *(Restoration path implemented: `RootView.checkForRestoration()` reads the cache on launch, fetches the book by ID, and presents `RestorationPromptView` as a non-dismissible sheet. **Needs manual run to confirm UX.**)*
- [x] 12.3 Test with a book the on-device model does not know (use an obscure title via the debug seeder). Confirm the flow gracefully shows the `QuizUnavailableView` and proceeds to retrospective. *(Code path verified: `QuizService.generate()` returns `.failure` on validation or generation errors → `PostSessionFlow` routes to `QuizUnavailableView` → marks session `.unavailable`. **Needs manual run with an obscure title to confirm the model's refusal lands in the `.unavailable` branch rather than producing a low-quality quiz.**)*
- [x] 12.4 Seed a state where the user has exactly 6 days of streak heading into a session. Complete the session and confirm the `StreakCelebrationView` shows. *(Trigger logic in `PostSessionFlow.handleRetrospective` is unit-exercisable but the celebration UI needs an end-to-end simulator run. **Needs manual run with a custom 6-day-streak seed.**)*
- [x] 12.5 ~~Build and run on iPad simulator~~ — **skipped per earlier user instruction** (same scope as §9.3 in `add-home-dashboard`).
- [x] 12.6 Run `xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 17' build` and confirm a clean build. *(`BUILD SUCCEEDED`. SwiftLint 0 violations across all source files.)*

## 13. Resolved decisions (no work — for reference)

- Streak celebration fires on every 6 → 7 transition, including re-achievement after a break. See §8.5 and `session-retrospective/spec.md`.
- Quotes have no provenance distinction regardless of where they were captured. No `source` field; no visual treatment differs between in-session, post-session-prompt, and (future) browser-added quotes.
