## 1. Project setup & dependencies

- [x] 1.1 RevenueCat product linked to Craw target via direct pbxproj edit (PBXBuildFile + XCSwiftPackageProductDependency).
- [x] 1.2 Added REVENUECAT_PUBLIC_KEY directly to Craw/Info.plist with the DEBUG test key — deviates from the proposed build-setting approach for parity with how CLERK_PUBLISHABLE_KEY and CRAW_API_BASE_URL are stored. CI override should swap to xcconfig before release.
- [x] 1.3 Update `CLAUDE.md` "Required configuration" table to document the new `REVENUECAT_PUBLIC_KEY` key and its purpose.
- [x] 1.4 Update `PrivacyInfo.xcprivacy` with the RevenueCat SDK's required data-collection declarations (purchase history, device id). Reference RevenueCat's docs for the canonical entries.

## 2. AppEnvironment & SDK configuration

- [x] 2.1 Add `AppEnvironment.revenueCatPublicKey` matching the existing `clerkPublishableKey` pattern in `Craw/Auth/AppEnvironment.swift`: read from Info.plist, fall back to the DEBUG test key, assert in DEBUG, assert in RELEASE on empty.
- [x] 2.2 Add `AppEnvironment.makeSubscriptionStore()` factory that constructs the new `SubscriptionStore` (see §3).
- [x] 2.3 In `Craw/CrawApp.swift`, add a `private static func configureRevenueCat()` mirroring `configureClerk()`. Call it from `init()` after `configureClerk()`. Set log level to `.info` in DEBUG, `.warn` in RELEASE.
- [x] 2.4 Wire the new `subscriptionStore: SubscriptionStore` `@State` property in `CrawApp` and inject it via `.environment(subscriptionStore)` on the root `AuthGate`.

## 3. SubscriptionStore + entitlement model

- [x] 3.1 Create directory `Craw/Subscription/`. Add `SubscriptionEntitlement.swift` defining the `craw_pro` entitlement identifier and `default` offering identifier as constants.
- [x] 3.2 Add `SubscriptionStore.swift` as `@Observable @MainActor final class` with:
  - `enum Status: Equatable { case unknown, inactive, active(expiresAt: Date?), inGracePeriod, cancelled(expiresAt: Date) }`
  - `private(set) var status: Status = .unknown`
  - `private(set) var currentOffering: Offering?`
  - `func refresh() async`
  - `func identify(clerkUserID: String) async`
  - `func signOut() async`
  - `func purchase(_ package: Package) async throws`
  - `func restore() async throws`
- [x] 3.3 In `SubscriptionStore.init`, spawn a long-lived `Task` that subscribes to `Purchases.shared.customerInfoStream` and maps each `CustomerInfo` into a `Status` value via a private `Status.from(_:)` helper.
- [x] 3.4 In `Status.from(customerInfo:)`: read `entitlements[craw_pro]`; if missing → `.inactive`; if `isActive && willRenew` → `.active(expiresAt: …)`; if `isActive && !willRenew && expirationDate > now` → `.cancelled(expiresAt: …)`; if `periodType == .intro || .trial` and active → `.active`; if `inGracePeriod` → `.inGracePeriod`; else `.inactive`.
- [x] 3.5 `identify(clerkUserID:)` calls `Purchases.shared.logIn(clerkUserID)`, then `refresh()` (which fetches `offerings()` and updates `currentOffering`).
- [x] 3.6 `signOut()` calls `Purchases.shared.logOut()` and resets `status = .unknown`, `currentOffering = nil`.
- [x] 3.7 `purchase(_:)` wraps `Purchases.shared.purchase(package:)`. On success the customerInfo stream observer updates state; the method returns once the resulting `CustomerInfo` shows entitlement active.
- [x] 3.8 `restore()` wraps `Purchases.shared.restorePurchases()`.

## 4. AuthGate ↔ subscription wiring

- [x] 4.1 In `Craw/AppShell/AuthGate.swift`, read the new `subscriptionStore` from `@Environment(SubscriptionStore.self)`.
- [x] 4.2 Extend the existing `.onChange(of: clerk.user?.id)` handler in `AuthGate`: when `newID != nil`, kick off `Task { await subscriptionStore.identify(clerkUserID: newID!) }`; when `newID == nil`, kick off `Task { await subscriptionStore.signOut() }`.

