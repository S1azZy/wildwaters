## Why

All application-owned business routes now render through Vite, Inertia, React,
TypeScript, and Tailwind. The temporary legacy frontend stack remains installed
even though no business route should depend on it, which keeps obsolete runtime,
dependency, CI, and test surfaces alive.

This is a Level 2 specified feature because it changes the frontend delivery
contract and verification surface. It does not require a new ADR because ADR
0005 already records the durable architecture decision and explicitly calls for
this final cleanup after migrated routes stop consuming the old stack.

## What Changes

- Remove the retired application-owned ERB/Hotwire/Stimulus/ViewComponent
  business frontend stack from direct app dependencies, source files, tests, and
  CI checks.
- Keep Vite, Inertia Rails, React, TypeScript, Tailwind, Propshaft-served static
  assets, mailer ERB templates, Inertia layout ERB, and external Rails engine UI
  support.
- Update documentation and tooling assertions so the supported frontend
  architecture is no longer described as a temporary dual-runtime migration.
- Preserve existing business behavior for public discovery, authentication,
  password reset, Dashboard, JSON map data, mailers, and Mission Control Jobs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `frontend-platform`: Replace the temporary dual-runtime migration contract
  with the completed Inertia-only business frontend contract and legacy stack
  retirement requirements.
- `design-system-shell`: Replace the retired ViewComponent shared-control API
  contract with the React-rendered shell, form, flash, and accessibility
  contract.

## Impact

- Affected dependencies: `Gemfile`, `Gemfile.lock`, Rails initializer/runtime
  files, CI commands, and bin scripts related to application-owned Importmap,
  Turbo, Stimulus, and ViewComponent usage. Transitive dependencies required by
  Mission Control Jobs remain outside the business frontend boundary.
- Affected source: legacy `app/javascript`, retired ViewComponent classes and
  templates, the superseded legacy application layout, and their specs.
- Affected docs/specs: frontend platform OpenSpec baseline, context maps, ADR
  implementation notes, and `CHANGES.md`.
- Risks: accidental removal of assets still needed by Inertia pages, stale test
  assertions around the former legacy runtime, and production build regressions.
  Verification must include frontend checks, Rails request/system specs, and
  production asset build coverage.
