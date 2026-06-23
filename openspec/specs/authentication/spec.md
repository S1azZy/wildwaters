# Authentication Specification

## Purpose

Define the implemented password registration, sign-in, persisted session, access
control, and sign-out behavior for Wild Waters web users.

## Requirements

### Requirement: Password registration
The system SHALL register a user and password identity atomically from an email, password confirmation, and supported locale.

#### Scenario: Registration page
- **GIVEN** a visitor without an active session
- **WHEN** the visitor opens the registration page
- **THEN** the system renders the registration form as an Inertia page inside
  the guest application shell
- **AND** the page receives localized display-ready copy, locale options, safe
  form defaults, and Rails-generated form/navigation URLs
- **AND** the response exposes no password value, raw session data, reset token
  field, policy internals, or user object

#### Scenario: Successful registration
- **GIVEN** an email that is not already registered and matching valid passwords
- **WHEN** a visitor submits registration with an `en` or `ru` locale
- **THEN** the system creates one user, one password identity, and one session
- **AND** it redirects the new user to the dashboard

#### Scenario: Invalid registration
- **GIVEN** registration input with invalid identity data such as a mismatched password confirmation
- **WHEN** the visitor submits registration
- **THEN** the system returns an unprocessable response
- **AND** it renders the migrated registration page with safe public validation
  feedback
- **AND** it creates neither the user nor the password identity

### Requirement: Email identity normalization
The system SHALL normalize password-identity email addresses for registration and authentication.

#### Scenario: Sign in with normalized email
- **GIVEN** a password identity stored for `user@example.com`
- **WHEN** the user signs in with surrounding whitespace and different email casing
- **THEN** the system authenticates the same identity

#### Scenario: Duplicate normalized account email
- **GIVEN** an account already stored for a normalized email
- **WHEN** another account uses an equivalent email with different casing or whitespace
- **THEN** the system rejects the duplicate account email

### Requirement: Password sign-in
The system SHALL create a persisted session only for an active user with valid password credentials.

#### Scenario: Sign-in page
- **GIVEN** a visitor without an active session
- **WHEN** the visitor opens the sign-in page
- **THEN** the system renders the sign-in form as an Inertia page inside the
  guest application shell
- **AND** the page receives localized display-ready copy, safe form defaults,
  recovery and registration URLs, and the Rails-generated submit URL
- **AND** the response exposes no password value, raw session data, reset token
  field, policy internals, or user object

#### Scenario: Successful sign-in
- **GIVEN** an active user with a password identity
- **WHEN** the user submits the correct password from the migrated sign-in page
- **THEN** the system creates a session and reaches the legacy explore homepage
  with a full document visit

#### Scenario: Invalid credentials
- **GIVEN** an unknown email or an incorrect password
- **WHEN** a visitor attempts to sign in
- **THEN** the system creates no session
- **AND** it returns an unprocessable response through the migrated sign-in page
  with the same generic failure message

#### Scenario: Suspended account
- **GIVEN** a suspended user with otherwise valid password credentials
- **WHEN** the user attempts to sign in
- **THEN** the system creates no authenticated session

#### Scenario: Authenticated user opens sign-in
- **GIVEN** an authenticated user
- **WHEN** the user opens the sign-in page
- **THEN** the system redirects to the explore homepage

### Requirement: Persisted web session
The system SHALL authenticate requests with a signed browser token whose digest is stored in an active session record.

#### Scenario: Session issuance
- **GIVEN** a successfully authenticated password identity
- **WHEN** the system issues a session
- **THEN** it stores the token digest, authentication method, last-seen time, expiry, IP address, and user agent
- **AND** the raw token expires after 30 days and is returned only in a signed HttpOnly SameSite=Lax cookie

#### Scenario: Production cookie
- **GIVEN** the application is running in production
- **WHEN** a session cookie is issued
- **THEN** the cookie is marked Secure

#### Scenario: Resume active session
- **GIVEN** a request with a valid token for a non-expired, non-revoked session
- **WHEN** the request is processed
- **THEN** the system restores the current user and updates the session's last-seen time

#### Scenario: Reject inactive session
- **GIVEN** a request with a token for an expired or revoked session
- **WHEN** the request is processed
- **THEN** the system does not authenticate the user and removes the invalid cookie

### Requirement: Request-scoped authenticated locale
The system SHALL process an application request that begins with an active
persisted session using the authenticated user's supported stored locale, and
SHALL process an unauthenticated request using the application default locale.

#### Scenario: Russian locale for an authenticated request
- **GIVEN** an active persisted session for a user whose stored locale is `ru`
- **WHEN** the user makes an application request
- **THEN** Rails translations produced during that request use the `ru` locale

#### Scenario: English locale for an authenticated request
- **GIVEN** an active persisted session for a user whose stored locale is `en`
- **WHEN** the user makes an application request
- **THEN** Rails translations produced during that request use the `en` locale

#### Scenario: Default locale for a guest request
- **GIVEN** a request without an active persisted session
- **WHEN** the application processes the request
- **THEN** Rails translations produced during that request use the application
  default locale

#### Scenario: Locale isolation between requests
- **GIVEN** one request was processed using an authenticated user's non-default
  locale
- **WHEN** a later unauthenticated request is processed by the application
- **THEN** the later request uses the application default locale

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
The system SHALL revoke the current persisted session and clear browser authentication on sign-out.

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