## 5. API contract & models

- [x] 5.1 Extend `APIUser` in `Craw/Networking/APIModels.swift` with `let feedback: String?` and `let feedbackSubmittedAt: Date?`. Add `CodingKeys` for `feedback_submitted_at`.
- [x] 5.2 Add `APIFeedbackSubmission: Encodable { let feedback: String }`.
- [x] 5.3 api-contract.yaml deferred: the file only existed in the archived add-auth-and-book-search change. The contract changes for this work live in the auth spec delta at specs/auth/spec.md.
- [x] 5.4 In `Craw/Networking/CrawAPIClient.swift`, add `func submitFeedback(_ body: APIFeedbackSubmission) async throws -> APIUser`. Map 409 → a new `APIError.feedbackAlreadySubmitted` case.
- [x] 5.5 Add `func deleteAccount() async throws` to `CrawAPIClient` — DELETE to `/v1/users/me`, no body, treat 2xx as success.
- [x] 5.6 Add `AuthSessionStore.applyUpdatedUser(_:)` to swap the cached `APIUser` payload without re-running bootstrap. Update `BootstrapStatus.ready` accessors accordingly.

## 6. Paywall UI

- [x] 6.1 Create `Craw/Subscription/PaywallView.swift` — a `View` taking a binding for dismissal and observing `SubscriptionStore`. Layout per the design: hero title + subtitle, two Q&A blocks, primary CTA, restore link, footer with Terms/Privacy links.
- [x] 6.2 Add `PaywallViewModel.swift` (or inline `@Observable` state) handling the purchase/restore button states (`idle`, `purchasing`, `restoring`, `error`).
- [x] 6.3 Hardcode the two Q&A copy strings exactly as specified in the paywall spec (D4 of `design.md`).
- [x] 6.4 Render the CTA label using the current monthly package's `localizedPriceString` and period: e.g. "Subscribe — $4.99 / month".
- [x] 6.5 Add a `PaywallFallbackView` shown when `currentOffering == nil` — short copy + Close button. No purchase/restore buttons are present.
- [x] 6.6 Use existing design tokens (`Theme.Palette.rausch`, `Theme.Typography.*`, `Theme.Spacing.*`) and the `OnboardingPrimaryButton` style for the CTA.

## 7. Profile tab redesign

- [x] 7.1 Create directory `Craw/AppShell/ProfileTab/`. Move the current `ProfileTab.swift` into it. Split it into: `ProfileTab.swift` (container + state), `ProfileUserHeader.swift`, `ProfileSubscriptionRow.swift`, `ProfileDeveloperQuote.swift`, `ProfileFeedbackSection.swift`, `ProfileSignOutRow.swift`, `ProfileDeleteAccountRow.swift`, `LeaveFeedbackSheet.swift`.
- [x] 7.2 `ProfileTab.swift` becomes a thin container: reads `Clerk`, `AuthSessionStore`, `SubscriptionStore`, `CrawAPIClient`, presents the seven cards inside a `ScrollView { VStack(spacing: Theme.Spacing.lg) { … } }`.
- [x] 7.3 `ProfileSubscriptionRow.swift` reads `SubscriptionStore.status`. Renders shimmer on `.unknown`, "Subscribe / Unlock the full Craw experience" on `.inactive` (presents paywall sheet), "Subscription / renews <date>" on `.active`, "Subscription / cancelled, ends <date>" on `.cancelled`, "Subscription / billing retry" on `.inGracePeriod`. Tapping non-inactive states calls `AppStore.showManageSubscriptions(in: scene)`.
- [x] 7.4 `ProfileDeveloperQuote.swift` — borderless card with italicized body copy and a "— Misha" attribution. No tap action.
- [x] 7.5 `ProfileFeedbackSection.swift` — branches on `authSessionStore.cachedUser?.feedback`. If nil, show a "Leave feedback" pill button. If non-nil, show the static "Thank you for your feedback!" card.
- [x] 7.6 `LeaveFeedbackSheet.swift` — `NavigationStack { Form { Section { TextEditor(text: $text).frame(minHeight: 160) } } }` with Cancel/Send toolbar buttons. Send button disabled when `text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty`. Max 2 000 chars enforced via `onChange`. Tapping Send calls `apiClient.submitFeedback(...)`, then `authSessionStore.applyUpdatedUser(updated)` on success; on `.feedbackAlreadySubmitted` triggers `authSessionStore.bootstrapIfNeeded()` (forces a refresh) and dismisses; on any other error shows an inline error.
- [x] 7.7 `ProfileSignOutRow.swift` — destructive-colored row. Presents `.confirmationDialog("Sign out of Craw?", isPresented:)` with default "Sign out" + cancel buttons. Confirm path invokes the existing sign-out closure (unchanged from current behavior).
- [x] 7.8 `ProfileDeleteAccountRow.swift` — destructive-colored row. Presents `.confirmationDialog("Permanently delete your account?", titleVisibility: .visible, isPresented:)` with `Button("Delete account", role: .destructive)` + cancel. Confirm path calls a new local `deleteAccount()` async function.
- [x] 7.9 Implement `deleteAccount()` in `ProfileTab.swift`: (1) `try await apiClient.deleteAccount()`, (2) `try await Clerk.shared.user?.delete()`, (3) call `CrawModelContainer.wipeAllUserData(context:)`. Wrap in try/catch and show distinct inline errors per the auth spec scenarios.

