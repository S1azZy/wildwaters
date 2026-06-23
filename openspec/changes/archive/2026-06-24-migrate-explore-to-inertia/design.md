## Context

The application-owned frontend stack already serves waterfall detail,
Dashboard, and authentication screens through Vite, Inertia, React,
TypeScript, and Tailwind. The public explore homepage remains a Rails ERB page
enhanced by a Stimulus `explore-map` controller and importmap-pinned MapLibre
asset.

Explore is the most complex remaining public page because it combines a
full-bleed map, a filter form, a dynamically refreshed results rail, local
basemap preference, and a Rails JSON `map_data` endpoint. Rails should continue
to own query semantics, translations, formatted display labels, generated URLs,
and the MapLibre style catalog.

## Goals / Non-Goals

**Goals:**

- Move the public explore homepage and waterfall index to a typed Inertia React
  page in one PR.
- Preserve the current visual design and waterfall-first interaction model.
- Keep the existing `map_data` endpoint and `Waterfalls::ExploreQuery` backend
  behavior unchanged.
- Load locally vendored MapLibre JS/CSS from same-origin assets without the
  legacy importmap runtime.
- Remove the superseded ERB explore template, waterfall card partial, and
  Stimulus map controller after parity tests pass.

**Non-Goals:**

- Introducing SSR, a UI kit, generated TypeScript route helpers, new npm
  dependencies, new map providers, or a map UX redesign.
- Changing PostGIS filtering, result ordering, publication rules, route names,
  CSP tile-host policy, or waterfall detail behavior.
- Migrating mailers or engine-owned Mission Control pages.

## Decisions

### Render explore as a full Inertia page

`WaterfallsController#index` will render `Waterfalls/Index` through the
isolated `inertia` layout. The response will include display-ready copy, current
filter values, map configuration, supported basemap styles, region options,
Rails-generated URLs, same-origin MapLibre asset URLs, and an initial
FeatureCollection for the first results rail render.

Partial React islands were rejected because the page would still have two
browser runtimes owning map lifecycle, filters, and rail rendering.

### Keep Rails as the explore data and formatting boundary

React receives only public display data and URLs. Rails remains responsible for
localized labels, height formatting, plunge-pool labels, region option ordering,
map-style URLs, and query filtering. The existing `map_data` endpoint remains
the client refresh contract for bounds-aware map updates.

### Load vendored MapLibre assets from the Inertia page

MapLibre remains a locally vendored browser asset instead of becoming a new npm
dependency in this slice. The Inertia page receives Rails-resolved asset URLs,
adds the CSS through the Inertia head, and lazy-loads the JS only when the map
component mounts. This keeps application runtime ownership in Vite/Inertia
while avoiding importmap, Turbo, and Stimulus on the page.

### Treat migrated explore as JavaScript-required

The old ERB page could expose server-rendered results when JavaScript was
disabled. A migrated Inertia page follows the frontend-platform contract:
without JavaScript, the root document displays the localized JavaScript-required
message. The React page may still include the old explore-specific `<noscript>`
copy for rendered-DOM continuity, but the durable guarantee is the Inertia
fallback.

## Risks / Trade-offs

- [Map parity drift] -> Preserve existing DOM hooks/classes, add component and
  browser coverage around filters, style controls, zoom controls, and the rail.
- [Runtime mixing] -> Assert that explore responses do not include importmap,
  Turbo, or Stimulus controller ownership.
- [Public prop leakage] -> Assert exact Inertia prop shape and exclude draft
  state, internal timestamps, credentials, raw session data, and policy data.
- [Vendored asset loading] -> Keep MapLibre JS/CSS same-origin and retain CSP
  coverage for OpenFreeMap, Stadia, font, image, and blob-worker sources.
- [Larger page PR] -> Keep backend query semantics and design unchanged; this
  slice only changes rendering ownership.

## Migration Plan

1. Add failing OpenSpec, request, frontend component, browser, and tooling specs
   for the migrated explore contract.
2. Add typed Rails props for `Waterfalls/Index` and render the index route
   through the Inertia layout.
3. Implement the React explore page, local MapLibre loader, filter/map refresh
   logic, style preference, zoom controls, and results rail using existing
   visual classes.
4. Retire the old explore ERB template, card partial, and Stimulus controller.
5. Sync baseline OpenSpec specs, archive the completed change, update
   `CHANGES.md`, and run the required Rails, frontend, security, and full
   verification gates.

Rollback restores the ERB render path and templates. There is no schema,
dependency, route, or persisted-data migration.

## Open Questions

None. Future SSR and a future UI-kit/design-system choice remain TODO-level
work outside this slice.
