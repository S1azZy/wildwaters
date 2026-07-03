---
name: wildwaters-imports-geonames
description: Use this skill when changing Wild Waters imports, GeoNames ingestion, import provenance, import runs or run items, retry/idempotency behavior, source records, region import application, or queued import orchestration.
---

# Wild Waters Imports GeoNames

## When to use

Use for the imports subsystem, GeoNames region ingestion, source provenance, import run/item lifecycle, download/build/apply steps, retry behavior, missing-upstream reconciliation, and import operator commands.

This skill is intentionally narrow because the import ADRs are large.

## Read

- `docs/DEVELOPMENT.md` behavior, migration, job, and verification rules.
- `docs/CONTEXT_MAP.md` row "Imports/GeoNames".
- `docs/FOUNDATIONS.md` import model and region model boundaries.
- Target `app/models/imports/**`, `app/interactors/imports/**`, `app/jobs/imports/**`, and matching specs/fixtures.
- `docs/adr/0003-import-architecture-and-region-ingestion.md` only for the relevant topic: provenance, source records, snapshots, region application, matching, reparenting, or legal/display policy.
- `docs/adr/0004-geonames-queued-import-orchestration.md` only for run items, queue orchestration, retries, finalization, parameter snapshots, or country-scoped reconciliation.

## Do not read by default

- Map/UI ADRs.
- Auth docs unless admin/operator access is part of the task.
- Entire ADR 0003 or ADR 0004 when a focused heading search is enough.
- All import fixtures; open only fixtures used by the target spec.

## Procedure

1. Identify the import layer: operator entrypoint, settings, download, dataset build, dataset apply, source record, run item job, finalizer, or retry.
2. Preserve the canonical flow: entrypoints converge on interactors; jobs receive IDs; domain writes pass through explicit import/domain apply interactors.
3. Preserve idempotency, provenance, retry safety, sanitized errors, and country-scoped missing-upstream reconciliation.
4. Do not mutate `import_sources.config` per run as the primary parameter channel; use run parameter snapshots where the ADR requires it.
5. For behavior changes, write the focused interactor/job/model spec first.
6. Use real fixture shapes when the behavior depends on upstream GeoNames format.
7. Run the narrow spec, then the verification required by `docs/DEVELOPMENT.md`.

## Outputs

```text
Loaded:
Skipped:
Import layer:
ADR topic:
Idempotency/retry proof:
Provenance boundary:
Red test:
Verification:
Open question:
```

## Token economy

- Use `rg -n "heading|term"` inside ADRs before opening sections.
- Prefer current code over historical ADR text when implementation has moved on.
- Load one interactor/job/model plus its matching spec before expanding.
- Summarize import state machines and fixture shapes instead of pasting large examples.
