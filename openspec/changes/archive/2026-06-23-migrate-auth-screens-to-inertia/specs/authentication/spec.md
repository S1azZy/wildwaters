## MODIFIED Requirements

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

#### Scenario: Invalid registration
- **GIVEN** registration input with invalid identity data such as a mismatched password confirmation
- **WHEN** the visitor submits registration
- **THEN** the system returns an unprocessable response
- **AND** it renders the migrated registration page with safe public validation
  feedback
- **AND** it creates neither the user nor the password identity

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
