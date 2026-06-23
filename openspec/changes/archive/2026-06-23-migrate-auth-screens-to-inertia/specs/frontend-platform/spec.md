## MODIFIED Requirements

### Requirement: Rails integration proof
The system SHALL prove the frontend platform through production business pages and SHALL remove superseded development/test smoke or legacy page surfaces as their routes migrate.

#### Scenario: Migrated auth screens
- **GIVEN** a visitor opens an application-owned authentication screen
- **WHEN** Rails renders sign-in, registration, password-reset request, or
  password-reset edit
- **THEN** Rails returns the expected Inertia component and typed props
- **AND** React renders the page through the shared application shell and
  preserved auth-screen styles
- **AND** no superseded application-owned auth ERB page template remains after
  parity coverage passes

#### Scenario: Auth form browser integration
- **GIVEN** frontend assets are built
- **WHEN** the migrated auth forms are exercised by request, component, and
  browser tests
- **THEN** the tests prove the Rails-to-Inertia-to-React response contract,
  CSRF-backed form submission, accessible interaction, safe validation
  rendering, flash, and necessary legacy-boundary navigation
