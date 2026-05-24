## 1. Dependencies & configuration

- [x] 1.1 SwiftPM dependency `https://github.com/clerk/clerk-ios` added; resolved at 1.1.3 (transitively pulls PhoneNumberKit 4.2.13 + Nuke 12.9.0). Build succeeds.
- [x] 1.2 `CLERK_PUBLISHABLE_KEY` and `CRAW_API_BASE_URL` configured in build settings.
- [x] 1.3 URL type `com.mykhivanov.Craw` registered for the Clerk OAuth callback.
- [x] 1.4 Add `Craw/PrivacyInfo.xcprivacy` declaring `api.craw.app` and `clerk.com` (plus `*.clerk.accounts.dev`) tracking domains, and data classes "Search History", "Email Address", "Name", "User ID" with the "App Functionality" purpose.
- [x] 1.5 Update `CLAUDE.md` to document how to set `CLERK_PUBLISHABLE_KEY` locally and in CI.

## 2. Persistence

- [x] 2.1 Add `coverImageURL: URL?`, `isbn: String?`, and `remoteID: String?` (all optional) to `@Model class Book` in `Craw/Persistence/Book.swift`.
- [x] 2.2 Update `Book.init` to accept the three new optional parameters with defaults of `nil`.
- [ ] 2.3 Launch the app once without `-CrawSeedSampleData YES` and confirm previously seeded books still load (SwiftData additive lightweight migration). **(USER — manual sim launch.)**
- [x] 2.4 Leave `SampleData.seedIfEmpty` unchanged (new fields stay `nil` for seeded books).

## 3. Networking layer (`api-client`)

