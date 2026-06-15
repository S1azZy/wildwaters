## MODIFIED Requirements

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
