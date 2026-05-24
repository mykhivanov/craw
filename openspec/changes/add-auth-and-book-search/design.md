## Context

Craw is a SwiftUI iOS/iPadOS app (iOS 26.5 deployment target, Swift 5.10) that stores all data locally via SwiftData. Recent commits added the home dashboard, week strip, stats, and a full session-tracking pipeline — all local. There is no user identity, no network code, no API key handling, and no SwiftPM dependencies.

This change adds the first network surface and ties it to a Clerk-managed identity. The product decision is that the app should not be usable without sign-in: every backend call (search today, sync tomorrow) must be authenticated, so an unauthenticated launch should not reach the dashboard at all.

The custom API at `https://api.craw.app/v1` is greenfield — this change defines its contract in `api-contract.yaml`. The app and backend will be co-developed; specs lock the contract on the app side. Backend implements the Google Books integration server-side (we own the API key there, we control caching, we can pivot away from Google Books without an app update).

## Goals / Non-Goals

**Goals:**
- A user lands on the auth entry screen on first cold launch and after sign-out; subsequent cold launches with a valid Clerk session restore directly to the dashboard.
- Every outbound request to `api.craw.app` carries a fresh Clerk JWT in the `Authorization` header.
- The API contract is complete enough that backend work for *all* current app features can begin in parallel, even though only `/v1/books/search` is consumed in this change.
- The networking layer is testable: `CrawAPIClient` depends on `URLSession` and an `AuthTokenProvider` protocol; both can be mocked.
- Sign-out returns to the auth screen without crashing in-flight requests (cancellation is graceful).

**Non-Goals:**
- No biometric (Face ID / Touch ID) unlock layer in front of Clerk — Clerk handles its own session lifetime.
- No multi-account / account switching UI.
- No offline mode — when offline, search shows an error; library writes still go to local SwiftData only.
- No cross-device sync in this change (contract is documented, endpoints not consumed).
- No backend implementation (lives in a separate repo).
- No password-reset / email-verification UX beyond what Clerk's `AuthView` provides out of the box.

## Decisions

### Auth: Clerk iOS SDK, with `AuthView` for sign-in UI
**Decision:** Add `https://github.com/clerk/clerk-ios` via SwiftPM. Configure once in `CrawApp.init`:
```swift
Clerk.configure(
    publishableKey: Bundle.main.infoDictionary?["CLERK_PUBLISHABLE_KEY"] as? String ?? "",
    options: .init(redirectConfig: .init(
        redirectUrl: "com.mykhivanov.Craw://clerk-callback",
        callbackUrlScheme: "com.mykhivanov.Craw"
    ))
)
```
Inject via `.environment(Clerk.shared)` at the scene root. Use the prebuilt `AuthView(mode: .signInOrUp, isDismissable: false)` for sign-in — no custom auth UI in v1.

**Why:** Clerk owns the painful surface area (email-link, OAuth callbacks, MFA, password rules). The SDK exposes an `@Observable Clerk` with `isLoaded`, `session`, and `user` — exactly what we need to drive the SwiftUI gate.

**Alternatives considered:**
- *Sign in with Apple only* — single-provider lock-in; many users prefer email/password.
- *Roll our own auth* — months of work for a sub-par result.
- *Auth0 / Firebase Auth* — comparable, but Clerk's SwiftUI components are unmatched today.

### Auth gate: a single `AuthGate` view at the scene root
**Decision:** Wrap the existing `RootView` in an `AuthGate` that switches between three states:
- `clerk.isLoaded == false` → `SplashView` (logo + spinner).
- `clerk.isLoaded == true && clerk.user == nil` → `AuthView(isDismissable: false)`.
- `clerk.isLoaded == true && clerk.user != nil` → existing `RootView`.

```
App launch
   │
   ▼
Clerk.configure (returns immediately, isLoaded == false)
   │
   ▼
SplashView ── isLoaded == true ──▶ user != nil ?
                                       │
                              ┌────────┴────────┐
                              │                 │
                            yes               no
                              │                 │
                              ▼                 ▼
                         RootView           AuthView (full-screen, not dismissable)
                       (TabView)                 │
                              ▲                 │ sign-in success
                              └─────────────────┘
                              ▲
                              │ sign-out → user becomes nil → gate re-evaluates → AuthView
```

**Why:** Keeps `RootView` and every tab unaware of auth state. Sign-out anywhere in the app reliably returns to the entry screen because `clerk.user` becomes nil and the gate re-evaluates.

**Alternatives considered:**
- *Conditional in `CrawApp.body`* — mixes concerns; harder to preview.
- *Programmatic navigation* — fragile; SwiftUI prefers state-driven branching.

### API client: a single actor, token-provider injected
**Decision:** `CrawAPIClient` is an `actor` exposing typed methods that match the `operationId`s declared in `api-contract.yaml` (`bootstrapSession`, `getCurrentUser`, `updateCurrentUser`, `deleteCurrentUser`, `searchBooks`, `getBookQuiz`). It depends on:
```swift
protocol AuthTokenProvider: Sendable {
    func currentToken() async throws -> String
}
```
`ClerkAuthTokenProvider` implements this with `Clerk.shared.auth.getToken()` (which auto-refreshes when < 10 s remain on the JWT). Every request goes through a single `perform<Req, Res>(_:)` helper that:
1. Builds the `URLRequest` from a `RequestSpec` (path, method, query, body).
2. Calls `currentToken()` and attaches `Authorization: Bearer <token>`.
3. On HTTP 401, invalidates the cached token (`skipCache: true`) and retries **once**.
4. Decodes 2xx as `Res`, decodes 4xx/5xx as `APIErrorBody`, maps to a typed `APIError`.

