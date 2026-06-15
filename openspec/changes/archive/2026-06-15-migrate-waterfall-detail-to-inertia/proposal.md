## Why

The frontend foundation is proven, but no production business route uses it
yet. Migrating the small, read-only waterfall detail page first validates the
route-by-route strategy with limited product risk before authentication forms
or the MapLibre explore lifecycle move to React.

This is a Level 2 specified feature: it changes user-visible page delivery,
typed response contracts, navigation behavior, and test ownership, but it does
not introduce a new durable architecture decision beyond ADR 0005.

## What Changes

- Render the existing published waterfall detail route as an Inertia React page
  while preserving its URL, visual design, content, and public-id lookup
  behavior.
- Add a minimal application-owned React shell that preserves the current site
  header, guest/authenticated action state, page title, content frame, and
  accessible flash presentation for migrated routes.
- Supply page-specific waterfall data, translated labels, navigation URLs, and
  the minimal shared shell state from Rails through explicit typed props.
- Keep the Explore route on the legacy ERB/Turbo/Stimulus runtime; links that
  cross between Explore and waterfall detail perform full document visits.
- Preserve published-only access and not-found behavior for draft or missing
  waterfalls without exposing unnecessary model, session, or policy data.
- Remove the development/test smoke route, controller, page, translations, and
  tests after the production waterfall detail route proves the same runtime
  chain.
- Add request, React component, accessibility, and browser coverage for the
  migrated detail route and shared React shell.

Non-goals:

- redesigning the waterfall detail page or changing its product content;
- migrating Explore, MapLibre, authentication, dashboard, mailers, or Mission
  Control Jobs;
- adding SSR, a UI kit, a client router, route generator, global state store, or
  general client-fetching layer;
- changing waterfall persistence, authorization, search, publication, or URL
  semantics.

Assumptions:

- the current waterfall detail content and Digital Naturalist styling are the
  parity target;
- current session state is sufficient to choose the existing header action;
- no waterfall detail interaction requires client-side state beyond Inertia
  navigation and shell rendering.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `waterfall-discovery`: The public waterfall detail route becomes a typed
  Inertia React page while retaining its lookup, publication, content, and
  not-found behavior.
- `frontend-platform`: The first production Inertia business route introduces
  the minimal shared React application shell and retires the temporary smoke
  surface.

## Impact

- Affected Rails code: `WaterfallsController#show`, application-level Inertia
  shared props, locales, and the development/test smoke route and controller.
- Affected frontend code: shared prop types, a React application shell and
  header/flash primitives, the waterfall detail page, and component tests.
- Affected legacy code: `app/views/waterfalls/show.html.erb` is retired; the
  Explore page and its links remain legacy and cross the runtime boundary with
  full document visits.
- Affected verification: waterfall request/system specs, React Testing Library
  coverage, accessibility assertions, frontend build/type checks, and the full
  project gate.
- Dependencies and deployment remain unchanged.

Primary risks requiring verification are accidental Inertia prop exposure,
loss of guest/authenticated header parity, incorrect mixed-runtime navigation,
visual regression, missing translated copy, and regressions in draft/missing
waterfall handling.
