# Admin Regions Directory Specification

## Purpose

Define the implemented application-owned admin regions directory for read-only
inspection of the region hierarchy.

## Requirements

### Requirement: Protected admin regions directory
The system SHALL provide a read-only regions directory inside the admin
namespace protected by Wild Waters admin authorization.

#### Scenario: Guest access
- **GIVEN** a visitor has no active application session
- **WHEN** the visitor requests `/admin/regions`
- **THEN** the system redirects to application sign-in with an authentication-required message

#### Scenario: Member access
- **GIVEN** an authenticated user whose role is `member`
- **WHEN** the user requests `/admin/regions`
- **THEN** the system redirects to the explore homepage with an admin-required message

#### Scenario: Admin access
- **GIVEN** an authenticated user whose role is `admin`
- **WHEN** the user requests `/admin/regions`
- **THEN** the system renders the regions directory as an Inertia response inside the admin shell
- **AND** the response exposes no raw model object, policy internals, import source records, geometry payload, or closure row records

### Requirement: Regions hierarchy table
The system SHALL render a paginated flat admin table of regions that preserves
hierarchy context for each row.

#### Scenario: Paginated hierarchy list
- **GIVEN** more regions exist than the admin regions page size
- **WHEN** an admin requests `/admin/regions`
- **THEN** the response contains only one page of regions
- **AND** the response contains pagination metadata and links for moving between pages

#### Scenario: Region row fields
- **GIVEN** an admin opens the regions directory
- **WHEN** the regions table renders
- **THEN** each row shows name, slug, kind, status, country code, parent path, hierarchy level, children count, and created date
- **AND** the region name is visually offset according to its hierarchy level

#### Scenario: Search regions
- **GIVEN** regions exist with different names, slugs, and country codes
- **WHEN** an admin searches the regions directory by region text
- **THEN** the response contains only matching regions
- **AND** the current search term remains visible in the search field

#### Scenario: Empty search result
- **GIVEN** no regions match the current search term
- **WHEN** an admin opens the filtered regions directory
- **THEN** the page renders an empty state instead of an empty broken table

### Requirement: Admin regions navigation
The system SHALL expose the regions directory from the admin Models navigation.

#### Scenario: Regions navigation item
- **GIVEN** an admin opens an application-owned admin page
- **WHEN** the admin shell renders
- **THEN** Regions appears in the Models navigation section with its own icon
- **AND** Regions is marked as the current page when the admin opens `/admin/regions`
