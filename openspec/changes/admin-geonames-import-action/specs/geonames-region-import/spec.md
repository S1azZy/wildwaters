## ADDED Requirements

### Requirement: Operator launch boundary
The system SHALL make the admin service-actions launch action the only
supported operator entrypoint for starting GeoNames region imports.

#### Scenario: Admin launch uses queued orchestration
- **GIVEN** an admin launches GeoNames import from service actions
- **WHEN** the launch action runs
- **THEN** it uses the existing queued GeoNames enqueue interactor
- **AND** import jobs receive only run item ids

#### Scenario: Shell launch path removed
- **WHEN** repository operator documentation and command targets are inspected
- **THEN** they do not advertise a rake task, Make target, or CLI command for starting or retrying GeoNames region imports
- **AND** they direct operators to the admin service-actions page for import launch

### Requirement: Admin launch settings snapshot
The system SHALL derive GeoNames admin-launch configuration from environment
backed application settings and persist the effective values with the run.

#### Scenario: Environment-backed admin launch
- **GIVEN** configured source key, country codes, languages, feature codes, alternate-name flag, mode, and download directory
- **WHEN** an admin launches GeoNames import from service actions
- **THEN** country and feature codes are normalized uppercase, language codes are normalized lowercase, booleans are typed, and the initiator is included
- **AND** the parent run and each country item persist those effective settings before jobs execute

### Requirement: Region apply refactor preserves behavior
The system SHALL keep provenance-aware region apply behavior unchanged while
the apply implementation is decomposed.

#### Scenario: Apply contract remains stable
- **GIVEN** a caller invokes `Imports::Regions::ApplySourceRecord` with the existing source, run, and normalized record input
- **WHEN** the source record is applied
- **THEN** the result contract and persisted source record, snapshot, region, link, and region-name effects match the existing GeoNames region import behavior
