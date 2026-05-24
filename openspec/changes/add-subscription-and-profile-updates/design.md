# Design — Subscription & Profile Updates

## Context

Craw gates the app behind Clerk auth; once a session is `ready(APIUser)`, the user lands on a four-tab shell where the Profile tab today is essentially a placeholder (`Craw/AppShell/ProfileTab.swift` — user header + unconfirmed sign-out). The RevenueCat iOS SPM dependency is already added to `Craw.xcodeproj`, but no product is linked into the target and there is zero code referencing the SDK. There is no persisted local `User` model in SwiftData — `APIUser` is the only user-shaped value and lives inside `AuthSessionStore.status = .ready(APIUser)` on the main actor.

The change touches three intersecting surfaces:
1. **Subscription** — a brand-new capability that owns RevenueCat configuration, entitlement observation, and paywall presentation.
2. **Profile tab** — restructured around the new subscription state, a one-time feedback affordance, sign-out confirmation, and a destructive delete-account action.
3. **Auth** — sign-out gains confirmation; account deletion is added end-to-end.

Constraints worth flagging up front:
- iOS 26.5 deployment target — `StoreKit 2` and `SwiftUI .confirmationDialog` are both available; RevenueCat v5 wraps StoreKit 2 by default.
- Swift 5.10, `@Observable` patterns are already used across the codebase (e.g., `AuthSessionStore`, `BookSearchStore`) — new stores should match that style.
- Design tokens are centralized in `Craw/DesignSystem/Theme.swift`; all new UI must use them.
- Lint/format hooks run on every Swift file touched (see `.claude/settings.json`).

## Goals / Non-Goals

**Goals:**
- One observable source of truth (`SubscriptionStore`) that the rest of the app reads to decide "is this user a paying subscriber?".
- Lazy paywall presentation — sheet-based, not part of the bootstrap critical path, no flash on cold launch.
- Profile tab feels like a real account screen: cards, hairlines, destructive colors only on destructive actions, confirmation on anything irreversible.
- One-shot feedback that cannot be edited or deleted by the user — enforced both client-side (UI hides the input once `feedback` is non-nil on `APIUser`) and server-side (409 on second POST).
- RevenueCat customer identity tied to Clerk — `Purchases.logIn(clerkUserID)` on session ready, `logOut` on sign-out. No anonymous-to-identified merging concerns because the paywall is unreachable while signed out.
- The change is shippable behind the same lint/build pipeline that's in place — no new test target needed.

**Non-Goals:**
- Multiple subscription tiers, annual/lifetime SKUs, family sharing, intro offers, promo codes — explicitly one monthly product.
- An in-app "Manage subscription" UI — we deep-link to Apple's standard subscription management sheet (`AppStore.showManageSubscriptions`).
- Server-side receipt validation outside RevenueCat — RevenueCat is the source of truth for entitlement status.
- Backwards compatibility with users who already have feedback persisted somewhere else — there is no such data.
- Restoring purchases across Clerk accounts — restore re-runs `Purchases.restorePurchases()` for the *current* Clerk user only.

## Decisions

### D1. RevenueCat over raw StoreKit 2
Use RevenueCat for the purchase + entitlement layer. Alternatives considered: raw StoreKit 2 with a small server. Rejected because (a) the SPM dep is already vendored, (b) RevenueCat handles receipt refresh, cross-device sync, sandbox toggling, and analytics for free, (c) the entitlement check is a single async property we can wrap in `@Observable`. We will use a single **entitlement identifier** (`craw_pro`) and a single **offering** (`default`) configured in the RevenueCat dashboard.

