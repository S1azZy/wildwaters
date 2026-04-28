# ADR 0003: Import Architecture and Region Ingestion

- Status: Accepted
- Date: 2026-03-28

## Context

Wild Waters depends on external data to achieve useful catalog coverage.
This is especially true for:

- regions and region hierarchy
- waterfall discovery data
- future enrichment datasets

The project needs a repeatable import mechanism that can:

- ingest from multiple heterogeneous sources
- re-run imports from the same source without creating duplicates
- track provenance and licensing
- match external records to local domain records
- support asynchronous execution through `Solid Queue`
- minimize manual review because the product is operated by one person

For `regions`, the project also needs:

- multilingual names from the start
- future-ready search by region name at multiple hierarchy levels
- enough spatial metadata to center the map later
- a balanced approach that avoids turning region ingestion into its own product

Additional constraints:

- Rails monolith
- thin models
- canonical business orchestration through `yabi` interactors
- PostgreSQL 18 with PostGIS
- `structure.sql`
- future region, spot, and other source types
- review imports will exist later, but they are explicitly out of scope for direct display and matching in this ADR

The current `regions.external_ref` column is too limited for the real requirement because one local region may be linked to several external sources.

## Decision

Adopt a dedicated `Imports` subsystem inside the monolith with:

1. generic import provenance tables
2. domain-specific link tables
3. source-level licensing and display policy metadata
4. idempotent async runs through `Solid Queue`
5. one canonical region import path for MVP:
   - `GeoNames` as canonical identity and hierarchy source
   - `geoBoundaries gbOpen` as boundary and centroid enrichment source
   - `Wikidata` as multilingual naming enrichment source
   - `Who's On First` deferred as a later concordance and sanity-check layer
   - `OSM` excluded from the MVP region pipeline

For regions:

- only the canonical identity source may create new `Region` rows automatically
- enrichment sources may update or attach to existing regions, but must not create new regions by default
- multilingual names live in a dedicated region-name table, not in `regions.metadata`
- region search readiness is established now through indexed multilingual names and canonical region centroids
- full polygon promotion into the core domain is deferred; polygons remain enrichment data until there is a concrete product need

## Goals

- Safe repeated imports
- Clear source provenance
- Deterministic re-import behavior
- Automatic matching wherever confidence is high
- Minimal operator workload
- Future support for multiple source types and future spot imports
- Licensing metadata captured close to the source definition
- Region names searchable across languages

## Non-goals

- Building a generic ETL platform
- Building a full GIS data warehouse
- Full review import design
- Cross-source review deduplication
- Perfect global administrative normalization
- Full polygon-first region product features in MVP

## Import Architecture

### Namespace and ownership

Use a dedicated `Imports` namespace:

- `app/models/imports/`
- `app/interactors/imports/`
- `app/jobs/imports/`
- `app/lib/imports/` for connectors and parsers only

Keep the boundaries explicit:

- connectors fetch and parse upstream data
- interactors orchestrate import, matching, and apply flows
- models own storage and local invariants only
- domain writes happen through domain-specific apply interactors

### Generic tables

#### `import_sources`

One row per configured upstream source.

Recommended columns:

- `id bigint primary key`
- `key text not null unique`
- `target_kind text not null`
- `source_role text not null`
- `fetch_mode text not null`
- `enabled boolean not null default true`
- `license_key text not null`
- `license_url text`
- `attribution_text text`
- `display_policy text not null`
- `compliance_notes text`
- `config jsonb not null default '{}'::jsonb`
- `last_successful_run_at timestamptz`
- timestamps

Semantics:

- `target_kind`: `region`, later `spot`, `review_signal`, others
- `source_role`: `canonical_identity`, `name_enrichment`, `geometry_enrichment`, `analysis_only`
- `fetch_mode`: `dump`, `api`, `scrape`, `manual_file`
- `display_policy`: `public_display_allowed`, `derived_only`, `internal_only`

This table intentionally carries licensing and display metadata so future review-like imports can be marked `internal_only` without inventing a second policy layer.

#### `import_runs`

One row per execution.

Recommended columns:

- `id bigint primary key`
- `import_source_id bigint not null references import_sources(id)`
- `mode text not null`
- `status text not null`
- `started_at timestamptz`
- `finished_at timestamptz`
- `cursor_in text`
- `cursor_out text`
- `stats jsonb not null default '{}'::jsonb`
- `error_class text`
- `error_message text`
- `initiated_by text not null default 'system'`
- timestamps

Rules:

