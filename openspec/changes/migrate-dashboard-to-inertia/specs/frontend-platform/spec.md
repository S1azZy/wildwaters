## ADDED Requirements

### Requirement: Protected Dashboard Inertia integration
The system SHALL deliver the protected Dashboard placeholder as a typed Inertia
React page while Rails retains authentication, localization, session mutation,
and redirect ownership.

#### Scenario: Typed dashboard page contract
- **GIVEN** an authenticated user opens the Dashboard
- **WHEN** Rails prepares the Inertia response
- **THEN** the page receives only the authenticated shared shell, translated
  display-ready Dashboard copy, and the Rails-generated sign-out URL
- **AND** the React page renders those props without importing Rails locale
  files or receiving a general user object

#### Scenario: Isolated dashboard runtime
- **GIVEN** the Dashboard route has migrated
- **WHEN** an authenticated user opens it
- **THEN** the response loads the React frontend entrypoint through the Inertia
  layout
- **AND** it does not load Turbo, Stimulus, or the importmap application
  entrypoint

#### Scenario: Dashboard sign-out interaction
- **GIVEN** the migrated Dashboard is rendered
- **WHEN** the user activates sign-out
- **THEN** an accessible button initiates the Rails-owned session deletion
  through the supported Inertia request transport
- **AND** the browser reaches the legacy sign-in page after Rails completes the
  redirect

#### Scenario: Dashboard legacy template retirement
- **GIVEN** request, component, accessibility, and browser tests prove the
  migrated Dashboard behavior
- **WHEN** application-owned Dashboard templates are inspected
- **THEN** the superseded Dashboard ERB page template no longer exists
