# Spot and Waterfall Domain Specification

## Purpose

Define the implemented transactional domain behavior for creating a waterfall
as a waterfall-specific record attached to the shared geospatial Spot root.

## Requirements

### Requirement: Transactional waterfall creation
The system SHALL create the Spot and Waterfall records atomically for a valid existing region.

#### Scenario: Valid waterfall
- **GIVEN** an existing region and valid waterfall attributes
- **WHEN** the waterfall creation use case runs
- **THEN** the system creates one waterfall-type Spot and one associated Waterfall
- **AND** it returns both records

#### Scenario: Missing region
- **GIVEN** the submitted region id does not exist
- **WHEN** waterfall creation is attempted
- **THEN** the system returns a region-not-found failure
- **AND** it creates neither record

#### Scenario: Invalid waterfall subtype
- **GIVEN** Spot attributes are valid but waterfall-specific attributes are invalid
- **WHEN** waterfall creation is attempted
- **THEN** the system returns a validation failure
- **AND** it rolls back the Spot

### Requirement: Spot public identity
The system SHALL generate a public id and normalized region-scoped slug for every Spot.

#### Scenario: Generated waterfall URL identity
- **GIVEN** a waterfall is created from a name
- **WHEN** its public parameter is generated
- **THEN** the Spot has a normalized slug and a parameter in `public_id--slug` form

#### Scenario: Region-scoped slug
- **GIVEN** two different regions
- **WHEN** each contains a Spot with the same normalized slug
- **THEN** both Spots are valid

#### Scenario: Duplicate slug in one region
- **GIVEN** a region already contains a Spot with a normalized slug
- **WHEN** another Spot in that region uses the same slug
- **THEN** the system rejects the duplicate

### Requirement: Canonical spot location
The system SHALL persist waterfall coordinates on the Spot as a PostGIS geography Point.

#### Scenario: Persist coordinates
- **GIVEN** valid latitude and longitude values
- **WHEN** a waterfall is created
- **THEN** the Spot location stores longitude as X and latitude as Y with SRID 4326

### Requirement: Waterfall subtype invariants
The system SHALL allow at most one Waterfall per Spot and reject negative waterfall height.

#### Scenario: Non-negative height
- **GIVEN** a waterfall height is zero, positive, or absent
- **WHEN** the Waterfall is validated
- **THEN** the height is accepted

#### Scenario: Negative height
- **GIVEN** a negative waterfall height
- **WHEN** the Waterfall is validated
- **THEN** the system rejects it

#### Scenario: Duplicate subtype row
- **GIVEN** a Spot already has a Waterfall
- **WHEN** another Waterfall is assigned to the same Spot
- **THEN** the system rejects the duplicate subtype row
