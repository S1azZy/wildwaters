## Why

The public explore homepage is the last high-value business frontend surface
still owned by ERB, Stimulus, and importmap. Moving it to Inertia now closes the
main public-page gap in the migration, proves the map-heavy React path, and
keeps the visible waterfall-first design intact while the backend remains the
source of truth for filtering, map data, localized copy, and route generation.

## What Changes

- Render the public explore homepage and waterfall index as a typed Inertia
  React page through the isolated frontend runtime.
- Preserve the current map-first design, filter band, basemap menu, zoom
  controls, collapsed results rail, localized copy, map-data endpoint, and
  published-only result behavior.
- Load the vendored MapLibre JS and CSS from same-origin Rails assets from the
  Inertia page without loading Turbo, Stimulus, or the importmap entrypoint.
- Retire the superseded explore ERB template, card partial, and Stimulus map
  controller after request, component, and browser coverage proves parity.
- Replace the old no-JavaScript server-rendered catalog promise with the
  frontend-platform JavaScript-required Inertia fallback for migrated pages.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `waterfall-discovery`: Specify that the explore page is delivered as a typed
  Inertia map-first page while the existing JSON map-data endpoint remains
  Rails-owned.
- `frontend-platform`: Extend route migration proof to include a map-heavy
  public Inertia page using locally vendored third-party browser assets.

## Impact

- Expected outcome: visitors see the same explore UI and filtered public
  waterfall content, but the page is served by React/Inertia instead of ERB and
  Stimulus.
- Task level: Level 2 specified behavior change. No ADR is required because the
  work applies the accepted frontend architecture.
- Scope: waterfall index render path, Inertia props, React explore page,
  MapLibre asset loading, request/frontend/system/tooling tests, baseline
  OpenSpec sync, legacy explore template/controller retirement, and `CHANGES.md`.
- Non-goals: map-data backend semantics, PostGIS query changes, waterfall
  detail pages, auth screens, Dashboard, mailers, Mission Control, SSR, a UI
  kit, route changes, or new dependencies.
- Dependencies and schema: no new package, gem, service, migration, API, or
  persisted data.
- Special verification risks: prop payloads must stay public-only, the route
  must not load importmap/Turbo/Stimulus, and the map asset policy must remain
  same-origin for application code while allowing only configured tile sources.
