## MODIFIED Requirements

### Requirement: Profile tab exposes sign-out

The Profile tab SHALL contain a visible, labeled "Sign out" affordance styled as a destructive action (red text using `Theme.Palette.trendDown`). Tapping it SHALL present a confirmation dialog with the title "Sign out of Craw?" and two buttons: a default "Sign out" button that invokes the sign-out flow defined in the `auth` capability, and a "Cancel" button with the `.cancel` role. The user SHALL NOT be signed out without confirming.

#### Scenario: Sign-out affordance is visible

- **WHEN** the user navigates to the Profile tab
- **THEN** a row or button labeled "Sign out" is visible
- **AND** the row reads as a destructive action (red text per design tokens)

#### Scenario: Confirmation gate before sign-out

- **WHEN** the user taps the "Sign out" row
- **THEN** a confirmation dialog titled "Sign out of Craw?" is presented
- **AND** the dialog has a default "Sign out" button and a cancel button
- **AND** no sign-out network call is made before the user confirms

#### Scenario: Cancel keeps the user signed in

- **WHEN** the user dismisses the sign-out confirmation dialog by tapping Cancel
- **THEN** the Profile tab remains visible
- **AND** `Clerk.shared.auth.signOut()` is NOT invoked

## ADDED Requirements

### Requirement: Profile tab layout

The Profile tab SHALL render its content as a vertical stack of cards inside a `ScrollView`, in the following order from top to bottom: (1) user header (name + email from Clerk), (2) subscription status card, (3) developer thank-you quote, (4) feedback section, (5) sign-out row, (6) delete-account row. Each card SHALL use `Theme.Palette.surfaceCard`, the `Theme.Radius.card` corner radius, and a `Theme.Palette.hairlineSoft` 1pt stroke, with `Theme.Spacing.lg` between sections.

#### Scenario: Card ordering

- **WHEN** the user navigates to the Profile tab
- **THEN** the visible card order from top to bottom is: user header, subscription status, developer quote, feedback section, sign out, delete account

### Requirement: Subscription status card

The Profile tab SHALL render a subscription card that reflects `SubscriptionStore.status` from the `subscription` capability. While `status == .unknown` the card SHALL show a shimmer / loading state with no tap action. While `status == .inactive`, the card title SHALL read "Subscribe" with a subtitle "Unlock the full Craw experience" and tapping it SHALL present the paywall sheet. While `status` is `.active`, `.inGracePeriod`, or `.cancelled`, the card title SHALL read "Subscription" with a subtitle describing the current plan and renewal/expiration date, and tapping it SHALL open Apple's manage-subscription sheet.

#### Scenario: Inactive opens paywall

- **WHEN** the user taps the subscription card while `status == .inactive`
- **THEN** the paywall sheet is presented full-screen

#### Scenario: Active opens manage sheet

- **WHEN** the user taps the subscription card while `status == .active(expiresAt:)` or `.cancelled`
- **THEN** Apple's manage-subscription sheet is presented
- **AND** the paywall sheet is NOT presented

#### Scenario: Unknown shows loading

- **WHEN** `SubscriptionStore.status == .unknown`
- **THEN** the subscription card renders a loading placeholder
- **AND** taps do nothing

### Requirement: Developer thank-you quote

The Profile tab SHALL render a non-interactive quote card immediately below the subscription card. The card SHALL display a short thank-you message from the developer in italicized body type, attributed to "— Misha". The card SHALL NOT have a border stroke (visually distinguishing it as editorial copy, not an action).

#### Scenario: Quote is visible and inert

- **WHEN** the user navigates to the Profile tab
- **THEN** an italicized thank-you quote is visible below the subscription card
- **AND** taps on the quote have no effect

### Requirement: One-time feedback submission

The Profile tab SHALL render a feedback section whose appearance depends on whether the current `APIUser.feedback` is set. When `feedback == nil`, the section SHALL render a "Leave feedback" button that presents a sheet containing a multiline `TextEditor` (max 2 000 characters), a Cancel toolbar action, and a Send toolbar action disabled until the trimmed text is non-empty. When `feedback != nil`, the section SHALL render a static "Thank you for your feedback!" card with no edit or delete affordance. The Leave feedback button SHALL NOT be reachable once feedback has been submitted in the current session.

#### Scenario: First-time user sees the input affordance

- **WHEN** the Profile tab is rendered for a user whose `APIUser.feedback` is nil
- **THEN** a "Leave feedback" button is visible
- **AND** no "Thank you for your feedback!" card is visible

#### Scenario: Submitting feedback persists and locks the UI

- **WHEN** the user types a non-empty message into the feedback sheet
- **AND** taps Send
- **THEN** the client invokes the feedback submission endpoint from the `auth` capability
- **AND** on 2xx the cached `APIUser` is updated with the returned `feedback` value
- **AND** the Leave feedback button is replaced by the static "Thank you for your feedback!" card

#### Scenario: Returning user with prior feedback

- **WHEN** the Profile tab is rendered for a user whose `APIUser.feedback` is non-nil
- **THEN** the "Thank you for your feedback!" card is visible
- **AND** no Leave feedback button is rendered

#### Scenario: Send disabled on empty input

- **WHEN** the feedback sheet is presented with an empty `TextEditor`
- **THEN** the Send toolbar button is disabled
- **AND** typing whitespace only does not enable the button

### Requirement: Delete-account row

The Profile tab SHALL render a "Delete account" row beneath the sign-out row, styled as a destructive action (red text). Tapping it SHALL present a destructive confirmation dialog with a title indicating permanent data loss and two buttons: a `.destructive` "Delete account" button and a `.cancel` "Cancel" button. On confirmation, the account-deletion flow defined in the `auth` capability SHALL be invoked.

#### Scenario: Confirmation gate before deletion

- **WHEN** the user taps "Delete account"
- **THEN** a destructive confirmation dialog is presented
- **AND** the dialog explains that the action permanently deletes the account, library, and reading history
- **AND** no deletion request is sent until the user confirms

#### Scenario: Cancel keeps the account

- **WHEN** the user dismisses the delete-account dialog by tapping Cancel
- **THEN** no API call is made
- **AND** the user remains signed in