**Why:** One choke point for auth, retry, logging, and error mapping — every future endpoint inherits these properties for free. Actor isolation gives us safe concurrent calls.

**Alternatives considered:**
- *Generic `Networking` package* — premature; we have one consumer.
- *Combine pipeline* — not used elsewhere in the codebase.

### Error model
**Decision:** Single `APIError` enum: `.unauthorized`, `.notFound`, `.rateLimited(retryAfter: TimeInterval?)`, `.server(message: String, code: String?)`, `.network(URLError)`, `.decoding(Error)`, `.cancelled`. The UI maps cases to one-line messages; technical detail is kept in `os.Logger`.

### Search flow
**Decision:** Replace last revision's `GoogleBooksClient` with a call to our backend:
```
GET /v1/books/search?q=<query>&limit=20&offset=0
```
Response is a normalized list (see the `searchBooks` operation and `BookSearchResponse` schema in `api-contract.yaml`). The store, debounce, pagination, dedupe, and state machine stay as previously designed; only the HTTP target changes.

**Why:** Server-side proxy means (1) we hide the Google Books API key, (2) we can swap providers without an app update, (3) we get a uniform error / response shape across all endpoints, (4) we can layer caching and rate-limiting centrally.

### Persistence: extend `Book`, add `remoteID`
**Decision:** Add three optional fields to `@Model class Book`:
- `coverImageURL: URL?`
- `isbn: String?`
- `remoteID: String?` — the backend's stable book ID returned by search. Lets future sync reconcile local-vs-server records without ISBN ambiguity.

**Why:** SwiftData handles additive optional fields with automatic lightweight migration. `remoteID` is forward-compatible — set it now, even though no sync code consumes it yet.

### Sign-out
**Decision:** Profile-tab gains a "Sign out" row that calls `try await Clerk.shared.auth.signOut()`. Local SwiftData is **not** wiped on sign-out — books and sessions persist locally because v1 has no notion of "this device belongs to user X". A future sync change will introduce a per-user partition; for now treat sign-out as ending the API session, not clearing the device.

**Risk:** A second user signing in on the same device sees the first user's local books. → **Mitigation:** call this out in `api-contract.yaml`'s "Library reads, writes, and local-data semantics" section (in `info.description`) and accept it as a known limitation for v1. Add a follow-up change `add-multi-user-data-isolation` when sync arrives.

### Splash / loading UX
**Decision:** `SplashView` is the app logo on the canvas background with a `ProgressView`. No timer — it shows for exactly as long as `clerk.isLoaded == false`, typically < 200 ms after warm starts.

## Risks / Trade-offs

- **Risk:** Clerk session restore is slow on cold launch (rare, but observed in the wild). → **Mitigation:** the splash hides any flicker; on real devices typical restore is 50–150 ms.
- **Risk:** First-time release will be rejected if `PrivacyInfo.xcprivacy` is missing or wrong. → **Mitigation:** add the manifest in this change, include the network domains (`api.craw.app`, `clerk.com`, `clerk.dev`, `*.clerk.accounts.dev`) and data classes ("Search History", "Email Address", "Name", "User ID"). Cross-reference with Clerk's published required-reasons list.
- **Risk:** Token refresh races — two concurrent requests could both see an expired token and both refresh. → **Mitigation:** `Clerk.shared.auth.getToken()` is documented to deduplicate concurrent refreshes internally; we trust the SDK and don't layer our own lock.
- **Risk:** Sign-out doesn't clear local SwiftData (above). → **Mitigation:** documented limitation, planned follow-up.
- **Risk:** Custom backend isn't deployed by the time this change is implemented. → **Mitigation:** the `BookSearchService` protocol allows pointing the search store at a `MockBookSearchService` in DEBUG via a launch argument, so UI work isn't blocked.
- **Trade-off:** Hard gate (no anonymous browsing) means users can't even see the seeded sample books without signing in. We accept this; the product is identity-first.

## Migration Plan

1. **SwiftPM:** add `clerk-ios` via Xcode → File → Add Package Dependencies (or by editing `project.pbxproj` once; the rest of the package is consumed via `import ClerkKit` / `import ClerkKitUI`).
2. **Schema migration:** additive optional properties on `Book` — SwiftData handles automatically. Verify by launching with previously seeded data.
3. **Rollout:** single release. There is no feature flag because the auth gate is the launch state — flagging it would mean shipping two code paths.
4. **Rollback:** if a launch-blocking auth bug ships, revert the wrapping of `RootView` by `AuthGate` (one-line change in `CrawApp`). The new optional `Book` columns and the unused `CrawAPIClient` are forward-compatible and can stay.
5. **Tester accounts:** create at least three Clerk test accounts (one with email-only, one with Google OAuth, one with both) and document them in the team password manager.

## Open Questions

- Do we accept Sign in with Apple as one of the providers, given App Store policy when offering email + OAuth? **Proposal:** yes — turn it on in the Clerk dashboard before submission. App Store Review will reject otherwise.
- Should the splash show the app logo or the word-mark? **Proposal:** logo only; matches the existing `Assets.xcassets` accent color treatment.
- How long until the backend exists? **Proposal:** out of scope here; the app ships with a mock service behind a debug launch arg so the UI is usable end-to-end without the backend.
- Do we need a "guest mode" that allows browsing local sample data without sign-in? **Proposal:** no — the product is identity-first. Reconsider after first user testing.
