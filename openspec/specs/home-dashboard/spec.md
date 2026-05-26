# home-dashboard Specification

## Purpose

The Home tab is the first surface a returning user lands on. Its job is twofold: give a glanceable sense of recent reading activity (greeting, week strip, stat cards) and provide the fastest possible path back into a reading session. After the redesign-reading-session-flow change, three explicit session-start entry points (For fun, To study, All currently reading) replace the prior detail-screen indirection — tapping a tile on Home starts a session in one tap.

## Requirements

### Requirement: Vertically scrolling single-feed layout

The Home tab SHALL present its content as a single vertically scrolling feed. The feed sections SHALL appear in this order from top to bottom: greeting, live counter, 7-day calendar strip, stat cards row, three session-start entry points (For fun, To study, All currently reading), Quote of the Day, Finished.

#### Scenario: Section ordering

- **WHEN** the user views the Home tab with content present
- **THEN** the sections are rendered in the order: greeting, live counter, 7-day strip, stat cards, For fun entry, To study entry, All currently reading entry, Quote of the Day, Finished

### Requirement: Time-of-day greeting

The greeting SHALL combine a part-of-day phrase ("Good morning", "Good afternoon", "Good evening") with the current weekday name (e.g., "Saturday"). Boundaries: morning is 04:00–11:59 local, afternoon is 12:00–17:59 local, evening is 18:00–03:59 local. The weekday SHALL reflect the user's current local calendar day.

#### Scenario: Morning greeting

- **WHEN** the user opens the app at 09:00 local time on a Saturday
- **THEN** the greeting reads "Good morning, Saturday"

#### Scenario: Evening greeting after midnight

- **WHEN** the user opens the app at 01:00 local time on a Sunday
- **THEN** the greeting reads "Good evening, Sunday"

### Requirement: Live "people reading now" counter

The dashboard SHALL display an estimated count of people currently reading, presented as a small subline beneath the greeting. The value SHALL change smoothly over time so that no two consecutive refreshes differ by more than a bounded delta. The value MUST be derivable on-device with no network call.

#### Scenario: Counter is visible

- **WHEN** the user views the Home tab
- **THEN** a "X people reading now" label is visible beneath the greeting where X is a positive integer

#### Scenario: Counter changes gradually

- **WHEN** the user observes the counter for at least 30 seconds without leaving the screen
- **THEN** the displayed value updates at least once
- **AND** no single update changes the value by more than 5% of its prior reading

### Requirement: 7-day calendar strip with progress rings

The strip SHALL render exactly seven day cells representing the last seven local-calendar days, oldest-first (left) to today (right). Each cell SHALL contain a circular progress ring showing reading time for that day relative to the user's daily reading-time goal. Today's cell SHALL be visually distinguished from the other six.

#### Scenario: Seven days are visible

- **WHEN** the user views the 7-day strip
- **THEN** seven day cells are rendered

#### Scenario: Today is highlighted

- **WHEN** the user views the 7-day strip
- **THEN** the rightmost cell represents today
- **AND** today's cell is visually distinguished (e.g., bold weekday label or accent-colored ring)

#### Scenario: Ring reflects reading-time progress

- **WHEN** a given day has 30 minutes logged and the daily goal is 60 minutes
- **THEN** that day's ring is filled to approximately 50% of its circumference

#### Scenario: Day with no activity

- **WHEN** a given day has zero minutes logged
- **THEN** that day's ring renders as an unfilled outline

### Requirement: Today's minutes stat card

A stat card SHALL show the count of minutes read today and the percentage change versus yesterday. A trend-direction arrow SHALL accompany the percentage: up arrow for positive change, down arrow for negative change, neutral indicator when change is zero or yesterday's value was zero.

#### Scenario: Positive day-over-day change

- **WHEN** today has 30 minutes and yesterday had 20 minutes
- **THEN** the card shows "30" minutes with "+50%" and an up arrow

#### Scenario: Negative day-over-day change

- **WHEN** today has 10 minutes and yesterday had 20 minutes
- **THEN** the card shows "10" minutes with "-50%" and a down arrow

#### Scenario: Yesterday had no reading

- **WHEN** yesterday had 0 minutes and today has any non-zero value
- **THEN** the card shows today's minute count with a neutral indicator and no percentage

### Requirement: Streak stat card

A stat card SHALL surface the user's current reading streak — the count of consecutive local-calendar days, ending today, on which any reading activity was logged. If today has no activity logged yet, the streak SHALL reflect days up to and including yesterday.

The card SHALL present two distinct visual treatments depending on streak length:

- **Below 7 days**: the card SHALL display the streak count as a single primary metric (e.g. "5 days").
- **7 days or more**: the card SHALL display **both** (a) a current-calendar-week visualization showing which days of the present calendar week have reading activity logged, and (b) a total-streak-days counter placed adjacent to the week visual. The "current calendar week" SHALL use `Calendar.autoupdatingCurrent` so it respects the user's first-weekday setting.

The transition between the two treatments SHALL be deterministic on streak length and SHALL NOT depend on any one-time flag.

#### Scenario: Active streak below the milestone

- **WHEN** the user has logged reading on each of the last 5 days including today
- **THEN** the streak card shows "5 days" as its primary metric
- **AND** no current-week visualization is rendered on the card

