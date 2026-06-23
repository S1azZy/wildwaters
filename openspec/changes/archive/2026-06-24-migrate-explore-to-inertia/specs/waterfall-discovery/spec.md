## MODIFIED Requirements

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
- **THEN** it contains the map target, search and filter controls, map-style
  control, zoom controls, and a collapsed results rail
- **AND** the page renders initial published waterfall cards from public
  Inertia props

#### Scenario: Map style catalog
- **GIVEN** the application map-style catalog has an explicit default
- **WHEN** the explore page is rendered
- **THEN** the page uses that default independently of catalog order and exposes
  the supported style options through typed Inertia props

#### Scenario: Initial explore props
- **GIVEN** published and draft waterfalls match the current explore filters
- **WHEN** Rails prepares the explore Inertia response
- **THEN** the initial FeatureCollection contains only matching published
  waterfalls up to the configured explore result limit
- **AND** the props omit draft state, internal timestamps, credentials, raw
  session data, and policy internals

### Requirement: Explore content security policy
The system SHALL keep application scripts and styles same-origin while allowing
only the external resources required by configured map styles and fonts.

#### Scenario: Map security policy
- **GIVEN** the migrated explore page is rendered
- **WHEN** the browser evaluates its content security policy
- **THEN** application scripts and styles are loaded from self rather than
  unpkg
- **AND** configured OpenFreeMap, Stadia, font, image, and blob-worker sources
  are allowed
- **AND** the page does not load Turbo, Stimulus, or the importmap entrypoint
