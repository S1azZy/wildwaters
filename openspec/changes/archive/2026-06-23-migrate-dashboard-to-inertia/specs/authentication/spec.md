## MODIFIED Requirements

### Requirement: Protected dashboard
The system SHALL require an active authenticated session for the Dashboard and
SHALL render the current localized account placeholder only to that user.

#### Scenario: Guest opens dashboard
- **GIVEN** a visitor without an active session
- **WHEN** the visitor opens the Dashboard
- **THEN** the system redirects to sign-in with an authentication-required
  message

#### Scenario: Authenticated user opens dashboard
- **GIVEN** a user with an active persisted session and a supported stored
  locale
- **WHEN** the user opens the Dashboard
- **THEN** the system renders the Dashboard as an Inertia page inside the
  authenticated application shell
- **AND** the page displays the localized placeholder identifying the signed-in
  account and an accessible sign-out action
- **AND** the response exposes no raw session material, credentials, policy
  internals, or unnecessary user attributes

### Requirement: Sign-out
The system SHALL revoke the current persisted session and clear browser
authentication on sign-out.

#### Scenario: Authenticated sign-out
- **GIVEN** an authenticated user viewing the Dashboard
- **WHEN** the user activates its sign-out button
- **THEN** the system submits a CSRF-protected `DELETE` request for the current
  session
- **AND** it records the session as revoked
- **AND** it clears browser authentication and redirects to the legacy sign-in
  page with a localized notice

#### Scenario: Reuse revoked token
- **GIVEN** a previously issued session has been revoked
- **WHEN** its token is presented on a protected request
- **THEN** the system treats the request as unauthenticated
