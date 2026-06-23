# Frontend Platform Specification

## Purpose

Define the implemented build, runtime, migration, quality, and delivery
contracts for the application-owned Vite, Inertia, React, TypeScript, and
Tailwind frontend.

## Requirements

### Requirement: Reproducible frontend build
The system SHALL compile the business frontend from locked npm dependencies into fingerprinted assets that Rails can serve in development, test, and production.

#### Scenario: Clean dependency install and build
- **GIVEN** a clean checkout with the repository-supported Node and npm versions
- **WHEN** the frontend dependencies are installed from the lockfile and the production build runs
- **THEN** the build succeeds without modifying the lockfile
- **AND** it produces a Rails-resolvable frontend asset manifest and compiled entrypoints

#### Scenario: Missing compiled production assets
- **GIVEN** the application is configured to use production frontend assets
- **WHEN** the required manifest or entrypoint is absent
- **THEN** verification fails instead of silently serving an incomplete business page

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
- **THEN** the required styles are present in the same compiled stylesheet family

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
- **GIVEN** Rails redirects to a migrated page with an allowed notice or alert flash
- **WHEN** the Inertia page renders
- **THEN** the shell presents the message with the matching status or alert semantics
- **AND** the one-time message does not become regular history-persisted shared data

#### Scenario: Shared shell prop exposure
- **GIVEN** Rails prepares shared data for an Inertia response
- **WHEN** the data is serialized
- **THEN** it contains only namespaced translated labels, Rails-generated navigation URLs, and the authentication state required by the shell
- **AND** it excludes credentials, raw session data, reset tokens, unnecessary user attributes, and policy internals

#### Scenario: Engine destination
- **GIVEN** a shell or page link targets external Rails engine UI
- **WHEN** the visitor follows that link
- **THEN** the browser performs a full document visit when needed
- **AND** application-owned business pages remain under the Inertia runtime

### Requirement: Typed Rails-to-React page contract
The system SHALL provide explicit TypeScript types for shared and page-specific Inertia props while Rails remains the source of user-facing translations, formatted display values, and application URLs.

#### Scenario: Waterfall detail props
- **GIVEN** the published waterfall detail route is enabled
- **WHEN** Rails renders its Inertia page
- **THEN** the page receives typed public waterfall content, translated display copy, formatted detail values, and typed application URLs through props
- **AND** the React page renders those values without importing Rails locale files, duplicating domain formatting, or using a generated route catalog

#### Scenario: Frontend type error
- **GIVEN** a page or component violates its declared shared or page-specific prop contract
- **WHEN** the frontend typecheck runs
- **THEN** verification fails before the application build is accepted

#### Scenario: Sensitive server state
- **GIVEN** Rails prepares shared or page-specific Inertia props
- **WHEN** the response is serialized
- **THEN** it omits credentials, raw session tokens, password-reset tokens, policy internals, unpublished state, and other server-only material

### Requirement: JavaScript-required Inertia shell
The system SHALL make the CSR requirement explicit for Inertia pages while keeping production application scripts and styles same-origin.

#### Scenario: JavaScript unavailable
- **GIVEN** a visitor opens an Inertia page without JavaScript
- **WHEN** the root document is rendered
- **THEN** it contains a localized message explaining that JavaScript is required

#### Scenario: Production asset policy
- **GIVEN** the application runs in production
- **WHEN** an Inertia page loads its application entrypoints
- **THEN** the scripts and styles are served from the application origin

#### Scenario: Development asset policy
- **GIVEN** the approved Vite development server is running
- **WHEN** a developer opens an Inertia page
- **THEN** development-only content security policy allowances permit its assets and live-reload connection
- **AND** those allowances are absent from production policy

### Requirement: Frontend quality gate
The system SHALL provide deterministic formatting, linting, accessibility, typechecking, component-test, production-build, and dependency-audit checks for frontend changes.

#### Scenario: Valid frontend change
- **GIVEN** frontend source and tests satisfy the configured rules
- **WHEN** the frontend verification gate runs in non-watch mode
- **THEN** formatting, linting, typechecking, component tests, coverage collection, production build, and dependency audit complete successfully

#### Scenario: Invalid accessible interaction
- **GIVEN** a shared interactive React component violates configured static or component-level accessibility checks
- **WHEN** frontend lint or tests run
- **THEN** verification fails with an actionable error

#### Scenario: Vulnerable npm dependency
- **GIVEN** the locked npm dependency graph contains a vulnerability at or above the configured blocking severity
- **WHEN** the frontend dependency audit runs
- **THEN** verification fails unless a precise reviewed exception is recorded

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

### Requirement: Rails integration proof
The system SHALL prove the frontend platform through production business pages
and SHALL remove superseded development/test smoke or legacy page surfaces as
their routes migrate.

#### Scenario: Production business page
- **GIVEN** a published waterfall exists
- **WHEN** a visitor opens its detail route in development, test, or production
- **THEN** Rails returns the expected Inertia component and props
- **AND** React renders the page through the shared application shell and frontend styles

#### Scenario: Browser integration
- **GIVEN** frontend assets are built
- **WHEN** the waterfall detail route is exercised by request, component, and browser tests
- **THEN** the tests prove the Rails-to-Inertia-to-React response contract, client rendering, accessible interaction, and route-boundary navigation

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
- **GIVEN** the production waterfall detail route proves the frontend runtime chain
- **WHEN** application routes and frontend pages are inspected
- **THEN** no development/test smoke route, controller, page, copy, or dedicated smoke test remains

#### Scenario: Legacy stack retirement proof
- **GIVEN** all current application-owned business pages render through Inertia
- **WHEN** the repository is inspected
- **THEN** no application-owned legacy business frontend runtime, component
  layer, or page layout remains

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
- **AND** the browser reaches the Inertia sign-in page after Rails completes the
  redirect

#### Scenario: Dashboard legacy template retirement
- **GIVEN** request, component, accessibility, and browser tests prove the
  migrated Dashboard behavior
- **WHEN** application-owned Dashboard templates are inspected
- **THEN** the superseded Dashboard ERB page template no longer exists

### Requirement: Integrated delivery pipeline
The system SHALL include frontend installation, verification, and asset compilation in the supported local, CI, and production Docker workflows.

#### Scenario: Local development startup
- **GIVEN** dependencies are installed
- **WHEN** the supported development command starts the application
- **THEN** Rails and the Vite development process run together with frontend changes available to the browser

#### Scenario: Continuous integration
- **GIVEN** a pull request changes frontend or application integration files
- **WHEN** CI runs
- **THEN** it installs locked npm dependencies and executes the frontend quality gate alongside the existing Rails gates
- **AND** it does not run retired Importmap, Turbo, Stimulus, or ViewComponent
  business frontend checks

#### Scenario: Production image build
- **GIVEN** a clean production Docker build
- **WHEN** the image is assembled
- **THEN** frontend assets are compiled during the build
- **AND** the final Rails runtime image can serve them without running a Node or SSR process
