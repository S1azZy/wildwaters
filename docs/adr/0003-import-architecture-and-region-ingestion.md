# ADR 0003: Import Architecture and Region Ingestion

- Status: Accepted
- Decided: 2026-03-28
- Normalized to implementation: 2026-06-13

## Context

Wild Waters imports external region data and must preserve provenance,
licensing, repeatability, and links between upstream identities and local
domain records. A single external reference on `regions` cannot represent this
relationship or support repeatable imports safely.

The import mechanism belongs inside the Rails monolith and must preserve the
project's thin-model, interactor-oriented application structure.

## Decision

Create a dedicated `Imports` subsystem with generic provenance records and
domain-specific links.

### Technology and ownership boundary

- The subsystem remains inside the Rails monolith.
- PostgreSQL JSONB stores source payloads and execution metadata.
- PostGIS stores product-facing region centers.
- `pg_trgm` indexes searchable region names.
- `yabi` interactors own acquisition, normalization, matching, apply, and
  domain synchronization use cases.
- Active Record models own associations, persistence, enums, and local
  invariants; they do not become an ETL orchestration layer.

### Import persistence

The generic persistence model is:

- `import_sources` stores source identity, role, fetch mode, licensing,
  attribution, display policy, and stable configuration;
- `import_runs` stores one execution, its mode, status, effective parameters,
  aggregate statistics, and errors;
- `import_source_records` stores stable upstream identities, raw and normalized
  payloads, checksums, lifecycle status, and last-seen run;
- `import_record_snapshots` stores payload history when a source record changes;
- domain-specific link tables connect source records to local domain records.

An upstream object is identified by source, record kind, and external UID.
`raw_payload` preserves the received record for audit and diagnostics.
`normalized_payload` is the stable internal contract between source-specific
normalization and source-independent matching/apply logic. A checksum covers
both representations, and a snapshot is added only when that content changes.

Region provenance uses `import_region_source_links`, not a polymorphic generic
link. This preserves database foreign keys and supports one primary identity per
region. Links record match strategy, confidence, and match time. A link may be
primary only when its source has the `canonical_identity` role.

### Region domain

The local region model remains product-oriented:

- `regions` stores the hierarchy parent, product region kind, country code, and
  PostGIS center point;
- `region_closures` materializes ancestors and descendants;
- `region_names` stores multilingual names and aliases with normalized,
  searchable values and optional source provenance.

The core region model uses product-oriented kinds instead of copying every
upstream administrative level. Source-specific details remain import data.
Reparenting imported regions goes through a domain interactor that rebuilds the
affected closure rows transactionally.

Imported domain writes go through `yabi` interactors. The region import path
upserts source records, snapshots changed payloads, resolves parents, reuses an
existing source link or a structural local match, creates or synchronizes the
region, refreshes provenance, and synchronizes names.

GeoNames is the only implemented region dataset. It is configured as the
canonical identity and hierarchy source and supplies initial centers and names.
Other source roles exist in the persistence model, but no additional region
enrichment pipeline is implied by this ADR.

The implemented apply path enforces canonical-source ownership of a primary
identity link. It does not separately prohibit a non-canonical source from
creating a region because no enrichment source apply path currently exists.
Introducing one requires an explicit matching and creation policy before it can
write domain records.

## Alternatives Considered

### Store one external reference on `regions`

Rejected because a region may have several upstream identities and each source
needs independent provenance and licensing metadata.

### Use a polymorphic import link

Rejected because it weakens foreign-key integrity and hides domain-specific
matching rules.

### Build a separate ETL service

Rejected because the current scale does not justify another deployment or a
second domain-write path.

### Store multilingual names in JSON metadata

Rejected because names need identity constraints, provenance, normalization,
and database indexes.

## Consequences

- Import state and provenance are queryable independently from domain records.
- Re-imports can update stable source records and retain changed snapshots.
- Domain writes remain governed by the same interactors as other application
  use cases.
- JSONB preserves source fidelity without leaking source-specific schema into
  the product-facing region table.
- Closure tables and trigram-indexed names support hierarchy traversal and
  multilingual lookup without introducing a separate search or GIS service.
- Matching behavior is explicit application logic and must be covered by RSpec.
- Supporting another imported domain requires a domain-specific link and apply
  path instead of extending a polymorphic catch-all.
- Requirements for sources or matching strategies that are not implemented
  belong in OpenSpec changes or `docs/TODO.md`, not in this ADR.
