## MODIFIED Requirements

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

### Requirement: Reset security effects
The system SHALL revoke all active sessions for the user after a successful password reset.

#### Scenario: Failed password reset
- **GIVEN** an invalid token or invalid password confirmation
- **WHEN** the reset is submitted
- **THEN** the system returns an unprocessable response through the migrated
  reset edit page with a safe generic error
- **AND** it does not revoke the user's active sessions
