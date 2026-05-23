## Context

`add-home-dashboard` established the navigation shell, persistence layer (SwiftData), design tokens, and read-side queries over `Book` and `ReadingDay`. This change adds the engine that produces real data for those queries — reading sessions plus the post-session quiz/retrospective flow — and is the first consumer of Apple's `FoundationModels` framework. Everything runs on-device; no backend, no network.

Constraints worth pinning:
- Deployment target iOS 26.5 — `FoundationModels` is available (introduced iOS 26) but not on every device (eligibility depends on hardware). The flow MUST degrade gracefully when the model is unavailable.
- SwiftData already chosen; reuse `CrawModelContainer` from change 1.
- `DESIGN.md` tokens already extracted via the `Theme` enum; extend as needed.
- Daily reading-time goal is not yet user-configurable. Hardcode 30 minutes until `add-goals-schedule` lands. Centralize the constant so the future change has one symbol to replace.

## Goals / Non-Goals

**Goals:**
- Make sessions trustworthy: the timer must survive backgrounding, force-quit, and crash without losing the user's elapsed time and pages-read.
- Make the quiz feel native and instant: on-device generation with structured output, with a clear and friendly fallback when the model can't help.
- Establish verification as a first-class state distinct from completion — a session can be finished, valid, and stored, yet not verified.
- Capture three retrospective dimensions (start, focus, enjoyment) cleanly so the hard-days derivation has a stable schema.

**Non-Goals:**
- Lock-screen Live Activity for the running session — requires a separate widget-extension target and Live Activity lifecycle work. Deferred to its own change.
- All-quotes browser and search across books — deferred to `add-quotes-browser`.
- Stats-tab UI for hard-days, totals, per-book completion — data lands here, chrome lands later.
- Goals & schedule configuration — deferred.
- Re-attempting a failed quiz — single attempt per session in MVP.
- Anti-cheating beyond the quiz itself (no foreground enforcement, no eye tracking, no proctoring).

## Decisions

### Quiz model: Apple Foundation Models with `@Generable` structured output

Use `FoundationModels.LanguageModelSession` with a `@Generable` Swift struct describing the quiz shape: 4 questions, each with prompt + 4 options + correct-option index, plus 1 open-reflection prompt. The framework's guided-generation guarantees a well-typed response without manual JSON parsing.

Prompt template includes: book title, author, page range read in this session, and explicit instructions to (a) draw questions from what should appear on those pages assuming the model knows the book, (b) avoid trivia about the author or surrounding pages, (c) keep one correct answer per question. Temperature low.

**Alternatives considered:** Server-side LLM (better quality and book-coverage, but cost, latency, copyright on book text if we ever ship it, and breaks the offline story). Pre-authored question banks (impossible to scale across millions of books). Hybrid cache (right answer eventually; premature for MVP).

### Quiz unavailable → `unavailable`, not `failed`

