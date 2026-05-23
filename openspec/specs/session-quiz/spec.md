# session-quiz Specification

## Purpose
TBD - created by archiving change add-session-quiz-verification. Update Purpose after archive.
## Requirements
### Requirement: Quiz shape

Each quiz SHALL contain exactly 4 multiple-choice questions and exactly 1 open-ended reflection prompt. Each multiple-choice question SHALL have exactly 4 distinct options labeled A, B, C, D and a single correct option. The reflection prompt SHALL accept free text and is never graded.

#### Scenario: Generated quiz structure

- **WHEN** the quiz pipeline produces a quiz for a session
- **THEN** the result contains 4 multiple-choice questions and 1 open reflection prompt
- **AND** each multiple-choice question has 4 distinct options and exactly one correct answer

### Requirement: On-device generation via Foundation Models

Quiz questions SHALL be generated on-device using Apple's `FoundationModels` framework with a guided/structured-output schema (`@Generable`). The generation prompt SHALL include: book title, book author, and the page range read in this session. No network call SHALL be made as part of quiz generation.

#### Scenario: Generation uses local model

- **WHEN** a session ends and a quiz is requested
- **THEN** generation is performed by an on-device `LanguageModelSession`
- **AND** no outbound network request is made

#### Scenario: Generation prompt scope

- **WHEN** a quiz is generated for a session spanning pages 40–67 of a book
- **THEN** the prompt sent to the model identifies the book and the page range
- **AND** instructs the model to draw questions from that section

### Requirement: Verification states

Every `ReadingSession` SHALL be assigned exactly one verification state on completion of the post-stop pipeline. The states SHALL be:
- `verified` — user answered at least 3 of 4 multiple-choice questions correctly.
- `failed` — user answered fewer than 3 of 4 multiple-choice questions correctly.
- `skipped` — user dismissed or declined the quiz.
- `unavailable` — the quiz could not be generated (model unavailable, generation errored, or output failed sanity checks).

Only `verified` SHALL be displayed publicly as a "✓ verified" badge. The other three states SHALL count toward private progress (streak, pages, minutes) but SHALL render as unverified.

#### Scenario: User passes the quiz

- **WHEN** the user answers 3 of 4 multiple-choice questions correctly
- **THEN** the session is assigned `verification = .verified`
- **AND** the session displays a "✓ verified" badge

#### Scenario: User misses the threshold

- **WHEN** the user answers 2 of 4 multiple-choice questions correctly
- **THEN** the session is assigned `verification = .failed`
- **AND** the session does not display the verified badge

#### Scenario: User skips the quiz

- **WHEN** the user dismisses the quiz without submitting answers
- **THEN** the session is assigned `verification = .skipped`

#### Scenario: Model unavailable

- **WHEN** quiz generation fails because the on-device model is unavailable or errors
- **THEN** the session is assigned `verification = .unavailable`
- **AND** the user is shown a brief "Skip verification this time" acknowledgment and proceeds to the retrospective

### Requirement: Sanity checks on generated output

Before presenting a quiz to the user, the system SHALL validate the generated output against these rules:
1. Exactly 4 multiple-choice questions are present.
2. Each multiple-choice question has exactly 4 options.
3. Each multiple-choice question's options are mutually distinct.
4. Each multiple-choice question has a `correctIndex` in range [0, 3].
5. The reflection prompt is non-empty.

If any rule fails, generation SHALL be treated as failed and the session SHALL be assigned `verification = .unavailable`.

#### Scenario: Malformed generation

- **WHEN** generation returns 3 multiple-choice questions instead of 4
- **THEN** the validator rejects the output
- **AND** the session is assigned `verification = .unavailable`

### Requirement: Single attempt per session

A session SHALL permit exactly one quiz attempt. After the user submits answers or skips, the verification state SHALL be final for that session.

#### Scenario: No retake

- **WHEN** the user submits answers and receives a `failed` result
- **THEN** no UI affordance is presented to retake the quiz for that session

### Requirement: Open-reflection storage

The user's response to the open-reflection prompt SHALL be persisted on the session record as a free-text field. An empty or omitted reflection is permitted.

#### Scenario: User writes a reflection

- **WHEN** the user enters text for the reflection prompt and submits the quiz
- **THEN** the text is persisted on the `ReadingSession` record

#### Scenario: User leaves reflection empty

- **WHEN** the user submits the quiz with the reflection field empty
- **THEN** the reflection field on the session record is empty
- **AND** the verification state is unaffected by the empty reflection

### Requirement: Threshold is a centralized constant

The "3 of 4" pass threshold SHALL be defined exactly once in the codebase as a named constant. UI copy, grading logic, and any future tuning change SHALL reference that single constant.

#### Scenario: Single source of truth

- **WHEN** the threshold value is referenced in code
- **THEN** all references resolve to one named constant
- **AND** changing the constant in one place changes the threshold everywhere

