# Password Reset Specification

## Purpose

Define the implemented account-recovery flow, including enumeration-safe
requests, time-bound one-time tokens, password replacement, and session
revocation.

## Requirements

### Requirement: Enumeration-safe reset request
The system SHALL return the same public result for existing and unknown account emails.

#### Scenario: Reset request page
- **GIVEN** a visitor without an active session
- **WHEN** the visitor opens the password-reset request page
- **THEN** the system renders the reset request form as an Inertia page inside
  the guest application shell
- **AND** the page receives localized display-ready copy, safe form defaults,
  and Rails-generated form/navigation URLs
- **AND** the response exposes no password value, raw session data, reset token
  field, policy internals, or user object

#### Scenario: Existing password identity
- **GIVEN** an account with a password identity
- **WHEN** a visitor requests a password reset for its normalized email
- **THEN** the system redirects to sign-in with the generic success message
- **AND** it sends one reset email to the account's primary email address

#### Scenario: Unknown email
- **GIVEN** no password identity exists for the submitted email
- **WHEN** a visitor requests a password reset
- **THEN** the system redirects to sign-in with the same generic success message
- **AND** it sends no email

### Requirement: Reset token storage
The system SHALL store only a digest of a generated password-reset token and the time it was issued.

#### Scenario: Issue reset token
- **GIVEN** an existing password identity
- **WHEN** a password reset is requested
- **THEN** the system stores a token digest and issue timestamp
- **AND** it places the raw token only in the delivered reset link

### Requirement: Time-bound single-use reset
The system SHALL accept a password-reset token only while it exists and is no more than 30 minutes old.

#### Scenario: Reset edit page
- **GIVEN** a visitor opens a password-reset token URL
- **WHEN** the reset form is rendered
- **THEN** the system renders the reset edit form as an Inertia page inside the
  guest application shell
- **AND** the page receives localized display-ready copy and a Rails-generated
  submit URL for the current token route
- **AND** the response exposes no password value, raw session data, standalone
  reset token prop, policy internals, or user object

#### Scenario: Active token
- **GIVEN** a valid token issued less than 30 minutes ago
- **WHEN** the user submits a valid new password and matching confirmation
- **THEN** the system updates the password
- **AND** it clears the reset-token digest and timestamp

#### Scenario: Reused token
- **GIVEN** a token that already completed a successful password reset
- **WHEN** the token is submitted again
- **THEN** the system rejects it as invalid

#### Scenario: Expired token
- **GIVEN** a token issued at least 30 minutes ago
- **WHEN** the token is submitted
- **THEN** the system rejects it as invalid

### Requirement: Reset security effects
The system SHALL revoke all active sessions for the user after a successful password reset.

#### Scenario: Successful password reset
- **GIVEN** a user with an active reset token and active sessions
- **WHEN** the user successfully changes the password
- **THEN** all active sessions for that user are revoked
- **AND** the user is redirected to sign-in with a success message

#### Scenario: Failed password reset
- **GIVEN** an invalid token or invalid password confirmation
- **WHEN** the reset is submitted
- **THEN** the system returns an unprocessable response through the migrated
  reset edit page with a safe generic error
- **AND** it does not revoke the user's active sessions
