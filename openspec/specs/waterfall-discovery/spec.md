# Waterfall Discovery Specification

## Purpose

Define the implemented public waterfall catalog, detail, filter, and map
discovery behavior, including publication boundaries and bounded GeoJSON
delivery.

## Requirements

### Requirement: Published waterfall catalog
The system SHALL expose only published waterfall spots in the public catalog.

#### Scenario: Published and draft waterfalls
- **GIVEN** the catalog contains published and draft waterfall spots
- **WHEN** a visitor opens the homepage or waterfall index
- **THEN** published waterfalls are rendered and draft waterfalls are omitted

#### Scenario: Catalog result bound
- **GIVEN** more than 60 published waterfalls match the current filters
- **WHEN** the catalog is rendered
- **THEN** the response contains at most 60 waterfall results

### Requirement: Explore filters
The system SHALL apply region subtree, minimum height, plunge-pool, and approach-difficulty filters to published waterfalls.

#### Scenario: Combined server-rendered filters
- **GIVEN** published waterfalls inside and outside a selected region subtree with different attributes
- **WHEN** a visitor submits several explore filters
- **THEN** the catalog renders only published waterfalls matching every active filter

#### Scenario: Empty filters
- **GIVEN** published waterfalls exist
- **WHEN** the catalog is requested without filters
- **THEN** the system returns the published catalog successfully

#### Scenario: Unknown region filter
- **GIVEN** no region has the submitted public id
- **WHEN** the catalog is filtered by that id
- **THEN** the system returns an empty result set

### Requirement: Public waterfall detail
The system SHALL resolve a published waterfall detail page by the public-id prefix of its slugged URL parameter and deliver the page through Inertia React with the existing public content.

#### Scenario: Published waterfall detail
- **GIVEN** a published waterfall with a region and populated public detail fields
- **WHEN** a visitor opens its public detail URL
- **THEN** the system returns the waterfall detail Inertia component
- **AND** the page displays its name, region, summary, description, translated detail labels and values, and a link back to Explore

#### Scenario: Optional waterfall detail fields
- **GIVEN** a published waterfall omits an optional summary, description, height, flow seasonality, or approach difficulty
- **WHEN** a visitor opens its public detail URL
- **THEN** the page renders successfully without an empty section or empty detail fact for that value

#### Scenario: Stale or incorrect slug
- **GIVEN** a published waterfall with a valid public id
- **WHEN** a visitor requests that public id followed by an incorrect slug
- **THEN** the system renders the same waterfall detail successfully

#### Scenario: Draft waterfall detail
- **GIVEN** a draft waterfall
- **WHEN** its public URL is requested
- **THEN** the system returns not found
- **AND** it does not serialize waterfall props

#### Scenario: Missing waterfall detail
- **GIVEN** no waterfall matches the public id
- **WHEN** the detail URL is requested
- **THEN** the system returns not found
- **AND** it does not render the Inertia application shell

#### Scenario: Waterfall detail prop exposure
- **GIVEN** a published waterfall detail is prepared for the browser
- **WHEN** Rails serializes the Inertia response
- **THEN** it includes only the page-specific public waterfall fields, translated display copy, and required URLs
- **AND** it excludes model internals, unpublished state, coordinates, credentials, raw session data, and policy internals

### Requirement: Bounded map data
The system SHALL require a complete valid longitude-latitude bounding box for map-data requests.

#### Scenario: Valid bounds
- **GIVEN** west and east are within -180 to 180, south and north are within -90 to 90, west is less than east, and south is less than north
- **WHEN** map data is requested
- **THEN** the system returns published waterfalls intersecting that PostGIS envelope

#### Scenario: Missing or partial bounds
- **GIVEN** one or more bounding-box values are absent
- **WHEN** map data is requested
- **THEN** the system returns an unprocessable response

#### Scenario: Malformed or invalid bounds
- **GIVEN** a bounding-box value is non-numeric, out of range, or has reversed edges
- **WHEN** map data is requested
- **THEN** the system returns an unprocessable response

### Requirement: Map feature collection
The system SHALL return map results as a GeoJSON FeatureCollection shaped for the explore interface.

#### Scenario: Published points within bounds
- **GIVEN** published and draft waterfalls inside and outside the requested bounds
- **WHEN** map data is requested with valid bounds
- **THEN** the FeatureCollection contains only published waterfalls inside the bounds

#### Scenario: Feature payload
- **GIVEN** a published waterfall in the requested bounds
- **WHEN** its map feature is serialized
- **THEN** the feature contains Point coordinates, public id, detail path, name, summary, region name, height label, plunge-pool state and label, and approach difficulty

#### Scenario: Map filters
- **GIVEN** several published waterfalls inside the requested bounds
- **WHEN** region or waterfall-attribute filters accompany the bounds
- **THEN** the FeatureCollection contains only features matching those filters

### Requirement: Map-first explore shell
The system SHALL deliver the explore shell as a typed Inertia React page that
uses the locally vendored MapLibre client while Rails remains responsible for
public waterfall data, filtering, formatting, and generated URLs.

#### Scenario: Explore page without client enhancement
- **GIVEN** a visitor opens the migrated explore page
- **WHEN** JavaScript is unavailable
- **THEN** the root document contains a localized JavaScript-required message
- **AND** the system does not promise server-rendered waterfall cards outside
  the Inertia client render

#### Scenario: Explore controls
- **GIVEN** the explore page is rendered
- **WHEN** the browser loads the Inertia page
- **THEN** it contains the map target, search and filter controls, map-style control, zoom controls, and a collapsed results rail
- **AND** the page renders initial published waterfall cards from public
  Inertia props

#### Scenario: Map style catalog
- **GIVEN** the application map-style catalog has an explicit default
- **WHEN** the explore page is rendered
- **THEN** the page uses that default independently of catalog order and exposes the supported style options through typed Inertia props

#### Scenario: Initial explore props
- **GIVEN** published and draft waterfalls match the current explore filters
- **WHEN** Rails prepares the explore Inertia response
- **THEN** the initial FeatureCollection contains only matching published
  waterfalls up to the configured explore result limit
- **AND** the props omit draft state, internal timestamps, credentials, raw
  session data, and policy internals

### Requirement: Explore content security policy
The system SHALL keep application scripts and styles same-origin while allowing only the external resources required by configured map styles and fonts.

#### Scenario: Map security policy
- **GIVEN** the migrated explore page is rendered
- **WHEN** the browser evaluates its content security policy
- **THEN** application scripts and styles are loaded from self rather than unpkg
- **AND** configured OpenFreeMap, Stadia, font, image, and blob-worker sources are allowed
- **AND** the page does not load Turbo, Stimulus, or the importmap entrypoint
