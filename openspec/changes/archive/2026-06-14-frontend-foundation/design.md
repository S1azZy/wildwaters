## Context

Wild Waters currently renders its business UI with ERB, ViewComponent,
Hotwire/Stimulus, importmap, Propshaft, and Tailwind compiled by
`tailwindcss-rails`. The repository already pins Node and npm for OpenSpec, but
Node is not part of the application build, Docker production stage, or main
test job. The public map additionally vendors MapLibre through Rails assets.

The approved target is a Rails monolith whose own business and future admin
pages are delivered through Inertia and rendered by React with TypeScript.
Rails continues to own routes, HTTP controllers, sessions, CSRF,
authorization, I18n, business use cases, and server-side data selection.
Mailer ERB and the Mission Control Jobs engine UI remain outside the migration.

Research on 2026-06-14 supports the following implementation baseline:

- `vite_rails` 3.11.0 with Vite 8.0.16;
- `inertia_rails` 3.21.2 with Inertia React 3.4.0;
- React 19.2.7;
- TypeScript 6.0.3 in strict mode;
- Tailwind CSS 4.3.1 through its Vite integration;
- Vitest 4.1.8.

Implementation MUST resolve and lock exact compatible versions rather than
using floating ranges. Existing Node 24 and npm remain the runtime and package
manager unless compatibility verification disproves that assumption.

The durable architecture is recorded in ADR 0005. This change implements only
the platform foundation and a development/test smoke surface. Later OpenSpec
changes own business-page migration.

## Goals / Non-Goals

**Goals:**

- establish a reproducible Vite/Inertia/React/TypeScript application build;
- preserve current ERB business behavior while both stacks coexist;
- make Vite the single Tailwind compiler for legacy and React pages;
- prove development, test, CI, security-audit, and production build paths;
- establish typed page props and explicit Rails/React ownership boundaries;
- establish a maintainable frontend quality and testing baseline;
- provide a safe route-by-route migration and rollback mechanism.

**Non-Goals:**

- migrate waterfall, authentication, dashboard, or map behavior;
- add SSR or require the Node runtime in production;
- redesign Digital Naturalist or change its design tokens;
- adopt a UI kit, client-side router, generated Rails route mirror, global state
  store, or general client-fetching library;
- introduce a public JSON API;
- remove importmap, Turbo, Stimulus, ViewComponent, Propshaft, or legacy
  JavaScript in this change;
- set a blocking frontend coverage percentage before representative business
  pages exist.

## Decisions

### Use Rails plus Inertia rather than React islands or a separate SPA

Each migrated route returns an Inertia page with serializable props. React owns
that page's rendering and local interaction state; Rails remains the server
application and supplies translated copy and URLs.

Alternatives:

- React islands inside ERB would make component ownership and final retirement
  ambiguous.
- A separate SPA and JSON API would duplicate routing, authentication, error
  handling, and deployment concerns without a current product need.

### Keep legacy and Inertia page delivery isolated

Coexistence uses two explicit layouts:

- the legacy application layout loads importmap/Turbo/Stimulus plus the
  Vite-built shared stylesheet;
- the Inertia root layout loads Vite React and stylesheet entrypoints and does
  not load importmap, Turbo, or Stimulus.

A business route is entirely legacy or entirely Inertia. Links inside the
Inertia route set use Inertia navigation; navigation across the migration
boundary uses a full document visit. The smoke route is available only in
development and test and is removed after the first business migration.

Loading both JavaScript runtimes in one layout was rejected because Turbo and
Inertia would compete for navigation and lifecycle ownership.

### Use CSR first and retain an SSR-compatible component boundary

The application does not run an Inertia SSR process during this program.
Migrated business UI requires JavaScript and the Inertia layout supplies a
localized `noscript` message. Components must avoid unnecessary browser-global
access during module initialization so later SSR evaluation is possible, but
SSR compatibility is not a blocking gate.

SSR now was rejected because it adds a production Node service, hydration
failure modes, and deployment complexity before release. The investigation is
tracked as low-priority future work.

### Use Vite as the single business-frontend asset compiler

Vite owns React/TypeScript modules and Tailwind 4 CSS. The current semantic
tokens and visual CSS move without redesign into frontend-owned stylesheet
sources. Tailwind source discovery explicitly includes legacy ERB/Ruby
components and React TypeScript files during coexistence.

Propshaft remains available for Rails-owned static assets and unmigrated
MapLibre assets until later changes move or retire them. `tailwindcss-rails` is
removed after parity is proven because maintaining two Tailwind compilers would
create divergent output.

### Use npm with locked application dependencies

The existing root `package.json` and `package-lock.json` become the single
JavaScript dependency set for OpenSpec and the application. Application
runtime packages and build/test tools use exact or repository-approved bounded
versions captured by the lockfile. `npm ci` is the reproducible install path.

The initial package families are:

- runtime: React, React DOM, Inertia React;
- build: Vite, Vite Ruby integration, TypeScript, Tailwind Vite integration;
- quality: ESLint flat config with TypeScript, React, Hooks, and JSX
  accessibility rules; Prettier with ESLint compatibility;
- tests: Vitest, jsdom, React Testing Library, jest-dom, user-event, and an
  axe-core-compatible accessibility assertion adapter.

Exact plugin selection may change if a package is unmaintained or incompatible,
but removing one of these quality concerns requires updating this design.

### Keep Rails as the source of truth for URLs and translated copy

Page-specific URLs and user-facing strings are serialized in props. The
frontend does not import Rails locale files, maintain a second translation
catalog, or generate a JavaScript mirror of Rails routes. Shared TypeScript
types define the common page props; page modules define their own props.

