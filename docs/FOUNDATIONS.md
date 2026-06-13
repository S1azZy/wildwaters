# Foundations

This document owns stable product, architecture, domain, data, and database
boundaries. It is not a roadmap, status report, command list, or implementation
scratchpad.

Use it when a task needs to answer:

- what Wild Waters is and is not;
- which domain concepts are canonical;
- where business logic, data access, and UI orchestration belong;
- which database and geospatial rules must stay consistent.

Workflow, commands, permissions, and verification live in
`docs/DEVELOPMENT.md`. Security and testing policy lives in
`docs/QUALITY_SECURITY.md`.

## Product Boundary

Wild Waters is a production-minded, mobile-first Rails monolith for discovering
natural water places, starting with waterfalls.

Decision order:

1. Product value.
2. Maintainability and consistency.
3. Delivery speed.
4. Future extensibility without MVP bloat.

Current product stance:

- Waterfalls are the only active public spot type.
- Region hierarchy, map browsing, and waterfall details are the active
  discovery surfaces.
- Confirmed future work is ordered in `docs/TODO.md` and becomes behavior only
  through an OpenSpec change.
- Web and API entrypoints must share the same domain/use-case layer when both
  exist.
- Russian and English are first-class UI locales.

Do not turn the MVP into:

- a generic outdoor platform;
- a native mobile app;
- an offline-first system;
- an AI product;
- a real-time product without a concrete need;
- a moderation, recommendation, or routing platform before the waterfall social
  loop is complete.

## Architecture Boundary

Wild Waters is one Rails monolith serving web UI, JSON responses, admin tools,
imports, and background jobs.

Stable architecture rules:

- Prefer current Rails conventions and existing project patterns.
- Controllers orchestrate HTTP only.
- Models own persistence, associations, scopes, normalization, and local
  invariants.
- Business use cases live in `app/interactors` and use the canonical `yabi`
  style.
- Queries that are not business use cases may live in `app/queries`.
- Authorization stays explicit through policies for domain resources or a
  dedicated guard for a bounded admin engine.
- Server-rendered web UI uses ERB, Hotwire, Tailwind, and the existing UI
  component layer where it already exists.
- Background work uses the Rails/Solid Queue stack unless a concrete need
  justifies otherwise.
- Do not introduce parallel service/interactor/API response styles.

Concrete cross-cutting decisions live in ADRs:

- Map browsing: `docs/adr/0001-map-browse-stack.md`
- Design system: `docs/adr/0002-design-system-foundation.md`
- Import architecture: `docs/adr/0003-import-architecture-and-region-ingestion.md`
- GeoNames queued import orchestration:
  `docs/adr/0004-geonames-queued-import-orchestration.md`

## Domain Boundary

Canonical domain areas:

- Identity and authentication.
- Regions and multilingual region names.
- Imports and source provenance.
- Spots and waterfalls.
- Waterfall browse/search queries.
- Admin and operational tooling.

Unimplemented domain layers are tracked in `docs/TODO.md`, not here.

Canonical place model:

- `Spot` is the root place entity.
- `waterfall` is the only active `spot_type` for MVP behavior.
- Waterfall-specific fields belong in `waterfalls`.
- Shared searchable/filterable fields belong on first-class tables, not inside
  generic metadata.
- Future spot types require an explicit product decision before user-facing
  behavior, routes, filters, or abstractions are added.

Region model:

- `Region` owns product-facing hierarchy and browse context.
- `RegionClosure` supports subtree traversal.
- `RegionName` owns canonical and alternate multilingual names.
- Import provenance stays in the `Imports` namespace and attaches to domain
  records through explicit link tables.

Import model:

- Imports are not a generic ETL product.
- Import flows must be idempotent, provenance-aware, and safe to retry.
- Source-specific orchestration belongs under `app/interactors/imports`.
- Domain writes from imports should pass through explicit domain/apply
  interactors.

## Data and Geospatial Boundary

- PostgreSQL 18 and PostGIS are first-class dependencies.
- Canonical spot coordinates live in a geospatial column suitable for nearby and
  bounds queries.
- Location and nearby search belong in database-backed queries/services, not in
  controllers.
- Nearby and map queries must be index-backed.
- Keep map payloads lean and product-shaped.
- Use `jsonb` only for genuinely source-specific, import-oriented, or
  subtype-specific data that is not a core searchable field.
- Do not move stable public filters, identifiers, names, coordinates, or status
  fields into generic metadata.

## Database Boundary

- Use `structure.sql` as the canonical schema dump.
- Never edit `db/structure.sql` by hand.
- Prefer SQL-forward migrations inside Rails migration wrappers.
- Use explicit `up` and `down`.
- Prefer PostgreSQL `uuidv7()` primary keys for main domain tables.
- `bigint` is acceptable for internal operational tables when it is the simpler
  fit.
- Foreign key types must match referenced primary keys.
- Default to explicit primary keys, foreign keys, `NOT NULL`, and justified
  indexes.
- Add geospatial indexes for location-backed lookups.
- Use `CHECK` only for true storage-level invariants.
- Keep business validation in the application layer.
- Keep naming consistent and within PostgreSQL identifier limits.

## Extension Rule

Extend from the current product and codebase, not from speculative future
platform ideas. Add abstractions only when an implemented use case needs them or
an ADR records the decision.
