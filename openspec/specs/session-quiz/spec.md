# session-quiz Specification

## Purpose

`session-quiz` is the optional post-session quiz that lets a user verify their understanding of what they just read. After the redesign-reading-session-flow change, the quiz is server-driven (no on-device generation) and only runs for study-attitude books — for-fun sessions skip it. The flow is stateless on the server: the client sends the book name plus the user's selection on each call, and grading returns a single mark from 1–3 mapped to a titled feedback string.

## Requirements

### Requirement: Post-session quiz triggers only for study books

The post-session quiz flow SHALL trigger only when the just-ended session's book has `attitude == .study`. Sessions for books with `attitude == .entertainment` SHALL skip the quiz flow entirely and proceed directly to the retrospective.

#### Scenario: For-fun session skips quiz

- **WHEN** a session for a `.entertainment` book transitions to `saving`
- **THEN** the post-session flow advances directly to the retrospective step
- **AND** no `/v1/quiz/sections` request is made

#### Scenario: Study session enters quiz flow

- **WHEN** a session for a `.study` book transitions to `saving` (via the "Finish" button)
- **THEN** the post-session flow enters the section picker step before the retrospective

### Requirement: Section picker fetches plain-text sections

When the quiz flow begins for a study book, the client SHALL issue `POST /v1/quiz/sections` with body `{ bookName: String }` (the book's title). The server returns a JSON array of plain-text section names: `[String]`. The client SHALL present these as a tappable list. The user SHALL also be able to type a page number into a free-text input as an alternative to picking a section, and SHALL be able to skip this step entirely.

#### Scenario: Sections render as tappable list

- **WHEN** the sections endpoint returns `["Part 1: Astrophage", "Part 2: The Bridge", "Part 3: Rocky"]`
- **THEN** the screen renders three tappable rows containing those exact strings

#### Scenario: User picks a section

- **WHEN** the user taps "Part 2: The Bridge"
- **THEN** the flow advances to the questions step with `sectionOrPage = "Part 2: The Bridge"` carried in memory

#### Scenario: User types a page number

- **WHEN** the user types `147` into the page input and confirms
- **THEN** the flow advances to the questions step with `sectionOrPage = "147"` carried in memory

#### Scenario: User skips the picker

- **WHEN** the user taps Skip on the section picker
- **THEN** the flow advances directly to the retrospective step
- **AND** no `/v1/quiz/questions` request is made

#### Scenario: Sections request fails

- **WHEN** the `/v1/quiz/sections` request returns any `APIError`
- **THEN** the flow advances directly to the retrospective step
- **AND** no error toast is required (graceful degradation)

### Requirement: Questions screen fetches questions for the selection

When the user advances from the section picker with a selection, the client SHALL issue `POST /v1/quiz/questions` with body `{ bookName: String, sectionOrPage: String }`. When the user reached the quiz flow via the "Book is finished" button, the body SHALL be `{ bookName: String, finished: true }` (no `sectionOrPage` field) and the section picker SHALL be skipped entirely.

The server returns a JSON array of `{ question: String, options: [String] }`. The client SHALL render each question with its options as a single-select picker. The user SHALL be able to skip the quiz at any point from this screen.

#### Scenario: Questions render as single-select pickers

- **WHEN** the questions endpoint returns `[{ question: "Who narrates?", options: ["Alice", "Bob", "Carol", "Dan"] }, { question: "Where?", options: ["Mars", "Moon", "Venus", "Earth"] }]`
- **THEN** the screen renders two questions, each with four single-select options

#### Scenario: Book-is-finished skips picker

- **WHEN** the user tapped "Book is finished" for a study book and the post-session flow enters
- **THEN** the section picker step is skipped
- **AND** the client issues `POST /v1/quiz/questions` with body `{ bookName, finished: true }`

#### Scenario: User skips the questions

- **WHEN** the user taps Skip on the questions screen
- **THEN** the flow advances directly to the retrospective step
- **AND** no `/v1/quiz/grade` request is made
- **AND** the saved `ReadingSession.quizMark` remains `nil`

#### Scenario: Questions request fails

- **WHEN** the `/v1/quiz/questions` request returns any `APIError`
- **THEN** the flow advances directly to the retrospective step

### Requirement: Grade returns a mark mapped to titled feedback

When the user selects an option for every returned question and taps Continue, the client SHALL issue `POST /v1/quiz/grade` with body `{ bookName: String, sectionOrPage: String?, answers: [String] }`. The `answers` array SHALL contain the selected option strings in the same order as the questions returned by `/v1/quiz/questions`. The server returns `{ mark: Int }` where `mark ∈ {1, 2, 3}`.

The client SHALL display the result as titled feedback:
- `mark = 1` → "Consider rereading"
- `mark = 2` → "Good"
- `mark = 3` → "Great session"

The client SHALL persist `ReadingSession.quizMark = mark` and `ReadingSession.sectionOrPageHint = sectionOrPage` (when present) before advancing to the retrospective.

#### Scenario: Mark 1 renders "Consider rereading"

- **WHEN** the grade endpoint returns `{ mark: 1 }`
- **THEN** the feedback screen displays "Consider rereading"

#### Scenario: Mark 2 renders "Good"

- **WHEN** the grade endpoint returns `{ mark: 2 }`
- **THEN** the feedback screen displays "Good"

#### Scenario: Mark 3 renders "Great session"

- **WHEN** the grade endpoint returns `{ mark: 3 }`
- **THEN** the feedback screen displays "Great session"

#### Scenario: Mark persists to the session record

- **WHEN** the user advances past the feedback screen with `mark = 2` and `sectionOrPage = "Chapter 4"`
- **THEN** the `ReadingSession.quizMark` becomes `2`
- **AND** the `ReadingSession.sectionOrPageHint` becomes `"Chapter 4"`

#### Scenario: Grade request fails

- **WHEN** the `/v1/quiz/grade` request returns any `APIError`
- **THEN** the flow advances directly to the retrospective step
- **AND** `ReadingSession.quizMark` remains `nil`

### Requirement: Quiz is skippable at every step

The user SHALL be able to skip the quiz flow at any step (section picker, questions, between questions). Skipping SHALL not surface an error or warning. Skipping SHALL not affect `ReadingDay` minutes, streak credit, or the retrospective step.

#### Scenario: Skip from any step lands on retrospective

- **WHEN** the user taps Skip at any quiz-flow step
- **THEN** the next screen presented is the retrospective
- **AND** the session's minute and streak credits are unchanged
