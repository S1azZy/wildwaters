## ADDED Requirements

### Requirement: Retired legacy business frontend stack
The system SHALL remove the retired application-owned ERB, Importmap, Turbo,
Stimulus, and ViewComponent business frontend stack after all current business
routes migrate to Inertia.

#### Scenario: Direct legacy runtime dependencies retired
- **WHEN** application dependencies and CI checks are inspected
- **THEN** Importmap, Turbo, Stimulus, and ViewComponent are absent from the
  direct application-owned business frontend runtime
- **AND** CI no longer runs Importmap-specific audit checks
- **AND** transitive dependencies required by external Rails engine UI do not
  count as application-owned business frontend runtime

#### Scenario: Legacy source surfaces retired
- **WHEN** application-owned frontend source files are inspected
- **THEN** the repository contains no legacy `app/javascript` business entrypoint
  or Stimulus controllers
- **AND** it contains no application-owned ViewComponent UI layer or legacy
  business application layout

#### Scenario: Non-business ERB remains allowed
- **WHEN** Rails templates are inspected
- **THEN** mailer templates, the Inertia root layout, and Rails-owned technical
  templates MAY remain
- **AND** external Rails engine UI such as Mission Control Jobs does not block
  legacy business frontend retirement

## MODIFIED Requirements

### Requirement: Isolated frontend runtime ownership
The system SHALL keep application-owned business routes under the Inertia React
browser runtime.

#### Scenario: Inertia route
- **GIVEN** a route is implemented as an application-owned business page
- **WHEN** the route is rendered
- **THEN** it loads the React frontend entrypoint
- **AND** it does not load Turbo, Stimulus, or the importmap application
  entrypoint

#### Scenario: External engine navigation
- **GIVEN** navigation targets external Rails engine UI
- **WHEN** the visitor follows the navigation
- **THEN** the browser may perform a full document visit
- **AND** the application does not require its retired legacy business frontend
  runtime for that engine surface

### Requirement: Shared visual foundation
The system SHALL compile the Digital Naturalist design tokens and Tailwind
styles for the application-owned Inertia business frontend without requiring
parallel Tailwind or legacy Rails UI compilers.

#### Scenario: React page styling
- **GIVEN** an Inertia React page uses the shared tokens and Tailwind utilities
- **WHEN** the frontend assets are built
- **THEN** the required styles are present in the compiled stylesheet family

#### Scenario: Legacy compiler retirement
- **WHEN** frontend build tooling is inspected
- **THEN** the application does not require a separate legacy Tailwind,
  Importmap, Turbo, Stimulus, or ViewComponent build path for business routes

### Requirement: Shared React application shell
The system SHALL provide migrated business pages with a typed React application
shell that preserves the current site identity, navigation actions, content
frame, document title, and accessible flash presentation.

#### Scenario: Guest shell
- **GIVEN** a visitor is not authenticated
- **WHEN** a migrated business page renders
- **THEN** the shell displays the translated brand and Explore navigation
- **AND** it displays the sign-in action without exposing user or session data

#### Scenario: Authenticated shell
- **GIVEN** a visitor is authenticated
- **WHEN** a migrated business page renders
- **THEN** the shell displays the profile action targeting the Rails dashboard
- **AND** it does not display the guest sign-in action

#### Scenario: Shell flash message
- **GIVEN** Rails redirects to a migrated page with an allowed notice or alert
  flash
- **WHEN** the Inertia page renders
- **THEN** the shell presents the message with the matching status or alert
  semantics
- **AND** the one-time message does not become regular history-persisted shared
  data

#### Scenario: Shared shell prop exposure
- **GIVEN** Rails prepares shared data for an Inertia response
- **WHEN** the data is serialized
- **THEN** it contains only namespaced translated labels, Rails-generated
  navigation URLs, and the authentication state required by the shell
- **AND** it excludes credentials, raw session data, reset tokens, unnecessary
  user attributes, and policy internals

#### Scenario: Engine destination
- **GIVEN** a shell or page link targets external Rails engine UI
- **WHEN** the visitor follows that link
- **THEN** the browser performs a full document visit when needed
- **AND** application-owned business pages remain under the Inertia runtime

### Requirement: Rails integration proof
The system SHALL prove the frontend platform through production business pages
and SHALL remove superseded development/test smoke or legacy page surfaces as
their routes migrate.

#### Scenario: Production business page
- **GIVEN** a published waterfall exists
- **WHEN** a visitor opens its detail route in development, test, or production
- **THEN** Rails returns the expected Inertia component and props
- **AND** React renders the page through the shared application shell and
  frontend styles

#### Scenario: Browser integration
- **GIVEN** frontend assets are built
- **WHEN** the waterfall detail route is exercised by request, component, and
  browser tests
- **THEN** the tests prove the Rails-to-Inertia-to-React response contract,
  client rendering, accessible interaction, and route-boundary navigation

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
  rendering, flash, and necessary document navigation

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

#### Scenario: Smoke surface retirement
- **GIVEN** the production waterfall detail route proves the frontend runtime
  chain
- **WHEN** application routes and frontend pages are inspected
- **THEN** no development/test smoke route, controller, page, copy, or dedicated
  smoke test remains

#### Scenario: Legacy stack retirement proof
- **GIVEN** all current application-owned business pages render through Inertia
- **WHEN** the repository is inspected
- **THEN** no application-owned legacy business frontend runtime, component
  layer, or page layout remains

### Requirement: Integrated delivery pipeline
The system SHALL include frontend installation, verification, and asset
compilation in the supported local, CI, and production Docker workflows.

#### Scenario: Local development startup
- **GIVEN** dependencies are installed
- **WHEN** the supported development command starts the application
- **THEN** Rails and the Vite development process run together with frontend
  changes available to the browser

#### Scenario: Continuous integration
- **GIVEN** a pull request changes frontend or application integration files
- **WHEN** CI runs
- **THEN** it installs locked npm dependencies and executes the frontend quality
  gate alongside the existing Rails gates
- **AND** it does not run retired Importmap, Turbo, Stimulus, or ViewComponent
  business frontend checks

#### Scenario: Production image build
- **GIVEN** a clean production Docker build
- **WHEN** the image is assembled
- **THEN** frontend assets are compiled during the build
- **AND** the final Rails runtime image can serve them without running a Node or
  SSR process
