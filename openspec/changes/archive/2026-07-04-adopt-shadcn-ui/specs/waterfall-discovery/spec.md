## ADDED Requirements

### Requirement: Kit-backed map-first explore chrome
The system SHALL refresh the Explore page chrome with shadcn-backed controls
while preserving the public map-first discovery contract.

#### Scenario: Explore map remains primary surface
- **GIVEN** a visitor opens the Explore homepage
- **WHEN** the Inertia page renders
- **THEN** the MapLibre map remains the primary visual surface
- **AND** filters, results, and map controls are layered around the map rather
  than replacing it with a non-map-first layout

#### Scenario: Explore controls use kit-backed compositions
- **GIVEN** the Explore page renders search, filters, result cards, result
  panels, map-style controls, zoom controls, and empty/loading states
- **WHEN** frontend source is inspected
- **THEN** those visible controls use shadcn primitives or Wild Waters wrappers
  where suitable
- **AND** MapLibre lifecycle code remains feature-owned outside the UI kit

#### Scenario: Explore data behavior unchanged
- **GIVEN** published and draft waterfalls exist with map filters
- **WHEN** the refreshed Explore UI requests or renders waterfall data
- **THEN** the same publication boundary, filter behavior, GeoJSON payload
  shape, and Rails-generated detail URLs remain enforced

#### Scenario: Responsive map-list interaction
- **WHEN** the refreshed Explore UI renders on a narrow viewport
- **THEN** map and result-list interactions remain reachable without hiding the
  map behind unrelated application chrome
- **AND** map controls remain accessible by keyboard or equivalent browser
  interaction
