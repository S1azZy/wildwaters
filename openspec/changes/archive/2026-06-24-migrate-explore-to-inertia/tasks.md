## 1. Failing Migration Contract

- [x] 1.1 Add request specs requiring the explore route to render
  `Waterfalls/Index` as an Inertia response with exact localized public props,
  runtime isolation, same-origin MapLibre asset URLs, and sensitive-key
  exclusions.
- [x] 1.2 Add request specs requiring existing explore filters and publication
  rules to shape the initial Inertia FeatureCollection.
- [x] 1.3 Add React component/accessibility tests for the map-first explore
  page, including filter controls, basemap menu, zoom controls, collapsed rail,
  cards, empty state, and local asset head tags.
- [x] 1.4 Update browser coverage to prove the migrated Inertia runtime,
  preserved DOM/classes, local MapLibre assets, and absence of importmap/
  Stimulus ownership.
- [x] 1.5 Run the focused request/frontend/system specs and confirm they fail
  for the expected missing explore Inertia implementation.

## 2. Typed Explore Page

- [x] 2.1 Add typed `Waterfalls/Index` page props for copy, filters, map
  configuration, map styles, region options, URLs, assets, and initial features.
- [x] 2.2 Implement React rendering for the preserved explore layout, filter
  band, map toolbar, style menu, collapsed results rail, cards, empty state, and
  no-JavaScript copy.
- [x] 2.3 Implement same-origin MapLibre JS lazy loading, CSS head injection,
  style preference, zoom controls, bounds refresh, client search, and card
  focus behavior without importing the legacy Stimulus controller.
- [x] 2.4 Run focused frontend tests, typecheck, lint, and format until green.

## 3. Rails Inertia Integration

- [x] 3.1 Change `WaterfallsController#index` to render the isolated Inertia
  layout with display-ready props.
- [x] 3.2 Preserve `map_data`, `Waterfalls::ExploreQuery`, result limits,
  publication filtering, map-style catalog defaults, and CSP behavior.
- [x] 3.3 Remove the superseded explore ERB template, waterfall card partial,
  and Stimulus map controller after migrated parity coverage passes.
- [x] 3.4 Run focused waterfall request and browser specs until green.

## 4. Legacy Retirement And Verification

- [x] 4.1 Sync the implemented behavior into baseline OpenSpec specs and archive
  this completed change in the same PR.
- [x] 4.2 Add a dated `CHANGES.md` entry describing the explore migration and
  preserved map/query behavior.
- [x] 4.3 Run `bin/openspec validate --all --strict`, focused request/frontend/
  system specs, `make frontend-verify`, `make security`, `make verify-fast`,
  and pre-PR `make verify`, recording any unrelated blocker exactly.
