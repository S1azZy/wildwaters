# ADR 0001: Map Browse Stack

- Status: Accepted
- Decided: 2026-03-19
- Normalized to implementation: 2026-06-13
- Partially superseded: ADR 0005 replaces the page-rendering and browser-build
  boundary for migrated routes; this ADR continues to own MapLibre, PostGIS,
  and map data delivery.

## Context

Waterfall discovery is map-first. The application is a Rails monolith with
Hotwire, Stimulus, PostgreSQL, and PostGIS, and it needs an interactive map
without making a proprietary map SDK part of the application architecture.

The browse surface must support a server-rendered initial state and progressively
enhance it with map movement, filtering, marker selection, and result-list
synchronization.

## Decision

Use an open, replaceable map stack built around MapLibre GL JS, Rails, and
PostGIS. Do not make a proprietary map SDK or a hosted vendor API the owner of
waterfall discovery.

### Technology boundary

- MapLibre GL JS is the browser renderer.
- The published MapLibre JavaScript and CSS are vendored in the application,
  pinned through importmap and Rails assets, and are not loaded from a runtime
  CDN.
- Rails, ERB, Hotwire, and Stimulus own page delivery and browser orchestration.
- PostgreSQL with PostGIS owns spatial filtering.
- Basemap style and tile services are runtime content dependencies selected
  through an application-owned catalog. Stadia Maps and OpenFreeMap are current
  providers, but provider replacement does not change this architecture.

### Browse delivery

- Rails renders the initial waterfall list and map shell;
- a Stimulus controller owns MapLibre lifecycle and interaction;
- waterfall points use MapLibre style layers and built-in clustering rather
  than one DOM marker per waterfall;
- `waterfalls#map_data` returns a compact GeoJSON feature collection;
- browser movement triggers bounded refreshes, and map requests require visible
  bounds and use a PostGIS envelope query;
- list and map delivery share the same application query path;
- map styles are selected from an application-owned catalog, while the selected
  style preference is stored in the browser.

GeoJSON over bounds-based HTTP requests is the current data-delivery contract.
Vector tiles, PMTiles, or a separate geospatial delivery service are not part of
the adopted stack. They require measured need and a new architecture decision,
not an implicit extension of this ADR.

## Alternatives Considered

### Mapbox GL JS or Google Maps

Both provide mature hosted products, but would make a vendor-controlled SDK and
commercial terms part of the core browse architecture.

### Leaflet

Leaflet is simpler, but the product uses WebGL style layers and clustering as
first-class map behavior.

### OpenLayers

OpenLayers is capable but adds a broader GIS-oriented API surface than this
product currently needs.

## Consequences

- The application owns GeoJSON payload shape, query limits, and map/list
  synchronization.
- PostGIS remains the source of truth for visible-bounds filtering.
- The initial page remains usable as server-rendered HTML, while the richer map
  experience depends on JavaScript.
- Basemap availability and attribution must be monitored independently from the
  application.
- Vendoring the renderer reduces runtime supply-chain and CDN availability
  dependencies, while dependency freshness remains an explicit project check.
- The application can replace basemap providers without replacing MapLibre or
  the Rails/PostGIS query path.
