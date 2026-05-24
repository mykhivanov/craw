## ADDED Requirements

### Requirement: Free-text book search via custom backend

The system SHALL allow the user to search the Craw book catalog by free-text query and view live results within the app. The query SHALL be sent as an authenticated `GET` request to `<CRAW_API_BASE_URL>/books/search` with parameters `q`, `limit`, and `offset`. The request SHALL be issued only when an authenticated Clerk session is active.

#### Scenario: User types a query

- **WHEN** the user types a non-empty query into the search field
- **THEN** the system issues a request to `GET /books/search?q=<query>&limit=20&offset=0` with the current Clerk JWT in the `Authorization` header
- **AND** the system displays the returned results as a list of cards

#### Scenario: User clears the query

- **WHEN** the user clears the search field to an empty string
- **THEN** the system cancels any in-flight request
- **AND** the system returns to an idle state with no results visible

#### Scenario: No session at search time

- **WHEN** the search field is presented but `Clerk.shared.user` is nil
- **THEN** the system does NOT issue any search request
- **AND** the auth gate has redirected the user to the entry screen before reaching this state

### Requirement: Debounce and cancel in-flight requests

The system SHALL debounce search input by at least 300 ms before issuing a network request, and SHALL cancel any prior in-flight request when a new query is committed. Cancellation of a prior request SHALL NOT surface as a visible error.

#### Scenario: User types quickly

- **WHEN** the user types five characters in rapid succession
- **THEN** the system issues at most one network request after typing stops
- **AND** the system does NOT display an error from cancelled prior requests

### Requirement: Result mapping from backend response

The backend SHALL return a JSON envelope `{ "items": [SearchBook], "next_offset": Int? }` where each `SearchBook` has the fields documented by the `Book` schema in `api-contract.yaml`. When the user selects a result, the system SHALL insert a new `Book` row into the on-device library mapped as follows:
- `remoteID` ← `SearchBook.id`
- `title` ← `SearchBook.title`
- `author` ← `SearchBook.author` (the backend pre-joins authors and substitutes "Unknown author" if missing)
- `totalPages` ← `SearchBook.totalPages` (the backend supplies a non-zero default if missing upstream)
- `coverImageURL` ← `SearchBook.coverImageURL` (already HTTPS, never `http://`)
- `isbn` ← `SearchBook.isbn` (preferring ISBN-13)
- `currentPage` ← 0
- `dateAdded` ← the time of insertion

#### Scenario: Adding a result

- **WHEN** the user selects a returned `SearchBook`
- **THEN** a new `Book` is inserted with the fields mapped exactly per the rules above
- **AND** the search sheet dismisses
- **AND** the new book appears in the Home tab's Reading Now section

#### Scenario: Empty items array

- **WHEN** the response is `{"items": [], "next_offset": null}`
- **THEN** the view enters `empty` state with a message referencing the current query

### Requirement: Pagination

The system SHALL request the first page with `limit=20` and `offset=0`. When the user scrolls within five rows of the last loaded result, the system SHALL fetch the next page using the `next_offset` value from the previous response. The system SHALL stop fetching after 60 total results for a given query, or when `next_offset` is `null`.

#### Scenario: Scrolling near the end of the list

- **WHEN** the user scrolls within five rows of the last loaded result
- **AND** the previous response included a non-null `next_offset`
- **AND** fewer than 60 results have been loaded for the current query
- **THEN** the system requests the next page using `offset=<next_offset>` and `limit=20`

#### Scenario: Reaching the result cap

- **WHEN** the system has loaded 60 results for a given query
- **THEN** the system does NOT issue further pagination requests for that query

#### Scenario: Backend signals no more pages

- **WHEN** a paginated response returns `next_offset: null`
- **THEN** the system does NOT issue further pagination requests for that query

### Requirement: Search state machine

The search surface SHALL be a pure function of an `@Observable` state with exactly these cases: `idle`, `loading`, `results([BookSearchResult])`, `empty`, `error(String)`. The view SHALL display:
- `idle`: a short helper string ("Search by title or author") and no list.
- `loading`: a progress indicator.
- `results`: the list of cards.
- `empty`: a "no results" message specific to the current query.
- `error`: a one-line message derived from `APIError` and a retry affordance.

#### Scenario: Search returns zero items

- **WHEN** the query returns a response whose `items` array is empty
- **THEN** the view enters `empty` state
- **AND** displays a message that references the query string

#### Scenario: Network or HTTP error

- **WHEN** the request fails with an `APIError` other than `.cancelled`
- **THEN** the view enters `error` state with a human-readable message
- **AND** displays a retry affordance that re-issues the last query

#### Scenario: 401 propagates to auth gate

- **WHEN** the request returns `APIError.unauthorized` after the API client's single retry
- **THEN** the auth gate observes `Clerk.shared.user == nil` (or the search store calls `Clerk.shared.auth.signOut()` defensively)
- **AND** the user is returned to the auth entry screen

### Requirement: Cover image rendering

When a `Book` has a non-nil `coverImageURL`, the system SHALL render the cover via SwiftUI's `AsyncImage`, falling back to the neutral placeholder while loading and on failure. The fallback order SHALL be: remote `coverImageURL` → bundled `coverAssetName` → neutral placeholder.

#### Scenario: Book with a remote cover

- **WHEN** a book has a non-nil `coverImageURL`
- **THEN** the cover renders from that URL
- **AND** the neutral placeholder is shown only while the image is loading or if loading fails

### Requirement: Privacy and quota safeguards

The system SHALL declare its outbound network calls to `api.craw.app` and `clerk.com` (plus Clerk sub-domains) in `PrivacyInfo.xcprivacy`. The system SHALL NOT send any device identifier with search requests — only the query string, pagination parameters, and the `Authorization` bearer token.

#### Scenario: Outgoing request payload

- **WHEN** the system issues a search request
- **THEN** the request URL contains only `q`, `limit`, and `offset` query parameters
- **AND** the request body is empty
- **AND** the only headers added beyond `URLSession` defaults are `Authorization`, `Accept`, and (for non-GET requests) `Content-Type`
