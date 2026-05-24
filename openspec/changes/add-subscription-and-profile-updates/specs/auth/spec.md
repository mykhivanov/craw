## MODIFIED Requirements

### Requirement: Sign-out flow

The Profile tab SHALL contain a "Sign out" affordance that, when confirmed via the dialog defined in the `app-shell` capability, calls `Clerk.shared.auth.signOut()`. On success, the app SHALL return to the auth entry screen. Local SwiftData records SHALL NOT be deleted by sign-out — only by the account-deletion flow defined below.

#### Scenario: User signs out from Profile tab

- **WHEN** the user taps "Sign out" and confirms the dialog
- **THEN** Clerk's sign-out method is invoked
- **AND** `Clerk.shared.user` becomes nil
- **AND** the auth entry screen replaces the dashboard
- **AND** previously persisted `Book`, `ReadingDay`, `ReadingSession`, `Quote`, and `Thought` rows remain in the local SwiftData store

#### Scenario: Sign-out network failure

- **WHEN** `Clerk.shared.auth.signOut()` throws
- **THEN** the user remains signed in
- **AND** a one-line error message is shown via the Profile tab
- **AND** the dashboard is still visible

## ADDED Requirements

### Requirement: Account deletion flow

The system SHALL provide an account-deletion path callable from the Profile tab once the user confirms the destructive dialog. The flow SHALL execute these steps in order on the main actor:

1. Issue `DELETE /v1/users/me` against the configured `CRAW_API_BASE_URL` with the current Clerk JWT.
2. On 2xx, call `Clerk.shared.user?.delete()` to revoke the IdP session.
3. On success, wipe local SwiftData rows (`Book`, `ReadingDay`, `ReadingSession`, `SessionRetrospective`, `Quote`, `Thought`) via a single `ModelContext` save.
4. Allow the auth gate to route back to the entry screen on the next `Clerk.shared.user` change.

If the backend call fails, no Clerk delete SHALL be attempted and the user SHALL see an inline error message. If the backend call succeeds but the Clerk delete fails, a recoverable error SHALL be surfaced asking the user to sign out manually.

#### Scenario: Successful deletion

- **WHEN** the user confirms the delete-account dialog
- **THEN** the app issues `DELETE /v1/users/me` with the current Clerk JWT
- **AND** on 2xx, `Clerk.shared.user?.delete()` is invoked
- **AND** on success, local SwiftData rows are wiped
- **AND** the auth gate returns to the entry screen via the existing `Clerk.shared.user` observer

#### Scenario: Backend delete fails

- **WHEN** `DELETE /v1/users/me` returns a non-2xx
- **THEN** Clerk's delete method is NOT called
- **AND** an inline error message is shown on the Profile tab
- **AND** the user remains signed in

#### Scenario: Clerk delete fails after backend succeeds

- **WHEN** `DELETE /v1/users/me` returns 2xx but `Clerk.shared.user?.delete()` throws
- **THEN** an alert advises the user that account data has been removed and asks them to sign out manually
- **AND** the local SwiftData wipe still runs
- **AND** the Profile tab remains visible

### Requirement: User feedback submission

The system SHALL provide a one-shot feedback submission flow callable from the Profile tab. The client SHALL POST `/v1/users/me/feedback` with body `{"feedback": "<text>"}` and the current Clerk JWT. The server SHALL return 200 with the updated `User` resource (now containing `feedback` and `feedback_submitted_at` fields) when the field was previously null, and SHALL return 409 if the field was already set.

On 2xx, the client SHALL update the cached `APIUser` in `AuthSessionStore` via a new `applyUpdatedUser(_:)` method without triggering a full bootstrap roundtrip. On 409, the client SHALL refresh the cached user from the server and present the static "Thank you for your feedback!" card without showing an error.

#### Scenario: First-time submission

- **WHEN** the user submits feedback for the first time
- **THEN** the client issues `POST /v1/users/me/feedback`
- **AND** on 200 the cached `APIUser` is replaced with the response payload
- **AND** the Profile tab transitions to the static "Thank you" card

#### Scenario: Concurrent submission across devices returns 409

- **WHEN** the server returns 409 because feedback was already submitted from another device
- **THEN** the client refreshes the cached user via `POST /v1/auth/session`
- **AND** the Profile tab transitions to the static "Thank you" card
- **AND** no user-facing error is shown

#### Scenario: APIUser carries feedback field

- **WHEN** `POST /v1/auth/session` is called for a user who has previously submitted feedback
- **THEN** the decoded `APIUser` payload contains a non-nil `feedback` string and a `feedback_submitted_at` date
- **AND** the Profile tab renders the static thank-you card on first paint
