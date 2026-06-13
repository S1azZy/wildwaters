# GeoNames Region Import Specification

## Purpose

Define the implemented GeoNames settings, queued country-shard orchestration,
region provenance, idempotent apply, reconciliation, finalization, and retry
behavior.

## Requirements

### Requirement: Effective import settings
The system SHALL build normalized GeoNames enqueue input from typed application defaults with optional explicit overrides.

#### Scenario: Environment-backed defaults
- **GIVEN** configured source key, country codes, languages, feature codes, alternate-name flag, mode, and download directory
- **WHEN** GeoNames settings are loaded
- **THEN** country and feature codes are uppercase, language codes are lowercase, booleans are typed, and the initiator is included

#### Scenario: Explicit overrides
- **GIVEN** application defaults and explicit country or mode input
- **WHEN** GeoNames settings are loaded
- **THEN** explicit input replaces the corresponding defaults

### Requirement: GeoNames dataset acquisition
The system SHALL download and normalize requested GeoNames country artifacts before applying them.

#### Scenario: Country dump with alternate names
- **GIVEN** a valid country code and alternate names enabled
- **WHEN** the country dump is downloaded and built
- **THEN** the system produces normalized hierarchy records and selected multilingual alternate names

#### Scenario: Alternate names disabled
- **GIVEN** a valid country code and alternate names disabled
- **WHEN** the country dump is downloaded
- **THEN** only country dump artifacts are required

#### Scenario: Invalid acquisition input
- **GIVEN** a missing required setting, invalid country code, unreadable artifact, or unsuccessful upstream response
- **WHEN** acquisition or dataset building runs
- **THEN** the system returns a validation, download, or dataset-build failure without applying records

### Requirement: Country-sharded enqueue
The system SHALL create one import run and one queued run item per normalized country in a single operation.

#### Scenario: Enqueue several countries
- **GIVEN** an existing configured GeoNames source and valid settings
- **WHEN** the import is enqueued
- **THEN** one running parent run stores the effective settings snapshot
- **AND** one queued country item stores its country-specific parameters and artifact directory for each country
- **AND** one imports-queue Active Job is enqueued per item with only the item id

#### Scenario: Preserve source metadata
- **GIVEN** the GeoNames source already contains licensing, attribution, and compliance metadata
- **WHEN** a run is enqueued
- **THEN** the system neither creates a duplicate source nor rewrites that metadata

#### Scenario: Missing source or invalid input
- **GIVEN** the configured source is missing or required enqueue input is absent
- **WHEN** enqueue is attempted
- **THEN** the system creates no run or items and enqueues no jobs

#### Scenario: Colliding normalized country keys
- **GIVEN** country inputs normalize to the same item key
- **WHEN** enqueue is attempted
- **THEN** the system returns an item-conflict failure without retaining a partial run or jobs

### Requirement: Country item processing
The system SHALL process each run item from persisted parameters and record its independent outcome.

#### Scenario: Successful item
- **GIVEN** a queued country item
- **WHEN** its job runs
- **THEN** the system increments attempts, downloads artifacts, builds and applies records, reconciles that country, and marks the item succeeded
- **AND** it records artifact paths and item statistics before finalizing the parent

#### Scenario: Already succeeded item
- **GIVEN** a run item is already succeeded
- **WHEN** processing is invoked again
- **THEN** the system skips all import steps without incrementing attempts

#### Scenario: Item step failure
- **GIVEN** a claimed item and a failed download, build, apply, or reconcile step
- **WHEN** processing reaches that failure
- **THEN** the item is marked failed with sanitized error data
- **AND** the parent run is finalized from terminal item states

#### Scenario: Missing item
- **GIVEN** no run item matches the submitted id
- **WHEN** processing is invoked
- **THEN** the system returns a run-item-not-found failure

### Requirement: Provenance-aware region apply
The system SHALL apply normalized region records idempotently with source records, changed-payload snapshots, domain links, hierarchy, centers, and searchable names.

#### Scenario: First canonical apply
- **GIVEN** an enabled canonical region source and parent-first normalized records
- **WHEN** the dataset is applied
- **THEN** the system creates regions, source records, primary identity links, centers, closure paths, and primary, ASCII, and alternate names

#### Scenario: Identical reapply
- **GIVEN** the same source records were already applied
- **WHEN** the dataset is applied again unchanged
- **THEN** the system creates no duplicate regions, source records, links, names, or snapshots

#### Scenario: Changed source payload
- **GIVEN** an existing source record receives changed normalized or raw payload
- **WHEN** it is reapplied
- **THEN** the system advances its changed timestamp and stores a new snapshot

#### Scenario: Structural local match
- **GIVEN** a local region tree matches the incoming parent, slug, kind, and country structure but has no source links
- **WHEN** the dataset is applied
- **THEN** the system attaches provenance links without duplicating the local regions

#### Scenario: Canonical reparenting
- **GIVEN** a linked imported region's upstream parent changes
- **WHEN** the record is reapplied
- **THEN** the region is synchronized through the region domain path and its closure subtree is rebuilt

#### Scenario: Disabled source
- **GIVEN** the run belongs to a disabled source
- **WHEN** dataset apply is attempted
- **THEN** the system rejects the apply without changing the parent run lifecycle

### Requirement: Region identity provenance
The system SHALL allow one source record link and at most one primary identity link per region.

#### Scenario: Duplicate source-record link
- **GIVEN** a source record is already linked to a region
- **WHEN** another link is created for that source record
- **THEN** the system rejects the duplicate link

#### Scenario: Non-canonical primary identity
- **GIVEN** a source whose role is not canonical identity
- **WHEN** its region link is marked as primary identity
- **THEN** the system rejects the link

### Requirement: Country-scoped missing reconciliation
The system SHALL mark omitted source records missing only for full or replay imports and only inside the processed country.

#### Scenario: Full country reconciliation
- **GIVEN** matched records in the processed country and another country
- **WHEN** a full or replay item omits one record from the processed country
- **THEN** only that omitted country record becomes missing upstream

#### Scenario: Incremental import
- **GIVEN** an incremental run omits a previously matched record
- **WHEN** reconciliation runs
- **THEN** no record is marked missing upstream

### Requirement: Parent run finalization
The system SHALL keep a parent run active until all items are terminal and then aggregate their outcome.

#### Scenario: Active sibling remains
- **GIVEN** at least one run item is queued or running
- **WHEN** finalization runs
- **THEN** the parent remains running

#### Scenario: All items succeed
- **GIVEN** every run item is terminal and succeeded
- **WHEN** finalization runs
- **THEN** the parent is marked succeeded with aggregate counts and the source records its last successful run time

#### Scenario: Partial failure
- **GIVEN** all run items are terminal and at least one failed
- **WHEN** finalization runs
- **THEN** the parent is marked partially failed with aggregate succeeded, failed, processed, created-region, and missing-upstream counts

### Requirement: Failed-item retry
The system SHALL retry only failed country items while preserving successful work.

#### Scenario: Retry partially failed run
- **GIVEN** a partially failed run with failed and succeeded items
- **WHEN** failed items are retried
- **THEN** only failed items are reset to queued with cleared errors and re-enqueued by id
- **AND** succeeded items remain unchanged and the parent returns to running

#### Scenario: Missing retry run
- **GIVEN** no run matches the submitted id
- **WHEN** retry is requested
- **THEN** the system returns a run-not-found failure and enqueues no jobs
