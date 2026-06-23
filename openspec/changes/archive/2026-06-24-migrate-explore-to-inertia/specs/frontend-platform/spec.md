## MODIFIED Requirements

### Requirement: Rails integration proof
The system SHALL prove the frontend platform through production business pages
and SHALL remove superseded development/test smoke or legacy page surfaces as
their routes migrate.

#### Scenario: Migrated explore homepage
- **GIVEN** a visitor opens the public explore homepage or waterfall index
- **WHEN** Rails renders the response
- **THEN** Rails returns the expected `Waterfalls/Index` Inertia component and
  typed public props
- **AND** React renders the page through the shared application shell and
  preserved explore styles
- **AND** no superseded application-owned explore ERB template, waterfall card
  partial, or Stimulus map controller remains after parity coverage passes

#### Scenario: Explore browser integration
- **GIVEN** frontend assets are built
- **WHEN** the migrated explore page is exercised by request, component, and
  browser tests
- **THEN** the tests prove the Rails-to-Inertia-to-React response contract,
  client rendering, accessible interaction, local MapLibre assets, filtered
  public results, and runtime isolation from importmap, Turbo, and Stimulus
