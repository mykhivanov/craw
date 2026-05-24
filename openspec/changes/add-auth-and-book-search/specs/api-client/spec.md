## ADDED Requirements

### Requirement: Authenticated request envelope

Every request sent by `CrawAPIClient` SHALL include the header `Authorization: Bearer <token>` where `<token>` is the JWT returned by the configured `AuthTokenProvider`. Requests SHALL also include `Accept: application/json` and, for requests with a body, `Content-Type: application/json`. The base URL SHALL be read from `Info.plist["CRAW_API_BASE_URL"]` with a default of `https://api.craw.app/v1`.

#### Scenario: Outgoing request includes bearer token

- **WHEN** the client issues any request
- **THEN** the `Authorization` header has the form `Bearer <jwt>`
- **AND** the JWT is the current token returned by `AuthTokenProvider.currentToken()`

#### Scenario: Base URL override

- **WHEN** `Info.plist["CRAW_API_BASE_URL"]` is set to a non-default value (e.g., a staging URL)
- **THEN** every request is sent against that URL
- **AND** the default `https://api.craw.app/v1` is NOT used

### Requirement: 401 refresh-and-retry

When the client receives an HTTP 401 response, it SHALL invalidate the cached auth token, fetch a fresh token (`skipCache: true`), and retry the original request exactly once. If the second attempt also returns 401, the client SHALL surface `APIError.unauthorized` and SHALL NOT retry further.

#### Scenario: First call returns 401, retry succeeds

- **WHEN** the first attempt returns HTTP 401
- **AND** a forced-refresh token is obtained successfully
- **THEN** the request is reissued with the new token
- **AND** if the second attempt returns 2xx, the decoded response is returned to the caller

#### Scenario: Both attempts return 401

- **WHEN** both the first and the retried request return HTTP 401
- **THEN** the client returns `APIError.unauthorized`
- **AND** the auth state is treated as invalid by upstream callers (e.g., the auth gate re-evaluates)

### Requirement: Typed error mapping

The client SHALL map response and transport conditions to a single `APIError` enum with at least these cases:
- `unauthorized` (HTTP 401 after one retry)
- `notFound` (HTTP 404)
- `rateLimited(retryAfter:)` (HTTP 429, parsed from `Retry-After`)
- `server(message:, code:)` (HTTP 5xx or 4xx other than the above, with body parsed as `APIErrorBody { code, message }`)
- `network(URLError)` (transport failures, excluding `URLError.cancelled`)
- `decoding(Error)` (response body parse failures)
- `cancelled` (Task cancellation or `URLError.cancelled`)

#### Scenario: 429 response carries retry-after

- **WHEN** the server returns HTTP 429 with `Retry-After: 30`
- **THEN** the client returns `APIError.rateLimited(retryAfter: 30)`

#### Scenario: Server returns structured error body

- **WHEN** the server returns HTTP 422 with body `{"code":"INVALID_QUERY","message":"Query too short"}`
- **THEN** the client returns `APIError.server(message: "Query too short", code: "INVALID_QUERY")`

### Requirement: Cancellation is silent

When a Swift `Task` running an API call is cancelled, the client SHALL return `APIError.cancelled` and the calling capability SHALL NOT treat this as an error to display.

#### Scenario: Search store cancels prior task

- **WHEN** the search store cancels its previous in-flight task
- **THEN** the cancelled task's call returns `APIError.cancelled`
- **AND** the search state does NOT enter `error`

### Requirement: JSON encoding and date format

Request and response bodies SHALL be encoded and decoded as JSON. Dates SHALL use ISO 8601 with fractional seconds and UTC offset, e.g., `2026-05-24T14:33:21.123Z`. Snake-case JSON keys SHALL be mapped to Swift camelCase via `keyDecodingStrategy = .convertFromSnakeCase` (and the inverse for encoding).

#### Scenario: Decoding a dated response

- **WHEN** the response contains `"date_added": "2026-05-24T14:33:21.123Z"`
- **THEN** it is decoded into a Swift property `dateAdded: Date` representing 2026-05-24 14:33:21.123 UTC
