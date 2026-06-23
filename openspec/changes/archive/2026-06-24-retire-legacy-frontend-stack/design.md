## Context

ADR 0005 selected Vite, Inertia Rails, React, TypeScript, and Tailwind as the
application-owned business frontend architecture. The route-by-route migration
has now moved the current business surfaces to Inertia: public explore,
waterfall detail, authentication/password-reset screens, and Dashboard.

The remaining old stack is implementation residue: Importmap, Turbo, Stimulus,
ViewComponent, the legacy application layout, `app/javascript`, Ruby UI
components, component specs, and CI/tooling checks that were only useful while a
business route still consumed legacy Rails UI. Mailer ERB, the Inertia layout
ERB, static Rails/PWA templates, Propshaft-managed static assets, and external
Rails engine UI are outside this cleanup.

## Goals / Non-Goals

**Goals:**

- Remove unused application-owned Importmap, Turbo, Stimulus, and ViewComponent
  direct dependencies and source files.
- Keep all current business routes rendering through the existing Inertia
  pages, typed props, React shell, and Vite-built CSS/JS.
- Update specs, docs, tooling assertions, and CI so the repository no longer
  treats the retired legacy frontend stack as supported.
- Preserve mailer templates, Mission Control Jobs, and Rails-owned technical
  templates that are not business frontend pages.

**Non-Goals:**

- Do not redesign the UI, change page copy, introduce SSR, or adopt a UI kit.
- Do not remove Propshaft or vendored static assets still used by Vite/Inertia
  pages.
- Do not change authentication, authorization, map filtering, mail delivery, or
  Mission Control Jobs behavior.

## Decisions

### Remove the old stack at dependency and source level

The cleanup removes direct app gems and files instead of leaving dormant
compatibility paths. Keeping an unused stack would make future agents and CI
believe that legacy business routes remain supported. Importmap/Turbo/Stimulus
may still appear as transitive dependencies of Mission Control Jobs; that is
engine-owned UI, not application-owned business frontend runtime.

Alternatives considered:

- Keep the gems but delete source files. This would reduce file churn but keep
  stale dependency, audit, and boot surfaces.
- Keep the old layout and ViewComponents for possible future admin UI. ADR 0005
  says new application-owned admin UI uses the new frontend architecture, so
  retaining the old layer would work against that direction.

### Keep ERB only where Rails still owns non-business templates

The Inertia root document remains an ERB layout because Rails must inject Vite
tags, CSP nonces, Inertia head data, and localized no-JavaScript copy. Mailer
ERB and Rails/PWA technical templates are not part of the business frontend
runtime and do not block retirement of the old stack.

### Update verification to prove absence, not coexistence

Existing specs prove that migrated routes do not load importmap/Turbo/Stimulus.
The cleanup adds or updates tooling specs to assert the retired files,
dependencies, and CI checks are gone. Browser/request/component coverage remains
responsible for business behavior parity.

### No new ADR

ADR 0005 already records the durable architecture decision and explicitly
requires final cleanup after no application-owned business route consumes the
old stack. This change updates OpenSpec and implementation state to match that
decision.

## Risks / Trade-offs

- [Hidden legacy consumer] -> Verify all controllers/routes and system specs
  still pass after deleting the old layout, components, and JavaScript entrypoint.
- [Asset regression] -> Run frontend build/verification and Rails system specs
  so Vite-managed CSS and vendored MapLibre assets remain available.
- [Stale docs/tests] -> Update frontend-platform specs, tooling specs,
  context-map rows, and CHANGES in the same PR.
- [Engine UI confusion] -> Keep Mission Control Jobs mounted behind the
  existing admin guard; do not attempt to rewrite or test its internal views.

## Migration Plan

1. Add specs/tooling assertions for the completed Inertia-only business frontend
   boundary and retired legacy stack.
2. Remove legacy frontend dependencies, source files, layout, component layer,
   specs, CI checks, and stale docs.
3. Refresh the bundle lockfile in the container.
4. Run OpenSpec validation and project verification.

Rollback is standard git revert. No data migration or persistent state change is
involved.

## Open Questions

None.