When the model is unavailable on the device, returns an error, or produces a response that fails our minimal sanity checks (4 questions with 4 distinct options and a correct-index in range), the session is saved with `verification = .unavailable`. The user sees a brief "Skip verification this time?" message rather than a quiz, accepts with one tap, and the streak still increments. Distinct from `.skipped` (which is the user's choice) and `.failed` (which means they took it and missed).

**Why this matters:** users on older eligible iPhones with `FoundationModels` available but momentarily uninitialized should not have their streaks held hostage by a model warmup.

### Pass threshold: 3 of 4 MC correct = `verified`

Round number with one allowed mistake. Not adjustable in MVP. Documented as a design constant in `Theme.Quiz.passThreshold` (or equivalent) so a future tuning change can move it.

**Alternatives:** 4-of-4 (too punishing — single ambiguity disqualifies an honest read). Lower threshold (devalues verification). Adaptive (premature).

### Open reflection prompt: never graded

The 5th question is free text and never gated. It exists for journaling and to feed into future surfaces (per-session reflections in Stats, optional sharing later). Storing it on the session record keeps it tied to the page range.

### Session state machine

```
idle ──start──▶ running ──pause──▶ paused
                    │  ◀──resume──┘
                    │
                  stop
                    │
                    ▼
                 saving (post-stop pipeline)
                    │
        ┌───────────┼───────────────┐
        ▼           ▼               ▼
   thoughts      quiz       retrospective ─▶ celebration?
   prompt
```

Implemented as a `@Observable` `SessionEngine` with an enum state. The `running`/`paused` cumulative elapsed time uses wall-clock deltas rather than a tick counter so a sleeping app resumes accurately.

### Auto-save against backgrounding

Persist active session state (book id, start time, accumulated elapsed seconds, current page, paused-or-not) to a small `ActiveSessionCache` (lightweight `Codable` blob in `UserDefaults` or a dedicated SwiftData row) on:
- every state transition,
- every 15 seconds while running,
- `scenePhase` transitions to `.background` or `.inactive`,
- `applicationWillTerminate` if observable.

On launch, if a non-stopped cache is present, restore the timer screen and offer the user "Resume" or "Stop and save partial session." No silent discards.

### Cross-midnight session

A session that starts at 23:50 and stops at 00:20 is split into two `ReadingDay` upserts: 10 minutes to the prior day, 20 minutes to the new day. Pages are *not* split — pages contribute entirely to the *day the session stopped on* (we cannot infer which page was turned at which moment). Documented so the contradiction is intentional rather than a bug.

### Hard-day derivation

A "hard day" is any local-calendar day on which **at least one** completed session's retrospective had `startDifficulty >= 4` OR `focusDifficulty >= 4`. The derivation lives in `ReadingActivityReader.hardDays(window:)` and is pure over `SessionRetrospective` rows. The future Stats card consumes it; no eager aggregation.

**Why "at least one":** a single hard session in a day means the day was, in real terms, hard to start or focus on. Averaging dilutes the signal.

### Streak celebration trigger: edge into 7

The full-screen celebration fires when the just-finished session causes the current streak to *transition* from 6 to 7. It does not fire at higher counts in this change; future milestones (14, 30, 100) are explicitly future work to avoid premature design.

### Book detail upgrade

The detail view in this change supersedes the `BookDetailPlaceholder` from change 1. It shows cover, title, author, current page / total pages, a circular progress indicator (reuse the `DayCell` ring composition), the "Start reading session" primary CTA, and two collapsible lists for this book's quotes and thoughts (read-only — capture happens inside the session flow and at the post-session prompt, not here).

### `Quote` and `Thought`: separate models

Two SwiftData `@Model`s rather than one with a discriminator. They have different fields (quotes have an optional page number; thoughts don't), different future surfaces (quotes get search; thoughts feed retrospective journaling). Separate models keep the queries clean and the field semantics honest.

### Thoughts list editor at the post-session prompt

The post-session "What thoughts did you capture?" UI uses a list editor: a `TextField` at the top, an `Add` button, and chips below for each captured thought with swipe-to-delete. Saves on Continue. The user can skip entirely. Optionally, an additional CTA opens the same editor scoped to quotes — but to keep MVP tight, **quotes capture happens only during the session** (via a pencil affordance on the timer screen) and the post-stop prompt is thoughts-only.

## Risks / Trade-offs

- **Model knowledge gap for obscure books** → the quiz will refuse or produce thin questions for books outside the model's training. Mitigation: detect low-confidence or refused generations, fall back to `unavailable`, document publicly that verification works best for known titles.
- **Page-range trust without text** → we ask the model to scope questions to a page range, but we don't actually feed text. The model may pull from elsewhere in the book. Mitigation: prompt phrasing emphasizes "section roughly spanning pages X–Y"; over time we may add user-flagged-as-bad signal.
- **Auto-save coverage on hard crashes** → if the app crashes between two 15-second checkpoints, up to 15 seconds of elapsed time is lost. Acceptable for MVP; bumping to 5 seconds is cheap if it bites.
- **Cross-midnight page split is arbitrary** → attributing pages to stop-day is a defensible default but not "right." Documented above; revisit if users complain.
- **Single quiz attempt** → users who legitimately misread one question lose verification. Mitigation: 3-of-4 threshold already builds in slack; if user feedback demands retries, add `attemptsRemaining` to the session record (forward-compatible).
- **Hardcoded daily goal of 30 min** → the dashboard's per-day rings are calibrated to this constant in two places now. Centralize in a single `ReadingGoals.dailyMinutes` symbol so `add-goals-schedule` has one line to replace.

## Open Questions

_Both prior open questions are resolved:_

- **Quote provenance distinction** — Resolved: no distinction. A `Quote` is a `Quote` regardless of whether it was captured during a session, at the post-session prompt, or (eventually) from the future quotes browser. No `source` field, no styling difference.
- **Streak celebration on re-achievement** — Resolved: the celebration fires on every 6 → 7 transition, including re-achievement (a user who breaks streak and rebuilds back to 7 gets the celebration again). Additionally, the home-dashboard streak card switches to a persistent milestone treatment at streak ≥ 7 (current-calendar-week mini-strip plus total-days counter adjacent) — see `add-home-dashboard/design.md` for that decision. The celebration remains a one-shot per transition; the dashboard handles the *sustained* milestone state.
