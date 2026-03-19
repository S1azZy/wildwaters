# ADR 0001: Map Browse Stack

- Status: Accepted
- Date: 2026-03-19

## Context

Wild Waters needs a map-first browse experience for waterfall discovery.
The target interaction is:

- large, fast map as the primary surface
- secondary list panel with compact spot cards
- top-level filters for region and spot attributes
- smooth zooming and panning
- room for later reviews, check-ins, and social signals

Product direction is closest to `AllTrails` for information architecture and `Hipcamp` for visual tone.

Project constraints:

- free/open stack preferred
- no monetization-driven vendor lock-in
- Rails monolith with Hotwire, Stimulus, PostgreSQL 18, and PostGIS
- mobile-first, but strong desktop map UX is required

## Decision

Use `MapLibre GL JS` as the map renderer for the public browse experience.

Adopt this implementation shape:

- map-first desktop layout with a large map and a narrow list panel
- `MapLibre` with a lightweight vector basemap style
- spot rendering through `style layers`, not large numbers of DOM markers
- map data loaded for the current visible bounds only
- built-in clustering for broader zoom levels
- compact map payloads with only browse-critical fields

For the first implementation stage:

- use `GeoJSON by bounds` for spot data
- update data after map movement settles (`moveend`)
- sync list and map selection without full-page rerenders

For a later scale-up path:

- move high-volume browse data to `vector tiles` or `PMTiles`

## Alternatives Considered

### Mapbox GL JS

Strong product quality and performance, but rejected because it introduces paid/vendor-controlled terms that do not fit the project's free/open preference.

### Google Maps JavaScript API

Fast and familiar, but rejected as the primary direction because it is less brandable for an outdoor-first product and remains vendor-controlled.

### Leaflet

Good for simpler maps, but not the preferred foundation for an `AllTrails`-style, map-dominant interface with WebGL-style rendering and future scaling.

### OpenLayers

Very capable, but heavier and more GIS-oriented than needed for the initial product experience.

## Consequences

Benefits:

- keeps the stack open and free-friendly
- supports the required fast, smooth, map-first UX
- gives a clean path from MVP browse to larger-scale tile-based delivery
- allows a branded visual language closer to `AllTrails + Hipcamp` than a default vendor map

Trade-offs:

- performance will depend on our data delivery strategy, not on `MapLibre` alone
- we must choose or host an appropriate free basemap/style
- we must design the map payload and interaction model carefully

Non-goals for the first map slice:

- custom 3D terrain
- complex route logic
- rich social overlays on the browse map
- large HTML marker systems

## Implementation Notes

Start with:

1. map-first `waterfalls#index` layout
2. `MapLibre` integration via Stimulus
3. bounds-based spot endpoint for published waterfalls
4. layer-based markers and clustering
5. MVP filters for region and key waterfall attributes

This ADR fixes the map stack decision, not the full visual design system.
