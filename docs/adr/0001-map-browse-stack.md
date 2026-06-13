# ADR 0001: Map Browse Stack

- Status: Accepted
- Decided: 2026-03-19
- Normalized to implementation: 2026-06-13

## Context

Waterfall discovery is map-first. The application is a Rails monolith with
Hotwire, Stimulus, PostgreSQL, and PostGIS, and it needs an interactive map
without making a proprietary map SDK part of the application architecture.

The browse surface must support a server-rendered initial state and progressively
enhance it with map movement, filtering, marker selection, and result-list
synchronization.

## Decision

Use MapLibre GL JS as the browser map renderer and keep browse data delivery in
the Rails application.

The implemented architecture is:

- Rails renders the initial waterfall list and map shell;
- a Stimulus controller owns MapLibre lifecycle and interaction;
- waterfall points use MapLibre style layers and built-in clustering rather
  than one DOM marker per waterfall;
- `waterfalls#map_data` returns a compact GeoJSON feature collection;
- map requests require visible bounds and use a PostGIS envelope query;
- list and map delivery share the same application query path;
- map styles are selected from an application-owned catalog, while the selected
  style preference is stored in the browser.

MapLibre is application infrastructure. External style and tile providers are
runtime content dependencies and may be replaced without changing this
decision.

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
- Larger data-delivery mechanisms are not part of this decision; adopting one
  would require a new confirmed architecture decision.