- [x] 3.1 Create `Craw/Networking/AuthTokenProvider.swift` with `protocol AuthTokenProvider: Sendable { func currentToken(forceRefresh: Bool) async throws -> String }`.
- [x] 3.2 Create `Craw/Networking/ClerkAuthTokenProvider.swift` conforming to `AuthTokenProvider`. Implement `currentToken(forceRefresh:)` by calling `Clerk.shared.auth.getToken(.init(skipCache: forceRefresh))`. Throw `APIError.unauthorized` when the returned token is nil or when no session is active.
- [x] 3.3 Create `Craw/Networking/APIError.swift` with the enum cases enumerated in `specs/api-client/spec.md` plus an `APIErrorBody: Decodable` struct (`code: String`, `message: String`). (Dropped `details: [String: AnyCodable]?` — server-side `details` is opaque to the client today; revisit if a field-specific UI surface is needed.)
- [x] 3.4 Create `Craw/Networking/CrawAPIClient.swift` as an `actor` with init `(baseURL: URL, session: URLSession = .shared, tokenProvider: AuthTokenProvider)`. Single `performGet<Response>` / `sendOnce<Response>` helpers handle header injection, 401 retry-once, `APIError` mapping. Configured `JSONDecoder` / `JSONEncoder` use the custom ISO 8601 with-fractional-seconds strategy (snake-case mapping is handled per-DTO via explicit `CodingKeys` to avoid conflicts with `LibraryBook`).
- [x] 3.5 Added typed endpoint methods `bootstrapSession() async throws -> APIUser` (POST `/auth/session`) and `searchBooks(query:limit:offset:) async throws -> BookSearchPage` (GET `/books/search`). Other endpoints from `api-contract.yaml` remain undeclared until the next change consumes them.
- [x] 3.6 At app launch (`CrawApp.init`), `URLCache.shared` is configured at 50 MB on-disk / 10 MB in-memory.
- [ ] 3.7 Add unit-style tests (XCTest or Swift Testing — create the target if it doesn't exist) for: 401 retry-once succeeds, two 401s surface `.unauthorized`, `Retry-After` parsed into `.rateLimited`, structured error body parsed into `.server`. **(USER — no test target exists yet; needs to be added via Xcode.)**

## 4. Auth (`auth` capability)

- [x] 4.1 In `Craw/CrawApp.swift`, `Clerk.configure(publishableKey:options:)` is called in `init` using the key resolved from `Info.plist["CLERK_PUBLISHABLE_KEY"]` via `AppEnvironment.clerkPublishableKey`, with redirect URL `com.mykhivanov.Craw://clerk-callback` and callback scheme `com.mykhivanov.Craw`. `.environment(Clerk.shared)` is injected at the scene root.
- [x] 4.2 In DEBUG, `AppEnvironment.clerkPublishableKey` asserts the value is non-empty.
- [x] 4.3 Create `Craw/AppShell/SplashView.swift` — a centered logo on `Theme.Palette.canvas` with a `ProgressView` below.
- [x] 4.4 Create `Craw/AppShell/AuthGate.swift` — observes `@Environment(Clerk.self)`, switches between `SplashView`, `AuthView(mode: .signInOrUp, isDismissable: false)`, and `RootView` per the gate state machine.
- [x] 4.5 In `Craw/CrawApp.swift`, `WindowGroup`'s root is now `AuthGate()`. `RootView` itself is unchanged.
- [x] 4.6 In `Craw/AppShell/ProfileTab.swift`, added a "Sign out" row styled per design tokens (red text via `Theme.Palette.trendDown`). Tapping it calls `try await Clerk.shared.auth.signOut()`; on success the gate re-evaluates automatically. On failure a one-line error is shown below.
- [x] 4.7 In `AuthGate`, observes the transition of `clerk.user?.id` via `.onChange` and calls `AuthSessionStore.bootstrapIfNeeded()` (which wraps `CrawAPIClient.bootstrapSession()`). The store caches the returned `APIUser` and is injected into `RootView`'s environment. On `APIError.unauthorized` after retry, calls `Clerk.shared.auth.signOut()`. On transient errors, retries via `.onChange(scenePhase)` foreground transitions.

## 5. Book search DTOs and store

- [x] 5.1 Create `Craw/Books/Search/BookSearchDTO.swift` with `BookSearchPage { items: [SearchBookDTO]; nextOffset: Int? }` and `SearchBookDTO { id, title, author, totalPages, coverImageURL: URL?, isbn: String? }`. Matches the `BookSearchResponse` and `Book` schemas in `api-contract.yaml`.
- [x] 5.2 Create `Craw/Books/Search/BookSearchResult.swift` — a UI-facing struct with `id, title, author, totalPages, coverImageURL, isbn`. Includes an initializer from `SearchBookDTO`.
- [x] 5.3 Create `Craw/Books/Search/BookSearchService.swift` — `protocol BookSearchService { func search(query: String, offset: Int) async throws -> BookSearchPage }` plus `LiveBookSearchService` wrapping `CrawAPIClient.searchBooks`.
- [x] 5.4 In DEBUG, `MockBookSearchService` returns three fixture results filtered by query substring; selected via `UserDefaults.standard.bool(forKey: "CrawMockSearch")` (launch arg `-CrawMockSearch YES`).
- [x] 5.5 Create `Craw/Books/Search/BookSearchStore.swift` as `@Observable @MainActor final class BookSearchStore` with the `idle / loading / results / empty(query) / error(message)` state machine. Debounce (350 ms via `Task.sleep`), per-query cancellation, dedupe by `(title.lowercased(), author.lowercased())`, pagination using `nextOffset` capped at 60.
- [x] 5.6 `APIError.cancelled` and `CancellationError` are treated as silent (no `error` transition). On `APIError.unauthorized` after retry, the store invokes the injected `onUnauthorized` callback (default: `Clerk.shared.auth.signOut()`) so the gate takes over.

## 6. Book search UI

- [x] 6.1 Create `Craw/Books/Search/BookSearchView.swift` — switches on `store.state`. `.searchable(text:)` bound to local `@State` mirrored into the store via `.onChange`.
- [x] 6.2 Create `Craw/Books/Search/BookSearchResultRow.swift` — cover thumbnail (`AsyncImage` from `coverImageURL` via the shared `CoverPlaceholder`), title, author, page count.
- [x] 6.3 In the results list, `.onAppear` on rows within the last-5 triggers `store.loadMore()`.
- [x] 6.4 On row tap, a `Book` is inserted via the SwiftData `modelContext` (including `remoteID`, `coverImageURL`, `isbn`), then the sheet dismisses via `@Environment(\.dismiss)`.
- [x] 6.5 Theme tokens applied for typography, spacing, rounding. No new colors introduced.

## 7. Cover rendering

- [x] 7.1 `CoverPlaceholder` now accepts both `coverAssetName: String?` and `coverImageURL: URL?`. Renders via `AsyncImage(url:)` when `coverImageURL` is non-nil (with neutral placeholder during load/failure), then falls back to bundled asset, then to the neutral glyph. Updated in `Craw/Home/Sections/BookListSection.swift` and the hero in `Craw/Books/BookDetailView.swift`.
- [ ] 7.2 Verify the fallback path: simulate a failing URL (e.g., a 404 thumbnail) and confirm the neutral placeholder replaces it without using `coverAssetName`. **(USER — manual.)**

## 8. Wire-up

- [x] 8.1 In `Craw/Home/HomeDashboardView.swift`, the add-book button's prior no-op is replaced with `.sheet(isPresented: $isSearchPresented) { BookSearchView() }`.
- [x] 8.2 `BookSearchView` is presented from `HomeDashboardView`, which is inside the modelContainer scope; insertions land in the live container.
- [x] 8.3 `AuthGate` is the sole root of the `WindowGroup`. `RootView` is only instantiated by `AuthGate` after Clerk reports a signed-in user.

## 9. End-to-end verification

- [ ] 9.1 Manual flow — fresh install (no Clerk session): launch app → splash → auth screen → sign up with email → land on Home dashboard. **(USER.)**
- [ ] 9.2 Manual flow — warm launch (existing session): launch app → splash → Home dashboard (no auth screen). **(USER.)**
- [ ] 9.3 Manual flow — search-and-add: tap add button on Home → search "atomic habits" → tap top result → sheet dismisses → book in Reading Now. **(USER — use `-CrawMockSearch YES` until backend is up.)**
- [ ] 9.4 Manual flow — sign-out: Profile tab → Sign out → returns to auth screen → local books remain visible after signing back in. **(USER.)**
- [ ] 9.5 Manual flow — 401 handling: revoke the user's Clerk session externally → trigger a search → confirm app returns to auth screen instead of crashing. **(USER.)**
- [ ] 9.6 Manual flow — offline: turn off Wi-Fi → trigger a search → confirm `error` state with retry; turn Wi-Fi back on and retry succeeds. **(USER.)**
- [x] 9.7 `xcodebuild -project Craw.xcodeproj -scheme Craw -destination 'platform=iOS Simulator,name=iPhone 17' build` reports `** BUILD SUCCEEDED **`. Clerk SwiftPM package resolved at 1.1.3 (also pulls PhoneNumberKit 4.2.13 and Nuke 12.9.0 transitively). Warnings only (no errors); see "Build warnings" note below.

## 10. Validation & archive readiness

- [x] 10.1 Run `openspec validate add-auth-and-book-search --strict` and resolve any findings.
- [ ] 10.2 Confirm every scenario in `specs/auth/spec.md`, `specs/api-client/spec.md`, `specs/book-search/spec.md`, `specs/app-shell/spec.md`, and `specs/book-library/spec.md` is exercised by either a unit test or a manual checklist entry above. **(USER — pending unit tests in §3.7 + manual flows in §9.)**
- [ ] 10.3 When implementation is complete, run `/opsx:archive` to fold the deltas into `openspec/specs/` and move the change to `openspec/changes/archive/`. **(USER — after §9 verification.)**
