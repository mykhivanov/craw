## ADDED Requirements

### Requirement: Root tab-based navigation

The app SHALL present a root `TabView` with exactly four tabs in this order: Home, Quotes, Stats, Profile. The Home tab SHALL be selected on first launch and on every cold start until tab-state restoration is introduced.

#### Scenario: Cold launch lands on Home

- **WHEN** the user opens the app from a closed state
- **THEN** the Home tab is the selected tab
- **AND** the Home dashboard is visible

#### Scenario: All four tabs are present

- **WHEN** the user views the tab bar
- **THEN** the tab bar shows four tabs labeled Home, Quotes, Stats, Profile in that order
- **AND** each tab has a distinct SF Symbol icon

### Requirement: Selected-tab tint uses brand accent

The tab bar's selected-state foreground color SHALL be the Rausch accent (`#ff385c`) as defined in `DESIGN.md`. Unselected tabs SHALL use the muted ink color from the design tokens.

#### Scenario: Active tab indicator

- **WHEN** any tab is the currently selected tab
- **THEN** its icon and label render in the Rausch accent color
- **AND** non-selected tabs render in the muted color

### Requirement: Per-tab navigation isolation

Each tab SHALL host its own `NavigationStack` so push navigation within one tab does not affect the navigation state of another tab. Switching tabs SHALL preserve each tab's navigation state for the duration of the app session.

#### Scenario: Pushed view persists when switching away and back

- **WHEN** the user pushes a detail view inside Home, switches to Stats, and switches back to Home
- **THEN** the previously pushed detail view is still visible

### Requirement: Placeholder destinations for non-Home tabs

The Quotes, Stats, and Profile tabs SHALL each render a placeholder view containing the tab name and a short "coming soon" message. Placeholder views SHALL be replaced by later changes and MUST NOT contain interactive behavior beyond rendering.

#### Scenario: Quotes tab placeholder

- **WHEN** the user selects the Quotes tab
- **THEN** a placeholder screen is shown identifying the Quotes feature as not yet implemented

#### Scenario: Stats tab placeholder

- **WHEN** the user selects the Stats tab
- **THEN** a placeholder screen is shown identifying the Stats feature as not yet implemented

#### Scenario: Profile tab placeholder

- **WHEN** the user selects the Profile tab
- **THEN** a placeholder screen is shown identifying the Profile feature as not yet implemented
