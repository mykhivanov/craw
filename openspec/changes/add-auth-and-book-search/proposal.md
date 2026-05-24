## Why

The app today is a local-only client: data is seeded in DEBUG, the add-book affordance is a "coming soon" no-op, and there is no user identity. To unlock book search, future cross-device sync, and any server-side personalization, the app needs (1) a user identity gate and (2) a first network dependency on our own backend. We're introducing both in the same change so the auth context is in place the moment we make the first authenticated request — and so the API contract is defined once for every feature the app will eventually need, not retrofitted endpoint-by-endpoint.

## What Changes

- **Add an entry / authentication screen** shown before the dashboard on every cold launch when no Clerk session is active. Uses the Clerk iOS SDK's `AuthView` (sign-in or sign-up) presented full-screen.
- **Integrate the Clerk iOS SDK** (`/clerk/clerk-ios`) via SwiftPM. Configure once in `CrawApp.init` with the publishable key from `Info.plist`. Inject `Clerk.shared` into the SwiftUI environment.
- **Gate `RootView`** behind Clerk's `isLoaded` + `user != nil`. While Clerk is loading session state from disk, show a branded splash; when loaded with no user, show `AuthView`; when signed in, show the existing `TabView`.
- **Add `CrawAPIClient`** — a typed actor that wraps `URLSession` calls to our backend at `https://api.craw.app/v1`. Every request automatically attaches `Authorization: Bearer <Clerk session JWT>` fetched via `Clerk.shared.auth.getToken()`.
- **Bootstrap the backend session** by calling `POST /v1/auth/session` once after Clerk reports a signed-in user. Idempotent — backend mints or returns the user record.
- **Implement the search flow** by calling `GET /v1/books/search?q=<query>` (custom backend) instead of Google Books directly. The backend owns Google Books integration, normalization, and caching server-side.
- **Wire the existing add-book affordance** on `HomeDashboardView` to present the search sheet now that search has a real implementation.
- **Add Profile-tab sign-out** action so users can leave (signs out via Clerk and returns to entry screen).
- **Define a minimal API contract** as an OpenAPI 3.1 document in `api-contract.yaml`: auth bootstrap, current-user CRUD (`GET / PATCH / DELETE /v1/user`), book search (`GET /v1/books/search`), and book quiz (`GET /v1/books/quiz`). The `User` resource is **fully hydrated** — every endpoint that returns a `User` (bootstrap, GET, PATCH) embeds the user's library as `library.in_progress[]` and `library.finished[]`, each item carrying every field the Home dashboard and book detail screen need (title, author, total/current pages, status, progress percent, cover URL, ISBN, descriptive metadata, and the relevant timestamps). Reading sessions, quotes, thoughts, and per-day activity remain local-only in v1; library *writes* are also deferred to a future contract revision (see the "Library reads, writes, and local-data semantics" section of `api-contract.yaml`'s `info.description`).
- **MODIFIED:** `app-shell` capability — root navigation is now gated behind an authenticated session.
- **MODIFIED:** `book-library` capability — drops "no writes" restriction; extends `Book` with optional `coverImageURL`, `isbn`, and an optional remote-id `remoteID` for future sync.

## Capabilities

### New Capabilities
- `auth`: User identity via Clerk iOS SDK — sign-in / sign-up entry screen, session-token retrieval, sign-out.
- `book-search`: Free-text search against the custom Craw backend's `/v1/books/search` endpoint and add a selected result to the local library.
- `api-client`: Shared, auth-injecting `URLSession` wrapper used by all backend-bound capabilities, with token refresh, 401 handling, and a single error model.

### Modified Capabilities
- `app-shell`: Adds an authentication gate in front of the tab bar.
- `book-library`: Allows external-source inserts; extends `Book` with optional `coverImageURL`, `isbn`, `remoteID`.

## Impact

- **New code:** `Craw/Auth/`, `Craw/Networking/CrawAPIClient.swift`, `Craw/Networking/APIError.swift`, `Craw/Networking/AuthTokenProvider.swift`, `Craw/Books/Search/`, `Craw/AppShell/AuthGate.swift`, `Craw/AppShell/SplashView.swift`.
- **Modified code:** `Craw/CrawApp.swift` (Clerk configure + environment), `Craw/AppShell/RootView.swift` (wrapped by `AuthGate`), `Craw/Persistence/Book.swift` (new optional fields), `Craw/AppShell/ProfileTab.swift` (sign-out), `Craw/Home/HomeDashboardView.swift` (wire add-book → search sheet).
- **Dependencies (SwiftPM):** add `https://github.com/clerk/clerk-ios` at the latest tagged release.
- **Configuration:** new `Info.plist` keys — `CLERK_PUBLISHABLE_KEY`, `CRAW_API_BASE_URL` (defaults to `https://api.craw.app/v1`). Add a URL scheme `com.mykhivanov.Craw` for Clerk OAuth callbacks.
- **Privacy manifest:** `PrivacyInfo.xcprivacy` declares `api.craw.app` and `clerk.com` domains and "User ID", "Email", "Search History" data classes (functionality purpose).
- **Backend contract:** see `api-contract.yaml` (OpenAPI 3.1) in this change — auth + three endpoint sets (user CRUD, book search, book quiz). Nothing else.
- **No impact on:** existing `reading-session`, `session-quiz`, `session-retrospective`, `reading-activity`, `home-dashboard`, `book-detail`, `quotes-and-thoughts` capabilities — they remain entirely local. The book quiz endpoint is defined in the contract for the future `session-quiz` integration but is not consumed in this change.
