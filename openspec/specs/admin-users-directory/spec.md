# Admin Users Directory Specification

## Purpose

Define the implemented application-owned admin dashboard and users directory
for viewing and narrowly managing user account state.

## Requirements

### Requirement: Admin dashboard shell
The system SHALL make the admin namespace open into an application-owned
dashboard shell instead of a service-actions page.

#### Scenario: Admin root dashboard
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** the user requests `/admin`
- **THEN** the system renders an empty admin dashboard as an Inertia response
- **AND** the dashboard uses the shared admin shell navigation

#### Scenario: Admin shell navigation groups
- **GIVEN** an admin opens an admin page
- **WHEN** the admin shell renders
- **THEN** the first navigation item is Dashboard with its own icon
- **AND** the second navigation item is Service Actions with its own icon
- **AND** a non-clickable `Models` section label appears after a visual spacer
- **AND** Users appears inside the `Models` section with its own icon
- **AND** Regions appears inside the `Models` section with its own icon

### Requirement: Protected admin users directory
The system SHALL provide an application-owned users directory inside the admin
namespace protected by Wild Waters admin authorization.

#### Scenario: Guest access
- **GIVEN** a visitor has no active application session
- **WHEN** the visitor requests an admin users page or submits an admin users action
- **THEN** the system redirects to application sign-in with an authentication-required message

#### Scenario: Member access
- **GIVEN** an authenticated user whose role is `member`
- **WHEN** the user requests an admin users page or submits an admin users action
- **THEN** the system redirects to the explore homepage with an admin-required message

#### Scenario: Admin access
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** the user requests `/admin/users`
- **THEN** the system renders the users directory as an Inertia response inside the admin shell
- **AND** the response exposes no password material, identity records, session records, reset tokens, raw user object, or policy internals

### Requirement: Users directory table
The system SHALL render a paginated admin table of users with search and
display-ready user account fields.

#### Scenario: Paginated list
- **GIVEN** more users exist than the admin users page size
- **WHEN** an admin requests `/admin/users`
- **THEN** the response contains only one page of users ordered by newest users first
- **AND** the response contains pagination metadata and links for moving between pages

#### Scenario: User row fields
- **GIVEN** an admin opens the users directory
- **WHEN** the users table renders
- **THEN** each row shows display name, email, role, status, locale, and created date
- **AND** each row exposes an edit action for that user
- **AND** each row exposes a suspend or reactivate action matching the user's current status

#### Scenario: Search users
- **GIVEN** users exist with different emails and display names
- **WHEN** an admin searches the users directory by email or display-name text
- **THEN** the response contains only matching users
- **AND** the current search term remains visible in the search field

#### Scenario: Empty search result
- **GIVEN** no users match the current search term
- **WHEN** an admin opens the filtered users directory
- **THEN** the page renders an empty state instead of an empty broken table

### Requirement: Admin user edit form
The system SHALL allow admins to edit only a user's display name, role, and
status from an individual admin edit page.

#### Scenario: Edit page
- **GIVEN** an admin opens an individual user's edit page
- **WHEN** the page renders
- **THEN** the form contains editable controls for display name, role, and status
- **AND** the page shows email, locale, created date, and updated date as read-only details
- **AND** the page contains no password field or password-management action

#### Scenario: Allowed update
- **GIVEN** an admin submits a valid display name, role, and status for a user
- **WHEN** the update succeeds
- **THEN** the system stores only those editable attributes
- **AND** the system redirects back to the admin users directory with a success message

#### Scenario: Disallowed fields ignored
- **GIVEN** an admin submits email, locale, password, password digest, identity, or session fields with the edit form
- **WHEN** the update is processed
- **THEN** the system does not change those disallowed attributes or credential records

#### Scenario: Invalid update
- **GIVEN** an admin submits an invalid role or status
- **WHEN** the update fails validation
- **THEN** the system re-renders the edit page with validation feedback
- **AND** the original user record is not changed

### Requirement: List-level user status action
The system SHALL allow admins to suspend or reactivate a user directly from the
users directory without editing other user attributes.

#### Scenario: Suspend active user
- **GIVEN** an active user appears in the admin users directory
- **WHEN** an admin chooses the suspend action for that user
- **THEN** the system changes that user's status to `suspended`
- **AND** the system redirects back to the users directory with a success message

#### Scenario: Reactivate suspended user
- **GIVEN** a suspended user appears in the admin users directory
- **WHEN** an admin chooses the reactivate action for that user
- **THEN** the system changes that user's status to `active`
- **AND** the system redirects back to the users directory with a success message

#### Scenario: Status action preserves other fields
- **GIVEN** an admin submits a status action for a user
- **WHEN** the action succeeds
- **THEN** the system does not change the user's role, display name, email, locale, identity records, session records, or password digest