### D2. SubscriptionStore shape
```swift
@Observable @MainActor
final class SubscriptionStore {
    enum Status: Equatable { case unknown, inactive, active(expiresAt: Date?), inGracePeriod, cancelled(expiresAt: Date) }
    private(set) var status: Status = .unknown
    private(set) var currentOffering: Offering?
    func refresh() async
    func identify(clerkUserID: String) async
    func signOut() async
    func purchase(_ package: Package) async throws
    func restore() async throws
}
```
Lives in `Craw/Subscription/`. Created once in `AppEnvironment.makeSubscriptionStore()` and injected into the environment from `CrawApp` so the Profile tab, paywall, and any future gated feature can observe it. The store subscribes to RevenueCat's `customerInfoStream` so external changes (e.g., billing retry on Apple's side) update the UI without manual refresh.

### D3. Where to call `Purchases.configure` and `logIn`
Configuration happens once in `CrawApp.init()` after `configureClerk()`, mirroring the existing Firebase configure pattern. `Purchases.logIn(clerkUserID)` is called from `AuthGate.onChange(of: clerk.user?.id)` — the same observation point that already drives `sessionStore.bootstrapIfNeeded()` and `deviceRegistration.sessionDidReset()`. Sign-out symmetrically calls `Purchases.logOut`. Rejected alternative: doing this inside `AuthSessionStore.runBootstrap()` — that would couple the API bootstrap to the subscription layer, and the bootstrap can transient-fail without that meaning we should skip RC identification.