- one active run per source at a time, enforced by a partial unique index on active statuses
- retries must be safe
- `mode` supports `full`, `incremental`, `backfill`, `replay`
- `status` should be constrained to a small explicit set such as `queued`, `running`, `succeeded`, `failed`, `cancelled`

#### `import_source_records`

One persistent row per upstream object.

Recommended columns:

- `id bigint primary key`
- `import_source_id bigint not null references import_sources(id)`
- `record_kind text not null`
- `external_uid text not null`
- `external_url text`
- `status text not null`
- `checksum text not null`
- `raw_payload jsonb`
- `normalized_payload jsonb not null default '{}'::jsonb`
- `first_seen_at timestamptz not null`
- `last_seen_at timestamptz not null`
- `last_changed_at timestamptz`
- `last_import_run_id bigint references import_runs(id)`
- timestamps

Constraints:

- unique on `import_source_id, record_kind, external_uid`

`normalized_payload` is the stable internal contract used by matching logic.
For region records it should expose only the extracted fields needed for matching and apply, for example:

- canonical name
- alternative names
- source level
- normalized level
- country code
- parent source identifiers
- centroid
- bounding box metadata
- concordances
- source-specific administrative level when available

`status` should be constrained to a small explicit set such as:

- `pending`
- `matched`
- `unresolved`
- `failed`
- `missing_upstream`

#### `import_record_snapshots`

Optional but recommended.
Store only changed payloads.

Recommended columns:

- `id bigint primary key`
- `import_source_record_id bigint not null references import_source_records(id) on delete cascade`
- `import_run_id bigint not null references import_runs(id)`
- `checksum text not null`
- `payload jsonb`
- `artifact_path text`
- `captured_at timestamptz not null`
- timestamps

Use `artifact_path` for large raw artifacts if a payload should live in object storage rather than PostgreSQL.

### Domain-specific link tables

Do not use a generic polymorphic `import_links` table.
That would weaken foreign key integrity and make the database sloppier than necessary.

Use domain-specific link tables instead.

#### `region_source_links`

Recommended columns:

- `id bigint primary key`
- `region_id uuid not null references regions(id) on delete cascade`
- `import_source_record_id bigint not null references import_source_records(id) on delete cascade`
- `match_strategy text not null`
- `confidence numeric(5,4) not null`
- `locked boolean not null default false`
- `primary_identity boolean not null default false`
- `matched_at timestamptz not null`
- timestamps

Constraints:

- unique on `import_source_record_id`
- unique partial index on `region_id` where `primary_identity = true`
- only canonical identity sources may set `primary_identity = true` by application rule

This lets many source records from different sources point to the same `Region`, while keeping one canonical identity link.

## Region Domain Changes

The current region schema is not sufficient for multi-source region ingestion.

### Change `regions`

Keep:

- `public_id`
- `parent_id`
- `name`
- `slug`
- `summary`
- `description`
- `status`
- closure-table hierarchy

Change or add:

- replace the current coarse `region_type` with product-oriented `region_kind` values:
  - `country`
  - `area`
  - `locality`
  - `park`
  - `custom`
- add `country_code text`
- add `center geography(Point, 4326)`
- remove `external_ref`

Rationale:

- the product is travel-oriented and does not need legal-administrative precision in the core region model for MVP
- `area` is a better product fit than carrying separate `admin1`, `admin2`, and `admin3` values through the core domain
- exact upstream administrative levels are still useful for matching, but can stay in import normalization rather than `regions`
- `external_ref` cannot represent multiple source identities
- `center` is enough for future map centering without prematurely promoting polygons into the main table

### Add `region_names`

Create a dedicated multilingual names-and-aliases table.

Recommended columns:

- `id uuid primary key default uuidv7()`
- `region_id uuid not null references regions(id) on delete cascade`
- `import_source_record_id bigint references import_source_records(id) on delete nullify`
- `language_code text`
- `name text not null`
- `normalized_name text not null`
- `name_role text not null`
- `preferred boolean not null default false`
- `searchable boolean not null default true`
- timestamps

Recommended `name_role` values:

- `primary`
- `official`
- `preferred`
- `native`
- `alias`
- `ascii`

Recommended indexes:

- index on `region_id`
- index on `language_code`
- unique index on `region_id, language_code, normalized_name, name_role`
- trigram index on `normalized_name`
- optional trigram index on `name`

Search rule:

- user-facing search should search `region_names`, not only `regions.name`

Naming rule:

- use `region_names`, not `region_translations`, because this table stores source-provided names, aliases, and search labels rather than application-managed editorial translations