#### Scenario: No streak

- **WHEN** the user has not logged reading on any of the last 7 days
- **THEN** the streak card shows "0 days" as its primary metric
- **AND** no current-week visualization is rendered on the card

#### Scenario: Streak at the seven-day milestone

- **WHEN** the user has a current streak of exactly 7 days
- **THEN** the streak card shows a current-calendar-week visualization with each day of the present calendar week marked as having activity or not
- **AND** a total-streak counter reading "7 day streak" is shown adjacent to the week visualization

#### Scenario: Streak well past the milestone

- **WHEN** the user has a current streak of 23 days
- **THEN** the streak card shows the same current-calendar-week visualization
- **AND** the adjacent total-streak counter reads "23 day streak"

#### Scenario: Streak drops back below seven

- **WHEN** the user previously had a 9-day streak which broke yesterday and today's streak is 1
- **THEN** the streak card reverts to the single-metric treatment showing "1 day"
- **AND** no current-week visualization is rendered

### Requirement: For fun session-start entry

The dashboard SHALL render a "For fun" entry point that, when at least one in-progress book of attitude `.entertainment` exists, displays the most-recently-added such book and starts a reading session for that book on tap. When zero such books exist, the entry renders the "Add a book for fun" placeholder defined under "Empty states".

#### Scenario: One for-fun book

- **WHEN** the user has exactly one in-progress for-fun book and taps the For fun entry
- **THEN** a reading session is started for that book
- **AND** no detail screen is shown

#### Scenario: Multiple for-fun books

- **WHEN** the user has three in-progress for-fun books and taps the For fun entry
- **THEN** a reading session is started for the most-recently-added of the three
- **AND** the other two for-fun books are reachable through the "All currently reading" entry point

### Requirement: To study session-start entry

The dashboard SHALL render a "To study" entry point that, when at least one in-progress book of attitude `.study` exists, displays the most-recently-added such book and starts a reading session for that book on tap. When zero such books exist, the entry renders the "Add a book to study" placeholder defined under "Empty states".

#### Scenario: One study book

- **WHEN** the user has exactly one in-progress study book and taps the To study entry
- **THEN** a reading session is started for that book

#### Scenario: Multiple study books

- **WHEN** the user has two in-progress study books and taps the To study entry
- **THEN** a reading session is started for the most-recently-added of the two

### Requirement: All currently reading session-start entry

The dashboard SHALL render an "All currently reading" entry point that pushes a list of every in-progress book (regardless of attitude), ordered most-recently-added first. The pushed view SHALL allow tapping any row to start a reading session for that book. The pushed view SHALL also contain an explicit "+ Add a book" row that opens book search WITHOUT preselecting an attitude; the user SHALL be required to pick an attitude as part of adding the book.

#### Scenario: Tap a row starts a session

- **WHEN** the user opens "All currently reading" and taps a book row
- **THEN** a reading session is started for that book

#### Scenario: Add a book from the list prompts attitude

- **WHEN** the user taps "+ Add a book" inside the "All currently reading" view
- **THEN** book search opens with no attitude preselected
- **AND** the user is required to choose `.entertainment` or `.study` before the book can be saved

### Requirement: Finished section

The dashboard SHALL render a "Finished" section listing every book whose `isFinished` flag is true. Each row SHALL be rendered at the design system's standard button height, displaying the book's title (single line). The section SHALL be hidden entirely when no finished books exist. Tapping a Finished row SHALL be a no-op — no detail navigation, no menu, no other affordance.

#### Scenario: Finished books exist

- **WHEN** the user has at least one finished book
- **THEN** the Finished section is visible
- **AND** each row is rendered at standard button height with the book's title

#### Scenario: No finished books

- **WHEN** the user has zero finished books
- **THEN** the Finished section is not rendered

#### Scenario: Tapping a finished row does nothing

- **WHEN** the user taps a row in the Finished section
- **THEN** no navigation is pushed
- **AND** no sheet or menu is presented

### Requirement: Empty states

The dashboard SHALL render dedicated empty states when content is absent:
- When zero books exist in total, a top-level empty state SHALL replace the three entry-point sections and the Finished section, inviting the user to add their first book.
- When the user has zero books of attitude `.entertainment`, the For fun entry SHALL render an "Add a book for fun" placeholder that, when tapped, opens book search with attitude preset to `.entertainment`.
- When the user has zero books of attitude `.study`, the To study entry SHALL render an "Add a book to study" placeholder that, when tapped, opens book search with attitude preset to `.study`.
- These attitude-preset placeholders SHALL NOT appear once at least one book of the corresponding attitude exists.

#### Scenario: First-launch empty state

- **WHEN** the user opens the app and the library contains zero books
- **THEN** the dashboard shows an empty-state prompt to add the first book in place of the three entry-point sections and the Finished section

#### Scenario: Has study but no for-fun book

- **WHEN** the user has one in-progress study book and zero for-fun books
- **THEN** the For fun entry shows the attitude-preset "Add a book for fun" placeholder
- **AND** the To study entry shows the existing study book as a session-start CTA

#### Scenario: Placeholders disappear once filled

- **WHEN** the user adds a for-fun book via the "Add a book for fun" placeholder
- **THEN** the For fun entry replaces the placeholder with the new book as a session-start CTA
