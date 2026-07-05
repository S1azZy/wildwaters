## ADDED Requirements

### Requirement: Admin-only GeoNames import launch
The system SHALL allow GeoNames region import launch only from the admin
service-actions surface.

#### Scenario: Guest cannot launch import
- **GIVEN** a visitor has no active application session
- **WHEN** the visitor submits the GeoNames import launch action
- **THEN** the system redirects to application sign-in with an authentication-required message
- **AND** no import run, run item, or import job is created

#### Scenario: Member cannot launch import
- **GIVEN** an authenticated user whose role is `member`
- **WHEN** the user submits the GeoNames import launch action
- **THEN** the system redirects to the explore homepage with an admin-required message
- **AND** no import run, run item, or import job is created

#### Scenario: Admin launches import
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** the admin submits the GeoNames import launch action
- **THEN** the system enqueues one GeoNames import run through the queued import interactor
- **AND** the run and item parameter snapshots contain the effective ENV-backed import settings
- **AND** the run initiator identifies the admin service-actions launch action
- **AND** the admin is redirected back to the service-actions page with a success message

#### Scenario: Active run blocks duplicate launch
- **GIVEN** an authenticated admin and an active GeoNames import run already exists
- **WHEN** the admin submits the GeoNames import launch action
- **THEN** the system creates no additional import run, run item, or import job
- **AND** the admin is redirected back to the service-actions page with a failure message

### Requirement: Latest GeoNames import panel
The system SHALL show the latest GeoNames import run on the admin
service-actions page.

#### Scenario: No previous run
- **GIVEN** no run exists for the configured GeoNames import source
- **WHEN** an admin opens the service-actions page
- **THEN** the page renders the GeoNames import panel with an empty latest-run state
- **AND** the launch button is available

#### Scenario: Latest run summary
- **GIVEN** at least one run exists for the configured GeoNames import source
- **WHEN** an admin opens the service-actions page
- **THEN** the page renders the latest run status, mode, initiator, started timestamp, finished timestamp when present, item status counts, settings snapshot, and result statistics
- **AND** the page exposes no raw session material, credentials, user object, role field, policy internals, secrets, or token values

#### Scenario: Failed latest run summary
- **GIVEN** the latest GeoNames import run or one of its items has sanitized failure data
- **WHEN** an admin opens the service-actions page
- **THEN** the panel renders a failure summary without raw credentials, tokens, or secret environment values

### Requirement: Admin service action form
The system SHALL render the GeoNames import launch button as a Rails/Inertia
form submitted to the admin service-actions launch URL.

#### Scenario: Launch button submits POST
- **GIVEN** an admin opens the service-actions page
- **WHEN** the page renders
- **THEN** the GeoNames panel contains one launch button inside a POST form targeting the Rails-generated launch URL
- **AND** it does not require import configuration fields from the client

