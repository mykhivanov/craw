## ADDED Requirements

### Requirement: Vertically scrolling single-feed layout

The Home tab SHALL present its content as a single vertically scrolling feed. The feed sections SHALL appear in this order from top to bottom: greeting, live counter, 7-day calendar strip, stat cards row, Reading Now, Finished.

#### Scenario: Section ordering

- **WHEN** the user views the Home tab with content present
- **THEN** the sections are rendered in the order: greeting, live counter, 7-day strip, stat cards, Reading Now, Finished

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

### Requirement: Today's pages stat card

A stat card SHALL show the count of pages read today and the percentage change versus yesterday. A trend-direction arrow SHALL accompany the percentage: up arrow for positive change, down arrow for negative change, neutral indicator when change is zero or yesterday's value was zero.

#### Scenario: Positive day-over-day change

- **WHEN** today has 30 pages and yesterday had 20 pages
- **THEN** the card shows "30" pages with "+50%" and an up arrow

#### Scenario: Negative day-over-day change

- **WHEN** today has 10 pages and yesterday had 20 pages
- **THEN** the card shows "10" pages with "-50%" and a down arrow

#### Scenario: Yesterday had no reading

- **WHEN** yesterday had 0 pages and today has any non-zero value
- **THEN** the card shows today's page count with a neutral indicator and no percentage

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

### Requirement: Reading Now section

The dashboard SHALL render a "Reading Now" section listing every book currently in progress. Each row SHALL display the book's cover (or a placeholder when no cover is set), title, author, and a progress bar representing pages-read / total-pages. The section header SHALL contain an add-book affordance.

#### Scenario: Multiple in-progress books

- **WHEN** the user has two in-progress books
- **THEN** the Reading Now section lists both books
- **AND** each row shows cover, title, author, and a progress bar

#### Scenario: Add-book affordance is present

- **WHEN** the user views the Reading Now section
- **THEN** the section header contains an add-book button

### Requirement: Finished section

The dashboard SHALL render a "Finished" section listing every book whose status is finished. Each row SHALL display the book's cover, title, and author. The section SHALL be hidden entirely when no finished books exist.

#### Scenario: Finished books exist

- **WHEN** the user has at least one finished book
- **THEN** the Finished section is visible and lists each finished book

#### Scenario: No finished books

- **WHEN** the user has zero finished books
- **THEN** the Finished section is not rendered

### Requirement: Empty states

The dashboard SHALL render dedicated empty states when content is absent:
- When zero books exist in total, a top-level empty state SHALL replace both Reading Now and Finished sections, inviting the user to add their first book.
- When books exist but none are in-progress, the Reading Now section SHALL display a "nothing on your nightstand" empty message that still contains the add-book affordance.

#### Scenario: First-launch empty state

- **WHEN** the user opens the app and the library contains zero books
- **THEN** the dashboard shows an empty-state prompt to add the first book in place of the Reading Now and Finished sections

#### Scenario: Library has only finished books

- **WHEN** the user has one or more finished books and zero in-progress books
- **THEN** the Reading Now section shows an empty-state message
- **AND** the Finished section renders normally

### Requirement: Tappable book rows route to detail

Tapping a row in either Reading Now or Finished SHALL push a book-detail destination onto the Home tab's navigation stack. The detail view's full content is owned by a later change; this change SHALL render a minimal detail placeholder showing the book's title.

#### Scenario: Tap on in-progress book

- **WHEN** the user taps a book row in Reading Now
- **THEN** a detail view for that book is pushed onto the Home navigation stack
