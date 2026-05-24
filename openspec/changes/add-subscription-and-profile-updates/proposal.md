# Add subscription and profile updates

## Why

The Profile tab today is a placeholder: a header and an unconfirmed "Sign out" button. There is no way for a reader to leave feedback, no way to remove their account, no destructive-action safety, and no surface for the upcoming paid plan. At the same time, Craw needs a single monthly subscription to fund AI features, infrastructure, and ongoing development — and the RevenueCat SPM dependency is already vendored into the Xcode project but not yet wired in. This change brings both pieces of work together: it turns the Profile tab into a real account screen and introduces the paywall + monthly subscription that the new "Subscription" row points to.

## What Changes

- Add a paywall sheet driven by RevenueCat, presenting a single monthly subscription product, two Q&A blocks ("What are you paying for?" / "What do you get?"), purchase + restore actions, and standard terms/privacy footers.
- Wire RevenueCat into app startup using the configured public SDK key, scoped per-user via Clerk's stable user id (`Purchases.shared.logIn` on session ready, `logOut` on sign-out).
- Expose subscription state through an observable `SubscriptionStore` consumed by SwiftUI. The store distinguishes `unknown / inactive / active / inGracePeriod / cancelled`.
- Redesign the Profile tab as a stacked card layout containing, in order: user header, **Subscription status** row (taps open paywall when inactive, opens "Manage subscription" when active), developer thank-you quote, **Leave feedback** affordance (one-time), **Sign out** (with confirmation), **Delete account** (destructive, with confirmation).
- Add a "Leave feedback" sheet with a multiline text editor (max 2 000 chars). Submitting POSTs to the backend; the feedback is one-shot — once persisted, the Profile tab shows a static "Thank you for your feedback!" card with no edit/delete affordance.
- Extend `APIUser` and the auth-session bootstrap contract with a `feedback` field (nullable string + submitted-at timestamp), and add a `POST /v1/users/me/feedback` endpoint (idempotent — 409 if already submitted).
- Add an account-deletion flow: `DELETE /v1/users/me` on the backend, plus `Clerk.shared.user?.delete()` on the client. Confirmation dialog is required.
- Add a sign-out confirmation dialog to the existing sign-out button.

## Capabilities

### New Capabilities

- `subscription`: RevenueCat-backed monthly subscription, paywall presentation, subscription-status observation, restore-purchases, and manage-subscription deep link.

### Modified Capabilities

- `app-shell`: Profile tab is no longer a placeholder — it gains a subscription row, developer quote + one-time feedback, sign-out confirmation, and a delete-account affordance. The "Profile tab exposes sign-out" requirement is tightened to require a confirmation dialog.
- `auth`: Sign-out gains a client-side confirmation step before invoking `Clerk.shared.auth.signOut()`. A new account-deletion requirement is added that calls the backend delete endpoint, then `Clerk.shared.user?.delete()`, and routes the gate back to the auth entry screen.

## Impact

- **Code (new)**: `Craw/Subscription/` — `SubscriptionStore.swift`, `SubscriptionEntitlement.swift`, `PaywallView.swift`, `PaywallViewModel.swift`, `RevenueCatConfigurator.swift`. `Craw/AppShell/ProfileTab/` — split `ProfileTab.swift` into `ProfileTab.swift`, `ProfileSubscriptionRow.swift`, `ProfileFeedbackSection.swift`, `ProfileDeleteAccountButton.swift`, `LeaveFeedbackSheet.swift`.
- **Code (modified)**: `CrawApp.swift` (RevenueCat configure), `AuthGate.swift` (Purchases logIn/logOut on session change), `Auth/AppEnvironment.swift` (store factory), `Networking/APIModels.swift` (`feedback` on `APIUser`), `Networking/CrawAPIClient.swift` (new submitFeedback, deleteAccount methods), `AppShell/ProfileTab.swift` (rewritten).
- **Dependencies**: RevenueCat SPM (`purchases-ios-spm`) is already vendored; activate by adding the `RevenueCat` product to the Craw target.
- **Config**: New `Info.plist` build setting `INFOPLIST_KEY_REVENUECAT_PUBLIC_KEY`. Setup steps documented in `CLAUDE.md`.
- **Backend / API contract**: extend the User resource with `feedback`, add `POST /v1/users/me/feedback`, add `DELETE /v1/users/me`. Update `openspec/changes/add-auth-and-book-search/api-contract.yaml` (or, post-archive, the live `auth` spec).
- **App Store**: an IAP product must be configured in App Store Connect (suggested id `com.mykhivanov.Craw.monthly`) and linked to the RevenueCat dashboard. Out of scope for code review but listed in `tasks.md` as a manual step.
- **Privacy / data**: `PrivacyInfo.xcprivacy` may need updates for the RevenueCat SDK's data collection (purchase, device id). Tracked as a follow-up task.
