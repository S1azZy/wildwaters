## Why

Wild Waters needs a typed, testable client-rendered frontend foundation before
its business pages can move from ERB, Hotwire, Stimulus, and ViewComponent to
React one route at a time. Establishing the build, runtime, testing, security,
and deployment contracts first keeps later page migrations small and prevents
the application from accumulating two permanent frontend architectures.

This is a Level 3 architectural change because it selects durable technologies,
changes the asset and page-delivery boundaries, and affects development,
testing, CI, and production builds across the application.

## What Changes

- Add a Vite, Inertia Rails, React, and strict TypeScript frontend foundation
  that can coexist with the current Rails-rendered business pages.
- Move Tailwind compilation and the existing design tokens into the Vite/npm
  pipeline while preserving the current visual output for unmigrated pages.
- Add frontend formatting, linting, accessibility, typechecking, component
  testing, dependency auditing, and production-build gates.
- Integrate the frontend pipeline with local development, Docker production
  builds, Make targets, and CI.
- Add a development/test-only Inertia smoke page that proves Rails-to-React
  props, Rails-provided translations and URLs, CSRF-aware navigation, shared
  styling, and the frontend test harness.
- Keep every existing business route on its current rendering stack during this
  change. Product routes will migrate atomically in later OpenSpec changes.
- Record the target frontend architecture and coexistence rules in a new ADR,
  and reconcile the older map and design-system ADRs with that decision.
- **BREAKING** for the development toolchain: npm becomes part of the
  application build and verification path rather than serving OpenSpec alone.

Expected outcome: the repository can build, test, run, and deploy one
non-production Inertia React page alongside unchanged ERB pages, providing a
verified base for later vertical migrations.

Non-goals:

- migrating a business page;
- adding server-side rendering;
- redesigning the current interface;
- adding a UI kit, client router, route generator, global state library, or
  client data-fetching framework;
- replacing Rails I18n, Rails routes, Rails sessions, CSRF protection, or
  existing business use cases;
- changing mailer templates or the Mission Control Jobs engine UI.

Assumptions:

- business pages may require JavaScript after they migrate;
- Rails remains the owner of HTTP routing, authentication, authorization,
  localization, and business logic;
- the existing npm and Node runtime remain the package-manager and JavaScript
  runtime baseline;
- the smoke route is removed after the first business page migration proves the
  platform.

Unresolved questions are limited to implementation research within the approved
direction: exact compatible package versions, final lint plugin configuration,
and whether initial accessibility assertions use axe in component tests or a
closely equivalent maintained adapter.

## Capabilities

### New Capabilities

- `frontend-platform`: Build, runtime, coexistence, quality-gate, and
  non-production smoke behavior for the Vite/Inertia/React/TypeScript
  foundation.

### Modified Capabilities

None. Existing business-page behavior remains unchanged in this foundation
change.

## Impact

Affected systems include Ruby and npm dependencies, the asset pipeline,
application layout integration, development process management, Docker build
stages, CI jobs, Make verification targets, frontend security auditing, and
test configuration. Existing ERB pages and their request/system behavior must
remain operational while loading CSS compiled through Vite.

The main risks requiring special verification are production asset
availability, development server fallback behavior, CSP and CSRF compatibility,
cache-busted asset references, Docker image reproducibility, npm supply-chain
findings, and accidental regressions in the unmigrated ERB pages.

A new ADR is required because the chosen frontend stack, Rails/React ownership
boundary, CSR-first delivery, route-level migration rule, and retirement path
must remain understandable after this change is archived.