## 8. SwiftData wipe utility

- [x] 8.1 Add `func wipeAllUserData(context: ModelContext) throws` to `Craw/Persistence/CrawModelContainer.swift`. Delete all `Book`, `ReadingDay`, `ReadingSession`, `SessionRetrospective`, `Quote`, `Thought` rows in a single transaction.

## 9. App Store Connect & RevenueCat dashboard (manual)

- [ ] 9.1 Create an auto-renewing subscription product in App Store Connect with id `com.mykhivanov.Craw.monthly`. Configure pricing, localized display name "Craw Monthly", and a short description.
- [ ] 9.2 In the RevenueCat dashboard, link the same product, create entitlement `craw_pro` mapped to the monthly product, and create offering `default` with one monthly package.
- [ ] 9.3 In App Store Connect, add the in-app purchase to the app's metadata for the next submission. Confirm sandbox testers can complete a test purchase.

## 10. Manual QA checklist

- [ ] 10.1 Cold-launch the app while signed in → Profile tab shows shimmer on subscription row briefly, then resolves to "Subscribe".
- [ ] 10.2 Tap "Subscribe" → paywall opens with two Q&A blocks, single CTA showing the monthly price, restore link, and footer.
- [ ] 10.3 Tap the CTA → Apple sheet appears, complete a sandbox purchase → paywall dismisses, subscription row updates to "Subscription / renews …".
- [ ] 10.4 Tap subscription row while active → Apple's manage-subscription sheet appears.
- [ ] 10.5 Tap "Restore purchases" with no prior purchase → inline error, paywall stays open.
- [ ] 10.6 Tap "Leave feedback" → sheet opens, Send is disabled until typing → submit → row collapses to "Thank you" card. Kill + relaunch → still shows the "Thank you" card.
- [ ] 10.7 Tap "Sign out" → confirmation dialog → confirm → routes back to auth screen.
- [ ] 10.8 Tap "Delete account" → destructive dialog → confirm → backend delete + Clerk delete + local SwiftData wipe → routes back to auth screen. Re-sign-in (or create a new account) → library is empty.
- [ ] 10.9 Force the backend delete endpoint to return 500 → inline error, user remains signed in, no Clerk delete fires.
- [ ] 10.10 Toggle to a network-offline state → tap Subscribe → paywall opens with fallback message if offerings fail to load.

## 11. Wrap-up

- [x] 11.1 Run `swiftformat` + `swiftlint` (handled automatically by the post-tool hook on edited files; verify no warnings).
- [x] 11.2 Build the app on iPhone 17 simulator with `xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 17' build`.
- [ ] 11.3 Self-review the diff against the proposal / design / specs. Flag any drift to the PR description.
- [ ] 11.4 When ready to archive, run `/opsx:archive add-subscription-and-profile-updates`.
