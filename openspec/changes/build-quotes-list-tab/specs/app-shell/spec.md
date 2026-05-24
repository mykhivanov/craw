## MODIFIED Requirements

### Requirement: Placeholder destinations for non-Home tabs

The Stats and Profile tabs SHALL each render a placeholder view containing the tab name and a short "coming soon" message. The Quotes tab SHALL NOT render a placeholder; it SHALL render the cross-book quotes list defined by the `quotes-and-thoughts` capability. Placeholder views SHALL be replaced by later changes and MUST NOT contain interactive behavior beyond rendering.

#### Scenario: Quotes tab hosts the real quotes list

- **WHEN** the user selects the Quotes tab
- **THEN** the cross-book quotes list view defined by `quotes-and-thoughts` is rendered
- **AND** no "coming soon" placeholder is shown

#### Scenario: Stats tab placeholder

- **WHEN** the user selects the Stats tab
- **THEN** a placeholder screen is shown identifying the Stats feature as not yet implemented

#### Scenario: Profile tab placeholder

- **WHEN** the user selects the Profile tab
- **THEN** a placeholder screen is shown identifying the Profile feature as not yet implemented
