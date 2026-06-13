# Region Management Specification

## Purpose

Define the implemented region hierarchy, multilingual name, center-point, and
closure-table behavior used by discovery and imports.

## Requirements

### Requirement: Region creation
The system SHALL create a region, searchable primary name, and closure rows in one transaction.

#### Scenario: Root region
- **GIVEN** valid region attributes without a parent
- **WHEN** a region is created
- **THEN** the system generates its public id and normalized slug
- **AND** it creates a searchable primary name and a depth-zero self closure

#### Scenario: Child region
- **GIVEN** a parent region with an existing ancestor chain
- **WHEN** a child region is created beneath it
- **THEN** the child references the parent
- **AND** it receives closure rows for itself and every parent ancestor with incremented depth

#### Scenario: Invalid region
- **GIVEN** invalid region attributes
- **WHEN** region creation is attempted
- **THEN** the system returns a validation failure
- **AND** it persists neither the region nor partial closure records

### Requirement: Region identity and sibling slugs
The system SHALL give every region a unique public id and a slug unique within its parent.

#### Scenario: Same slug under different parents
- **GIVEN** two different parent regions
- **WHEN** each parent has a child with the same normalized slug
- **THEN** both child regions are valid

#### Scenario: Same slug under one parent
- **GIVEN** a parent already has a child with a normalized slug
- **WHEN** another child under that parent uses the same slug
- **THEN** the system rejects the duplicate

### Requirement: Region center
The system SHALL store provided region coordinates as a PostGIS geography Point in longitude-latitude order.

#### Scenario: Region with coordinates
- **GIVEN** valid latitude and longitude values
- **WHEN** a region is created or synchronized
- **THEN** its center stores longitude as X and latitude as Y with SRID 4326

### Requirement: Multilingual region names
The system SHALL normalize region names and keep name identity unique per region, locale, normalized value, and role.

#### Scenario: Normalize name
- **GIVEN** a region name with case or spacing differences
- **WHEN** it is validated
- **THEN** the system derives a Unicode-normalized lowercase searchable value

#### Scenario: Duplicate name identity
- **GIVEN** a region already has a name for a locale and role
- **WHEN** an equivalent normalized name is added for the same locale and role
- **THEN** the system rejects the duplicate

### Requirement: Imported region reparenting
The system SHALL rebuild closure paths for an imported region and its descendants when its parent changes.

#### Scenario: Reparent subtree
- **GIVEN** an imported region with descendants under an old parent
- **WHEN** synchronization assigns a new parent
- **THEN** the region and every descendant retain self closures
- **AND** their ancestor closures reference the new parent chain at correct depths
