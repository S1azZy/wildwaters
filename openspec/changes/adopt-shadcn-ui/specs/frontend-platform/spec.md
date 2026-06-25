## ADDED Requirements

### Requirement: Shadcn dependency and build integration
The system SHALL treat shadcn-generated component source and its locked npm
dependencies as first-class inputs to the business frontend build.

#### Scenario: Locked shadcn dependency graph
- **WHEN** frontend dependencies are installed from the lockfile
- **THEN** shadcn-required packages are resolved from the locked npm graph
- **AND** the install does not require a separate frontend package manager or
  runtime outside the existing repository contract

#### Scenario: Production build with shadcn primitives
- **GIVEN** an Inertia page imports shared shadcn-backed primitives
- **WHEN** the production frontend build runs
- **THEN** the page compiles into Rails-resolvable frontend assets with the
  shared shadcn and Digital Naturalist styles present

#### Scenario: Frontend quality gate covers UI kit
- **WHEN** the frontend verification gate runs
- **THEN** formatting, linting, typechecking, component tests, production build,
  and dependency audit cover shadcn-generated source and Wild Waters wrappers