This provides multilingual search readiness now without introducing a global search platform prematurely.

## Region Source Strategy

### Canonical MVP sources

#### `GeoNames`

Role:

- canonical identity source
- canonical hierarchy source
- initial centroid source
- alternate names source

Why:

- stable global IDs
- pragmatic dumps and services
- global coverage
- reasonable hierarchy for MVP

Use:

- `geonameid` as `external_uid`
- `ADM*` and country feature codes mapped to internal `region_kind`
- exact source administrative levels retained in `normalized_payload` for matching and diagnostics
- GeoNames point as initial `regions.center`
- alternate names imported into `region_names`

#### `geoBoundaries gbOpen`

Role:

- geometry enrichment source
- better centroid and boundary sanity source

Why:

- strong administrative polygons
- appropriate for geometry enrichment

Use:

- never create a new `Region` automatically
- attach to existing canonical regions
- derive improved centroid if the match is exact and trustworthy
- keep raw polygon payload in snapshots or source-record payload, not in `regions`

#### `Wikidata`

Role:

- multilingual naming enrichment source
- concordance enrichment source

Why:

- strong labels and aliases
- very good multilingual coverage

Use:

- never create a new `Region` automatically
- attach to existing regions
- import `ru`, `en`, and other known labels into `region_names`
- treat Wikidata as enrichment, not as hierarchy authority

#### `Who's On First`

Role:

- deferred reference and concordance source

Decision:

- do not use in the first implementation slice
- keep it as a later enrichment option if GeoNames and Wikidata linking need more help

#### `OSM`

Decision:

- exclude from the MVP region ingestion path

Why:

- admin-level interpretation is uneven across countries
- ODbL introduces unnecessary legal and product complexity for this stage

## Matching and Merge Strategy for Regions

### Automatic creation policy

Only `canonical_identity` sources may create new `Region` rows automatically.

For MVP, that means:

- GeoNames may create regions
- geoBoundaries may not create regions
- Wikidata may not create regions

This is the main mechanism that prevents duplicate-region explosions.

### Matching order

Apply matching in strict tiers.
Stop at the first high-confidence success.

#### Tier 1: existing source link

Match by:

- `import_source_id + record_kind + external_uid`
- existing `region_source_links`

This is the normal re-import path.

#### Tier 2: known concordance

Match by concordance extracted into `normalized_payload`, for example:

- GeoNames ID
- Wikidata QID
- later WOF ID

This is especially important for enrichment sources.

#### Tier 3: deterministic structural match

Match by:

- normalized primary name
- normalized level
- country code
- parent region

This tier must require high structural agreement.

#### Tier 4: geometry-assisted match

Match by:

- centroid proximity
- centroid-inside-boundary checks if polygon metadata exists
- country and level agreement

Use only as a supporting signal, not as the sole authority.

#### Tier 5: unresolved

If confidence is below threshold:

- store the source record
- do not auto-create from enrichment sources
- do not auto-attach
- leave the record eligible for later re-match

This is intentionally conservative.
Solo-founder operation is better served by a few unresolved records than by silent duplicate corruption.

### Merge precedence

Use attribute-level precedence.

#### Region identity and hierarchy

Owned by:

- GeoNames

Fields:

- parent chain
- internal region kind
- country code
- canonical source identity

Reparenting rule:

- canonical imports may reparent an existing `Region`
- reparenting must run through a dedicated domain interactor rather than ad hoc model updates
- closure rows for the moved subtree must be rebuilt transactionally and idempotently

#### Canonical display name

Owned by:

- GeoNames initially

Rule:

- `regions.name` stays the app's canonical display name
- multilingual and alternate names belong in `region_names`

#### Multilingual labels and aliases

Owned by:

- GeoNames alternate names
- Wikidata labels and aliases

Rule:

- prefer explicit language-tagged names
- keep multiple names when they are valid aliases
- do not overwrite one valid name with another; append and mark preference instead

#### Centroid

Owned by:

- GeoNames initially
- geoBoundaries may replace it when the geometry match is exact

#### Polygon geometry

Rule:

- keep outside the core `regions` table in the first implementation
- preserve it as enrichment data only

## Multilingual Region Naming

Wild Waters needs multilingual region storage from day one.

Decision:

- `regions.name` is only the canonical app display name
- every additional localized or alternate name is stored in `region_names`
- search queries must hit `region_names`

Behavioral rules:

- store at least `ru` and `en` when available
- store unknown-language aliases with a null `language_code` if the source provides them without a language tag
- store multiple valid names per locale if they are genuinely distinct aliases
- prefer exact-language source values over machine-derived transliterations

Do not:

- pack multiple names into a JSON field
- model multilingual names as only two columns on `regions`
- rely on transliteration to recover missing multilingual data

This table is for names and aliases only.
If the product later needs localized editorial content such as `summary` or `description`, that should use separate per-entity translation tables such as `region_translations`.

## Search Readiness

Future product direction includes one search input that can accept:

- country
- admin region
- city or locality
- spot name

This ADR prepares for that without building the full search system now.

Decision:

- use `region_names` as the future region-side search surface
- keep `regions.center` ready for map centering
- do not create a global search index table yet

Future search path:

- region search can query `region_names`
- spot search can later query a similar spot-name projection
- both result sets can be combined in SQL or through a later materialized projection when justified

This keeps the path open without prematurely building a search platform.

## Async Execution Model

Use `Solid Queue`.

Recommended job shape:

- imports should enter through the shared queue orchestration flow
- source-specific batch processing may stay inside the coordinator flow for MVP and be split into additional jobs only when runtime or volume justifies it

Operational rules:

- one active run per source
- record upserts must be idempotent
- retries must not create duplicate source records or duplicate domain links
- partial failures should leave the run in a diagnosable state with persisted stats

## Risk Assessment and Mitigations

### Risk: duplicate regions from multiple sources

Mitigation:

- only canonical identity source can auto-create regions
- enrichment sources only attach to existing regions
- strict matching tiers

### Risk: inconsistent admin levels across countries

Mitigation:

- use application-owned `region_kind` values in the core domain
- keep exact source-specific levels in import normalization for matching only
- do not expose upstream level codes as our canonical model

### Risk: hierarchy drift after repeated canonical imports

Mitigation:

- allow canonical imports to reparent existing regions explicitly
- rebuild closure rows transactionally for moved subtrees
- log reparent operations through import runs for diagnosis

### Risk: multilingual naming conflicts

Mitigation:

- keep multiple names in `region_names`
- distinguish canonical display name from aliases
- avoid destructive overwrite behavior

### Risk: legal misuse of imported data

Mitigation:

- store license and display policy on `import_sources`
- keep attribution metadata explicit
- classify future restricted sources as `derived_only` or `internal_only`

### Risk: region complexity derails the waterfall product

Mitigation:

- keep polygons out of the core domain initially
- do not build a generic ETL framework
- postpone WOF and OSM
- focus MVP automation on GeoNames first and add enrichment sources only when they clearly improve product outcomes

### Risk: manual review workload becomes too high

Mitigation:

- prefer conservative unresolved records over bad auto-merges
- re-run matching automatically after canonical imports
- minimize sources allowed to create new records

### Risk: upstream records disappear or are retired

Mitigation:

- if a source record disappears, do not auto-delete the linked `Region`
- mark the source record as `missing_upstream`
- keep domain rows intact until a later explicit review or cleanup policy applies

## Consequences

Benefits:

- stable re-import and update path
- proper multi-source provenance
- multilingual region support from the start
- future-ready path to spot imports
- clean legal-policy slot for future restricted imports such as review analysis sources

Trade-offs:

- more tables than a naive importer
- some unresolved enrichment records will remain unmatched automatically
- canonical region creation is intentionally biased toward one source for safety

## Alternatives Considered

### Write directly into `regions`

Rejected because:

- it cannot safely support multi-source provenance
- it does not handle repeated imports well
- `external_ref` is structurally insufficient

### One generic polymorphic link table

Rejected because:

- it weakens foreign key integrity
- domain-specific links are clearer and safer

### Store multilingual names in JSON on `regions`

Rejected because:

- it weakens queryability
- it complicates search
- it makes provenance and indexing worse

### Import full polygons into `regions` immediately

Rejected because:

- region polygons are not core product behavior today
- it increases operational and migration cost too early

## Implementation Notes

Implementation should proceed in this order:

1. add generic import tables
2. add `region_source_links`
3. evolve `regions` and remove `external_ref`
4. add `region_names` with trigram-based search indexes
5. implement GeoNames canonical import end-to-end
6. add basic admin visibility for sources, runs, and unresolved region records
7. implement targeted Wikidata naming enrichment where canonical imports do not provide sufficient language coverage
8. introduce geoBoundaries enrichment only if centroid quality or later product needs justify the extra geometry complexity

This ADR intentionally establishes the pattern for future spot imports, but does not design spot ingestion in detail.
