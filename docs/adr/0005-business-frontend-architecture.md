# ADR 0005: Business Frontend Architecture

- Status: Accepted
- Decided: 2026-06-14
- Implementation: `openspec/changes/archive/2026-06-14-frontend-foundation`
  and subsequent route migration changes
- Partially superseded: ADR 0006 resolves the deferred UI-kit decision for
  application-owned business and admin React interfaces.

## Context

Wild Waters is a Rails monolith whose application-owned business frontend has
migrated from ERB, Hotwire, Stimulus, ViewComponent, importmap, and Tailwind to
Vite, Inertia Rails, React, TypeScript, and Tailwind. The application is
expected to grow beyond the initial public waterfall pages into richer
interactive product flows and an application-owned admin interface.

The project needs stronger client-side composition and typing without splitting
the monolith into a separate SPA/API system or moving routing, authentication,
authorization, localization, and business rules out of Rails. The migration
must remain incremental because existing product behavior is already covered by
request and system tests.

Mailer templates and Rails engine interfaces that the application does not
render, including Mission Control Jobs, are not part of the business frontend
architecture.

## Decision

Adopt Vite, Inertia Rails, React, and TypeScript as the business frontend
architecture for Wild Waters.

### Application boundary

- Rails remains the single application server and owns routes, controllers,
  sessions, CSRF protection, authorization, I18n, business use cases, and data
  selection.
- Inertia is the page-delivery protocol between Rails controllers and React
  pages.
- React owns rendering and local interaction state for migrated business
  routes.
- Page-specific URLs and translated copy are supplied by Rails through typed
  Inertia props.
- Dedicated JSON endpoints remain appropriate for bounded dynamic data such as
  visible-map GeoJSON; they do not imply a separate general-purpose API.
- The frontend does not maintain a second route catalog, translation catalog,
  global state architecture, or general client-query layer without a concrete
  future need.

### Technology boundary

- Vite is the JavaScript, TypeScript, React, and business CSS build tool.
- TypeScript uses strict checking.
- React components use Tailwind and the existing Digital Naturalist design
  tokens defined by ADR 0002.
- npm and the repository lockfile own JavaScript dependency resolution.
- The production build compiles browser assets ahead of time. The application
  does not require a production Node process while SSR is absent.
- Propshaft may continue to serve Rails-owned static assets during migration;
  it is not a second business JavaScript build.

The researched implementation baseline on 2026-06-14 is `vite_rails` 3.11.0,
Vite 8.0.16, `inertia_rails` 3.21.2, Inertia React 3.4.0, React 19.2.7,
TypeScript 6.0.3, Tailwind CSS 4.3.1, and Vitest 4.1.8. Compatibility is
rechecked and the resolved dependency graph is locked when the foundation
change is implemented.

### Rendering and migration boundary

Migration was route-based rather than component-island-based:

- an application route was entirely legacy Rails UI or entirely an Inertia
  React page during migration;
- legacy and Inertia routes used separate layouts so Turbo/Stimulus and Inertia
  did not compete for browser lifecycle ownership;
- existing business routes migrated through separate, reviewable OpenSpec
  changes;
- current application-owned business routes now render through Inertia React;
- new application-owned admin UI uses the new frontend architecture;
- the final cleanup change removes the old application-owned frontend stack
  after no business route consumes it.

The migration preserves current visual design. It is not a redesign program.

### Client rendering and SSR

Business pages migrate as client-rendered Inertia pages. JavaScript is required
for migrated routes, and the root document provides a localized `noscript`
message.

SSR is deliberately deferred until after the initial release. Source structure
should avoid needless barriers to future SSR, but SSR compatibility is not a
current delivery gate and there is no production SSR service.

### Quality boundary

Frontend changes are covered by complementary layers:

- RSpec request specs prove Rails/Inertia page, props, redirect, flash,
  authentication, and authorization contracts;
- Vitest and React Testing Library prove user-visible component behavior;
- static and component-level accessibility checks cover shared controls and
  critical forms;
- Capybara/Selenium remains the initial end-to-end browser layer;
- format, lint, strict typecheck, unit tests with coverage reporting,
  production build, and npm dependency audit are required frontend checks.

Frontend coverage is measured before a blocking threshold is selected. The
threshold is chosen after representative business pages exist. Playwright is
reconsidered when the map or admin interface provides evidence that it improves
the browser test layer.

### Component-system boundary

The migration initially ported stable UI primitives into application-owned,
typed React components and did not adopt a visual UI kit during foundation
work.

ADR 0006 later selected shadcn/ui as the preferred component foundation for
application-owned business and admin React interfaces. This ADR continues to
own the Inertia React architecture, while ADR 0006 owns the UI-kit and
component-layer decision.

## Alternatives Considered

### Keep ERB, Hotwire, Stimulus, and ViewComponent

This remains a capable Rails-native stack, but it does not meet the selected
direction for richer typed client composition and the future admin UI.

### Add React islands inside ERB

Islands would reduce initial setup but preserve two rendering models inside the
same page, complicate lifecycle and ownership, and make removal of the old stack
less predictable.

### Build a separate React SPA and JSON API

A separate application would create duplicate route, authentication,
authorization, localization, error, and deployment contracts without a current
product boundary that justifies them.

### Adopt SSR immediately

Immediate SSR would improve no-JavaScript and initial-render characteristics,
but it would introduce a production Node service, hydration failure modes, and
additional operational work before release. The project will reassess it with
measured post-release needs.

### Adopt a UI kit during migration

Combining framework migration with a component-system replacement would make
visual and behavioral regressions harder to isolate. The existing design is
preserved first, while the admin milestone provides a concrete point for a
later toolkit decision.

## Consequences

- Frontend application code, dependencies, tests, and builds become
  first-class parts of repository verification and production image assembly.
- Rails continues to enforce security and business boundaries; Inertia props
  become an explicit exposure surface requiring review and tests.
- The project no longer maintains a legacy application-owned business frontend
  stack after the cleanup change.
- Tailwind compilation moves to Vite while the Digital Naturalist visual
  vocabulary remains stable.
- Migrated pages no longer promise useful operation without JavaScript unless a
  later OpenSpec change and SSR decision restore that capability.
- Mailer ERB, Rails-owned infrastructure templates, and external engine UI do
  not block retirement of the old business frontend stack.
- ADR 0001 continues to own MapLibre/PostGIS and map data delivery, while this
  ADR supersedes its ERB/Stimulus/browser-build boundary for migrated routes.
- ADR 0002 continues to own Digital Naturalist and its token vocabulary, while
  this ADR supersedes its ViewComponent/ERB implementation boundary for
  migrated routes.
