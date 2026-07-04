## ADDED Requirements

### Requirement: Protected admin Inertia integration
The system SHALL deliver application-owned admin pages through the existing
Inertia React frontend runtime while Rails retains routes, sessions,
authorization, localization, and data selection.

#### Scenario: Admin page runtime
- **GIVEN** an authenticated admin opens the application-owned admin page
- **WHEN** Rails renders the response
- **THEN** Rails returns the expected Admin Inertia component and typed props
- **AND** the response loads the React frontend entrypoint through the Inertia
  layout
- **AND** it does not require Turbo, Stimulus, Importmap, SSR, or a separate
  frontend application

#### Scenario: Admin page typed props
- **GIVEN** Rails prepares the application-owned admin page response
- **WHEN** the response is serialized
- **THEN** the page receives localized display-ready copy, Rails-generated admin
  navigation URLs, and the shared shell contract
- **AND** React renders those props without importing Rails locale files,
  duplicating route generation, or receiving server-only authorization state
