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
The system SHALL keep each application route under one browser-rendering runtime during migration.

#### Scenario: Legacy route
- **GIVEN** a business route has not migrated to Inertia
- **WHEN** the route is rendered
- **THEN** it uses the legacy Rails page runtime
- **AND** it receives the shared stylesheet compiled by the frontend build

#### Scenario: Inertia route
- **GIVEN** a route is implemented as an Inertia page
- **WHEN** the route is rendered
- **THEN** it loads the React frontend entrypoint
- **AND** it does not load Turbo, Stimulus, or the importmap application entrypoint

#### Scenario: Cross-runtime navigation
- **GIVEN** navigation crosses between a legacy route and an Inertia route
- **WHEN** the visitor follows the navigation
- **THEN** the browser performs a full document visit without requiring both runtimes to own the same page

### Requirement: Shared visual foundation
The system SHALL compile the existing Digital Naturalist design tokens and Tailwind styles for both legacy and Inertia pages without requiring parallel Tailwind compilers.

#### Scenario: Legacy page after compiler migration
- **GIVEN** an existing ERB business page
- **WHEN** the page is rendered after Tailwind compilation moves to the frontend build
- **THEN** its referenced utility classes and semantic design tokens are present in the compiled stylesheet

#### Scenario: React page styling
- **GIVEN** an Inertia React page uses the shared tokens and Tailwind utilities
- **WHEN** the frontend assets are built
- **THEN** the required styles are present in the same compiled stylesheet family

### Requirement: Shared React application shell
The system SHALL provide migrated business pages with a typed React application shell that preserves the current site identity, navigation actions, content frame, document title, and accessible flash presentation.

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

#### Scenario: Legacy destination
- **GIVEN** a shell or page link targets an unmigrated Rails route
- **WHEN** the visitor follows that link
- **THEN** the browser performs a full document visit to the legacy page
- **AND** the legacy route remains owned by Turbo, Stimulus, and importmap

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

### Requirement: Rails integration proof
The system SHALL prove the frontend platform through a production waterfall detail Inertia page and SHALL remove the superseded development/test smoke surface.

#### Scenario: Production business page
- **GIVEN** a published waterfall exists
- **WHEN** a visitor opens its detail route in development, test, or production
- **THEN** Rails returns the expected Inertia component and props
- **AND** React renders the page through the shared application shell and frontend styles

#### Scenario: Browser integration
- **GIVEN** frontend assets are built
- **WHEN** the waterfall detail route is exercised by request, component, and browser tests
- **THEN** the tests prove the Rails-to-Inertia-to-React response contract, client rendering, accessible interaction, and legacy-boundary navigation

#### Scenario: Smoke surface retirement
- **GIVEN** the production waterfall detail route proves the frontend runtime chain
- **WHEN** application routes and frontend pages are inspected
- **THEN** no development/test smoke route, controller, page, copy, or dedicated smoke test remains

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

#### Scenario: Production image build
- **GIVEN** a clean production Docker build
- **WHEN** the image is assembled
- **THEN** frontend assets are compiled during the build
- **AND** the final Rails runtime image can serve them without running a Node or SSR process