This favors explicit page contracts over a broad global payload. Sensitive
session records, tokens, credentials, policy internals, and unnecessary user
attributes MUST NOT enter Inertia props.

### Establish layered tests without duplicating assertions

- RSpec request specs with Inertia assertions prove component selection, prop
  shape, status, redirects, flash, authentication, and authorization.
- Vitest with React Testing Library proves component rendering and user-visible
  interaction; tests query by accessible roles and labels.
- Axe assertions cover shared controls and critical forms where automated
  component checks add useful signal.
- Existing Capybara/Selenium system specs remain the end-to-end browser layer.
- Snapshot tests are not the default, and implementation details are not a
  stable contract.

Frontend coverage is collected and reported during foundation work without a
blocking percentage. A later decision sets thresholds after two or three real
pages reveal meaningful baselines. Playwright is not added now; its value is
reassessed for the map or admin UI rather than duplicating Selenium immediately.

### Make frontend checks first-class project gates

The frontend command set provides deterministic scripts for:

- format check;
- ESLint;
- TypeScript `--noEmit`;
- Vitest in non-watch mode with coverage reporting;
- Vite production build;
- npm vulnerability audit.

Make targets and `bin/ci` compose these scripts with existing Ruby, ERB, RSpec,
Brakeman, and Bundler checks. Importmap audit remains until importmap is removed.
ERB lint remains because mailers and third-party/Rails-owned templates continue
to exist after the business migration.

### Build assets without a production Node runtime

Development runs Rails, Vite, and Tailwind through the Vite process under the
existing process manager/container workflow. Production installs npm
dependencies and builds fingerprinted Vite assets in a Docker build stage, then
copies only compiled output into the final Rails runtime image. The final web
container does not run Node because SSR is out of scope.

CI performs `npm ci` before frontend checks and builds assets before Rails
request/system tests that render Vite tags. The production image build must
also be exercised before the foundation is accepted.

### Preserve Rails security boundaries

Inertia requests use existing Rails session cookies and CSRF protection.
Frontend forms use the Inertia/Rails integration rather than bypassing
authenticity checks. Vite development hosts and websocket connections receive
environment-scoped CSP allowances only; production keeps application scripts
and styles same-origin. Error payloads and logs must not expose credentials,
reset tokens, signed blob tokens, or raw session material.

There are no new persistence, authorization, privacy, retry/idempotency,
PostGIS, or map-query semantics in this change. Existing policies, interactors,
and GeoJSON behavior remain unchanged.

## Risks / Trade-offs

- [Legacy CSS changes during compiler migration] -> Compare representative
  legacy pages before and after, keep the same token vocabulary, and retain an
  easy revert to the old CSS tag until parity is verified.
- [Turbo and Inertia lifecycle conflict] -> Use separate layouts and forbid
  mixed runtime ownership within a route.
- [Missing or stale Vite manifest] -> Make asset build an explicit local, test,
  CI, and Docker gate with a smoke request that resolves production-style tags.
- [CSP blocks Vite development or production chunks] -> Add only
  environment-scoped development origins and verify production same-origin
  delivery.
- [Inertia props leak sensitive data] -> Keep props page-specific, review
  serialized keys in request specs, and preserve existing filtered logging.
- [Tooling makes local verification slow] -> Provide narrow frontend scripts
  and compose the full set only in `make verify`/CI.
- [npm audit produces unactionable transitive findings] -> Fail on the
  repository-approved severity level, document any temporary exception
  precisely, and never use blanket audit disablement.
- [Coverage percentage encourages weak tests] -> Report coverage first and
  defer a blocking threshold until representative pages exist.
- [A future UI kit conflicts with current components] -> Keep component APIs
  local and accessible, and make the UI-kit choice before substantial admin UI
  development.
- [CSR affects no-JavaScript access and SEO] -> Make JavaScript-required
  behavior explicit per migrated page; defer SSR as a separately approved
  architecture change.

## Migration Plan

1. Pin compatible Ruby and npm dependencies and add Vite/Inertia configuration.
2. Add frontend entrypoints, strict TypeScript, formatting/linting, tests, and
   accessibility setup.
3. Move Tailwind source CSS and tokens into Vite while keeping legacy pages
   visually unchanged.
4. Add isolated legacy and Inertia layouts plus the development/test-only smoke
   route.
5. Integrate Rails/Vite development processes and container volumes.
6. Integrate deterministic frontend checks and asset builds into Make,
   `bin/ci`, GitHub Actions, and test setup.
7. Add the production Docker asset build and prove the final image serves the
   smoke bundle in an appropriate test environment.
8. Run focused smoke/request/component checks, legacy system specs,
   `make verify`, and a production image build.

Rollback removes the smoke route and Inertia layout, restores the legacy
stylesheet compiler/tag, and removes the new build steps and dependencies.
Because no business route migrates in this change, rollback does not require
data migration or user-facing route changes.

Later changes migrate one complete route at a time. The planned order starts
with waterfall detail, leaves Explore/MapLibre until last among current pages,
and ends with a dedicated cleanup change that removes old frontend
dependencies only after repository search and verification prove no remaining
business consumers.

## Open Questions

- Which exact compatible patch versions and maintained axe adapter pass the
  implementation spike on the repository's pinned Node and Ruby versions?
- What measured frontend coverage baseline after the first two or three
  business pages is useful enough to enforce?
- Does the MapLibre migration justify replacing Selenium with Playwright, or
  using Playwright only for a small browser-specific subset?

These questions may refine tools within the approved boundaries. A change to
the selected architecture, SSR timing, route ownership, package manager, or
Rails/React responsibility split requires artifact review before
implementation continues.
