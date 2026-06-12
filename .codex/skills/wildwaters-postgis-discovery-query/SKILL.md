---
name: wildwaters-postgis-discovery-query
description: Use this skill when changing Wild Waters geospatial data, PostGIS-backed nearby or bounds queries, map payloads, waterfall discovery queries, geospatial migrations, or index-backed catalog performance.
---

# Wild Waters PostGIS Discovery Query

## When to use

Use for nearby search, bounds search, map data endpoints, waterfall catalog filters, coordinate storage, geospatial indexes, PostGIS migrations, and payload/performance changes in discovery surfaces.

If the task requires detailed spatial SQL, geometry operations, or migration implementation, also use the global `postgis` skill.

## Read

- `docs/DEVELOPMENT.md` migration/schema/PostGIS and controller/request verification rules.
- `docs/CONTEXT_MAP.md` rows for waterfall catalog/browse, explore map UI, migrations/schema, queries/presenters, or models/domain persistence.
- `docs/FOUNDATIONS.md` data, geospatial, and database boundaries.
- The target query/presenter/controller/model/spec, then one neighboring query or request/system spec.
- `docs/adr/0001-map-browse-stack.md` only when changing MapLibre or map-first browse behavior.
- Recent migrations only when schema or indexes change.

## Do not read by default

- Imports ADRs.
- Auth/security docs unless protected/private/user data enters the payload.
- All migrations or full `db/structure.sql`.
- Frontend files unless the map UI contract changes.

## Procedure

1. Identify whether the change is read-query, payload shape, UI behavior, migration/index, or model persistence.
2. Confirm the public waterfall MVP boundary: waterfall is the only active public spot type unless the user explicitly approved broader spot behavior.
3. Keep nearby and bounds logic database-backed and index-aware; do not move spatial filtering into controllers.
4. Keep map payloads lean and product-shaped: identifiers, names, coordinates, status/visibility, and only fields needed by the UI.
5. For schema changes, inspect recent migrations, write explicit `up`/`down`, and never edit `db/structure.sql` by hand.
6. For behavior changes, write the narrow request/interactor/query/system spec first.
7. Verify with the narrow spec and the matrix-required gate, normally `make verify-fast` for query/controller/schema behavior.

## Outputs

```text
Loaded:
Skipped:
Change kind:
Query/index boundary:
Payload shape:
Red test:
Verification:
Performance risk:
Open question:
```

## Token economy

- Start from the context-map row and open only one vertical slice: caller, query/presenter, model, matching spec.
- Use `rg "bounds|nearby|location|ST_|spatial|map_data|MapLibre"` before opening files.
- Read `db/structure.sql` only for generated-output inspection after Rails tasks.
- Prefer short query/payload summaries over pasting full JSON examples.
