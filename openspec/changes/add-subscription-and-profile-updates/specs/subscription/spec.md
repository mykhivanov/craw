## ADDED Requirements

### Requirement: RevenueCat SDK initialization

The app SHALL configure the RevenueCat SDK exactly once at process start by calling `Purchases.configure(withAPIKey:appUserID:)` immediately after Clerk configuration. The API key SHALL be read from `Info.plist["REVENUECAT_PUBLIC_KEY"]` via `AppEnvironment.revenueCatPublicKey`. In DEBUG builds, if the key is missing, the app SHALL fall back to the embedded test key; in RELEASE builds, a missing key SHALL trigger an assertion. RevenueCat log level SHALL be `.info` in DEBUG and `.warn` in RELEASE.

#### Scenario: First-launch initialization

- **WHEN** the app launches for the first time
- **THEN** `Purchases.configure` is called before any view that observes subscription state is rendered
- **AND** the configured API key is the value of `REVENUECAT_PUBLIC_KEY` from Info.plist

#### Scenario: Missing key in RELEASE

- **WHEN** the app is built without `REVENUECAT_PUBLIC_KEY` in a RELEASE configuration
- **THEN** an assertion fires at launch
- **AND** the app does not silently default to the DEBUG test key

### Requirement: Customer identity tracks Clerk session

The system SHALL keep RevenueCat's app user id synchronized with the active Clerk user id. When `Clerk.shared.user?.id` transitions from `nil` to a non-nil value, the app SHALL call `Purchases.shared.logIn(clerkUserID)`. When it transitions back to `nil`, the app SHALL call `Purchases.shared.logOut()`. These calls SHALL happen on the main actor and SHALL NOT block UI presentation.

#### Scenario: Sign-in identifies the customer

- **WHEN** a user signs in via Clerk
- **AND** `Clerk.shared.user?.id` becomes non-nil
- **THEN** `Purchases.shared.logIn(clerkUserID)` is invoked exactly once
- **AND** `SubscriptionStore.identify(clerkUserID:)` is awaited as part of the same flow

#### Scenario: Sign-out resets the customer

- **WHEN** the user signs out
- **AND** `Clerk.shared.user` becomes nil
- **THEN** `Purchases.shared.logOut()` is invoked
- **AND** `SubscriptionStore.status` returns to `.unknown` on the next observer read

### Requirement: SubscriptionStore observable state

The system SHALL expose a `@MainActor @Observable` `SubscriptionStore` injected into the SwiftUI environment. The store SHALL publish a `status` value of one of: `unknown`, `inactive`, `active(expiresAt:)`, `inGracePeriod`, `cancelled(expiresAt:)`. The store SHALL subscribe to RevenueCat's `customerInfoStream` so external entitlement changes are reflected without a manual refresh. The store SHALL expose the current `Offering` for the configured monthly product as `currentOffering`.

#### Scenario: Active entitlement maps to .active

- **WHEN** RevenueCat reports the `craw_pro` entitlement as active with an expiration date
- **THEN** `SubscriptionStore.status` is `.active(expiresAt: <date>)`

#### Scenario: Cancelled but still in paid period

- **WHEN** RevenueCat reports the `craw_pro` entitlement as `willRenew == false` and `expirationDate > now`
- **THEN** `SubscriptionStore.status` is `.cancelled(expiresAt: <date>)`

#### Scenario: Stream-driven update

- **WHEN** RevenueCat pushes a new `CustomerInfo` over `customerInfoStream` while the app is foregrounded
- **THEN** `SubscriptionStore.status` updates within one runloop without any explicit `refresh()` call

### Requirement: Paywall presentation

The system SHALL provide a `PaywallView` that can be presented from any screen as a full-screen sheet. The paywall SHALL render the configured monthly product from `currentOffering` and SHALL be unreachable when no offering is loaded — instead a one-line "Subscriptions are temporarily unavailable" message is shown with a Close button. The paywall SHALL contain:

- A title and a short subtitle.
- Two Q&A blocks. The first Q reads "What are you paying for?" with the answer "AI, infrastructure, and ongoing development to make your experience best in class." The second Q reads "What do you get?" with the answer "Progress quiz to make the best out of it, book suggestions, statistics, competition."
- A single primary CTA button labeled with the monthly price (e.g., "Subscribe — $4.99 / month") that initiates `Purchases.shared.purchase(package:)`.
- A "Restore purchases" text button.
- Footer text "Subscription auto-renews monthly. Cancel anytime in Settings." plus links labeled "Terms" and "Privacy".

#### Scenario: Paywall renders the monthly product

- **WHEN** the paywall is presented while `currentOffering` exposes a monthly package priced at $4.99
- **THEN** the CTA button label includes "$4.99" and "month"
- **AND** the two Q&A blocks render with the exact copy specified above

#### Scenario: Paywall with no offering

- **WHEN** the paywall is presented while `currentOffering` is nil
- **THEN** a fallback message and Close button are shown
- **AND** no purchase or restore action is callable

#### Scenario: Restore purchases

- **WHEN** the user taps "Restore purchases"
- **THEN** `Purchases.shared.restorePurchases()` is invoked
- **AND** on success, the paywall is dismissed if the entitlement is active
- **AND** on failure, an inline error is shown without dismissing the paywall

### Requirement: Purchase flow

When the user taps the CTA, the system SHALL call `Purchases.shared.purchase(package:)` and present Apple's standard purchase sheet. On `userCancelled`, the paywall SHALL remain visible with no error displayed. On any other error, an inline error message SHALL be shown. On success, the paywall SHALL dismiss and `SubscriptionStore.status` SHALL transition to `.active` before the dismiss completes.

#### Scenario: Successful purchase

- **WHEN** the user completes the purchase sheet
- **THEN** RevenueCat returns a transaction with the `craw_pro` entitlement active
- **AND** `SubscriptionStore.status` becomes `.active(expiresAt: <date>)`
- **AND** the paywall sheet dismisses

#### Scenario: User cancels purchase

- **WHEN** the user dismisses Apple's purchase sheet without buying
- **THEN** no error is surfaced
- **AND** the paywall sheet remains visible

#### Scenario: Purchase fails

- **WHEN** `Purchases.shared.purchase` throws a non-cancellation error
- **THEN** an inline error message describing the failure is shown on the paywall
- **AND** the CTA returns to its idle state

### Requirement: Manage active subscription via Apple

When a subscription is active or in grace period, the system SHALL provide a "Manage subscription" affordance that opens Apple's native manage-subscription sheet via `AppStore.showManageSubscriptions(in:)` from the current scene. The app SHALL NOT attempt to cancel the subscription itself, since cancellation is owned by the App Store.

#### Scenario: Manage opens Apple sheet

- **WHEN** the user taps "Manage subscription" on an active plan
- **THEN** Apple's standard manage-subscription sheet is presented
- **AND** no Craw-owned cancellation UI is shown
