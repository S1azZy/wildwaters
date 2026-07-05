## MODIFIED Requirements

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
