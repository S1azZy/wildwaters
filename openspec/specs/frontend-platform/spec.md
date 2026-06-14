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

### Requirement: Typed Rails-to-React page contract
The system SHALL provide explicit TypeScript types for shared and page-specific Inertia props while Rails remains the source of user-facing translations and application URLs.

#### Scenario: Smoke page props
- **GIVEN** the non-production smoke route is enabled
- **WHEN** Rails renders its Inertia page
- **THEN** the page receives typed translated text and typed application URLs through props
- **AND** the React page renders those values without importing Rails locale files or a generated route catalog

#### Scenario: Frontend type error
- **GIVEN** a page or component violates its declared prop contract
- **WHEN** the frontend typecheck runs
- **THEN** verification fails before the application build is accepted

#### Scenario: Sensitive server state
- **GIVEN** Rails prepares shared or page-specific Inertia props
- **WHEN** the response is serialized
- **THEN** it omits credentials, raw session tokens, password-reset tokens, and other server-only secret material

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
- **WHEN** a developer opens the smoke page
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
The system SHALL prove the frontend foundation through a development/test-only Inertia smoke page without adding a production product route.

#### Scenario: Development smoke page
- **GIVEN** the application runs in development
- **WHEN** a developer opens the smoke route
- **THEN** Rails returns the expected Inertia component and props
- **AND** the React page renders with the shared frontend styles

#### Scenario: Test smoke page
- **GIVEN** the application runs in test
- **WHEN** the smoke route is exercised by request and browser tests
- **THEN** the tests prove the Inertia response contract and client rendering

#### Scenario: Production route absence
- **GIVEN** the application runs in production
- **WHEN** the smoke path is requested
- **THEN** the application does not expose the development/test smoke route

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
