## ADDED Requirements

### Requirement: Admin service actions page
The system SHALL provide an application-owned service-actions page inside an
admin namespace protected by Wild Waters admin authorization.

#### Scenario: Guest access
- **GIVEN** a visitor has no active application session
- **WHEN** the visitor requests `/admin` or `/admin/service-actions`
- **THEN** the system redirects to application sign-in with an
  authentication-required message

#### Scenario: Member access
- **GIVEN** an authenticated user whose role is `member`
- **WHEN** the user requests `/admin` or `/admin/service-actions`
- **THEN** the system redirects to the explore homepage with an admin-required
  message

#### Scenario: Admin access
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** the user requests `/admin` or `/admin/service-actions`
- **THEN** the system renders the service-actions page as an Inertia response
  inside the admin shell
- **AND** the response exposes no raw session material, credentials, user
  object, role field, or policy internals

### Requirement: Admin shell layout
The system SHALL render the first admin page with a top toolbar, a left
sidebar, and a central working area built from the approved React frontend and
shadcn-backed component foundation.

#### Scenario: Service actions navigation
- **GIVEN** an admin opens the admin service-actions page
- **WHEN** the admin shell renders
- **THEN** the sidebar shows service actions as the only subsection
- **AND** service actions is marked as the current subsection
- **AND** the central workspace renders a placeholder for future service
  command controls

#### Scenario: Placeholder has no operational side effect
- **GIVEN** an admin opens the service-actions page
- **WHEN** the page renders
- **THEN** it does not enqueue imports, start jobs, retry imports, or render an
  enabled service command action