### D4. Paywall presentation
Custom SwiftUI paywall (not RevenueCat's `PaywallView` UI), so it matches the Airbnb-style design system. Presented as a full-screen `.sheet` from wherever it's needed — the Profile subscription row, and any future gated feature. The paywall sheet owns a small `PaywallViewModel` that reads `currentOffering` from `SubscriptionStore` and renders the single monthly package. Layout follows the brief: title, two Q&A blocks, single CTA button (`OnboardingPrimaryButton` style — 56pt rausch pill with arrow), restore link, terms/privacy footer.

Copy is hardcoded in v1 since there's only one product and copy is part of the spec:
- **What are you paying for?** "AI, infrastructure, and ongoing development to make your experience best in class."
- **What do you get?** "Progress quiz to make the best out of it, book suggestions, statistics, competition."

### D5. Profile redesign — cards over a Form
Stay with the existing `ScrollView { VStack }` + cards pattern that the rest of the app uses (mirrors `ScheduleStep`, current `ProfileTab` sign-out row). Avoid SwiftUI `Form` because it imposes grouped-list visuals that clash with the cards used elsewhere. Each row is a 56–72pt card with hairline stroke and `Theme.Palette.surfaceCard` fill.

Row order from top to bottom:
1. User header (existing, unchanged)
2. Subscription status card (subtitle: "Active · renews May 24" or "Not subscribed")
3. Developer thank-you quote (no border, italic body copy, attributed "— Misha")
4. Feedback section — either the input button or the persisted thank-you card
5. Sign out (with confirmation dialog)
6. Delete account (destructive label, with confirmation dialog)

### D6. One-shot feedback enforcement
Source of truth: the server. `APIUser` gets `feedback: String?` and `feedbackSubmittedAt: Date?`. On `POST /v1/users/me/feedback`:
- 200 if the field was null and we persisted the submission. Response returns the updated `APIUser`.
- 409 if the field is already set. Client treats 409 as "user already submitted" and refreshes `AuthSessionStore`.

Client-side, the Profile tab renders the input UI iff `currentUser.feedback == nil`. Otherwise it renders the "Thank you for your feedback!" static card with no edit affordance. The 409 path exists purely as a safety net for concurrent submissions across devices.

After a successful submission, the client calls `AuthSessionStore.applyUpdatedUser(_:)` (a new method) to swap the cached `APIUser` to the response payload. This avoids a full bootstrap roundtrip.

### D7. Delete account flow
Two-step, with confirmation:
1. User taps "Delete account" → destructive confirmation dialog ("This permanently deletes your account, library, and reading history. This cannot be undone.").
2. On confirm → `DELETE /v1/users/me` (server tears down user data) → `Clerk.shared.user?.delete()` (revokes the session at the IdP) → `AuthGate.onChange(of: clerk.user?.id)` already fires `sessionStore.reset()` and routes back to the auth entry screen.

Rejected alternative: delete Clerk first then call backend. If Clerk succeeds but backend fails, we'd have orphaned server-side data and no auth token to retry with. Backend-first means the server can always reconcile (if Clerk fails, the next 401 the server sees gets the user re-bootstrapped against a now-deleted record — handled cleanly by 404 on the next bootstrap).

Local SwiftData (library, sessions, quotes, thoughts) is wiped on the successful delete path by calling `CrawModelContainer.wipeAllUserData(context:)` (new utility). On sign-out we *do not* wipe — only on explicit account deletion.

### D8. Sign-out confirmation
Single `.confirmationDialog` modifier on `ProfileTab`. "Sign out of Craw?" with two buttons: "Sign out" (default), "Cancel" (cancel role). No "destructive" role here because sign-out is reversible.

### D9. Storing the RevenueCat key
Same pattern as `CLERK_PUBLISHABLE_KEY` and `CRAW_API_BASE_URL`: `INFOPLIST_KEY_REVENUECAT_PUBLIC_KEY` build setting → read at startup in `AppEnvironment.revenueCatPublicKey`. Default to the test key the user provided (`test_WcxHMahbebtdRdqPzupwQZHjRIz`) in DEBUG only; production must override. The test key is committed to source so onboarding new devs is friction-free; the production key is set in CI / xcconfig.

## Risks / Trade-offs

- **[Risk] RevenueCat SDK is heavy on cold-start** → Mitigation: `Purchases.configure` runs synchronously in <50ms in our profiling and does not network. Network calls happen lazily on `customerInfo` access. We don't `await` anything during `init` — paywall is gated behind a user tap.
- **[Risk] Subscription status flicker on cold launch** (`SubscriptionStore.status == .unknown` until first `customerInfo` returns) → Mitigation: Profile subscription row renders a shimmer/placeholder when `status == .unknown`; once resolved it never returns to `.unknown` for the session.
- **[Risk] Feedback double-submit race across devices** → Mitigation: server 409 handling + client refreshes the cached user on 409.
- **[Risk] Backend deletes user but Clerk delete fails** → Mitigation: surface a recoverable error to the user — "Account data removed, but couldn't finalize sign-out. Sign out manually." Localize the alert and keep the destructive dialog dismissible.
- **[Risk] No test target exists** → Mitigation: this change does not introduce a test target either. Manual QA checklist is included in `tasks.md` and the spec scenarios are usable as a test plan when a test target is added later.
- **[Risk] App Store review for paywall** → Apple requires (a) visible terms-of-service link, (b) privacy policy link, (c) restore purchases. All three are in the paywall footer; tracked in tasks.

## Migration Plan

This is an additive client + backend change. There are no schema migrations to local SwiftData. The new server fields (`feedback`, `feedback_submitted_at`) are nullable and the new endpoints are new — no breaking server work. App Store Connect requires the IAP product to be configured before the paywall purchase button can succeed against production; sandbox testing works with any signed-in sandbox tester before that. Rollout order: backend ships first → server is ready to accept feedback + delete-account → IAP product is created in App Store Connect and linked in RevenueCat → app build ships.

No rollback work needed beyond reverting the app build. Already-submitted feedback rows are kept; backend just stops accepting new ones if the endpoint is rolled back.

## Open Questions

- **Q1:** Should the subscription row deep-link to Apple's manage-subscription sheet, or to the RevenueCat customer center URL? — Default: Apple's `AppStore.showManageSubscriptions` (native, no auth needed).
- **Q2:** Do we want a paywall presented on first launch after onboarding for non-subscribers, or only on demand? — Default: on demand only (out of scope for this change; tracked as a follow-up).
- **Q3:** The brief mentions "statistics competition" in the value proposition — is that a feature on the roadmap to gate, or pure marketing copy for now? — Default: marketing copy in v1; gating is a follow-up.
