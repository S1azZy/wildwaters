# ADR 0004: GeoNames Queued Import Orchestration

- Status: Accepted
- Decided: 2026-04-24
- Normalized to implementation: 2026-06-13

## Context

A GeoNames region import may cover several countries and can fail or need a
retry independently for each country. Running the complete dataset as one
synchronous command would hide progress, couple execution to a shell process,
and make partial retry difficult.

Operational defaults come from application configuration, but queued work may
execute after those defaults change. Each run therefore needs a durable snapshot
of its effective input.

## Decision

Represent a GeoNames import as one master `Imports::Run` with one
`Imports::RunItem` per country.

The implemented orchestration is:

1. `Imports::GeoNames::Settings` builds effective input from typed application
   configuration or explicit overrides.
2. `Imports::GeoNames::EnqueueRegionImport` creates the run and all country
   items transactionally.
3. The run and items persist effective parameters; each item has its own
   artifact directory.
4. One Active Job is enqueued per item with `perform_later`; the job receives
   only the run-item id.
5. `ProcessRunItem` claims the item, downloads its files, builds normalized
   records, applies them, and reconciles missing upstream records within that
   country.
6. The item records status, attempts, artifact paths, statistics, and errors.
7. `FinalizeRun` closes the parent only after all items are terminal and marks
   it `succeeded` or `partially_failed`.
8. `RetryFailedItems` requeues only failed items and reopens the parent run.

Solid Queue is the queue backend through Rails Active Job. Make and rake tasks
are operator adapters; orchestration lives in interactors and can be called by
any application entrypoint.

## Alternatives Considered

### One synchronous import task

Rejected because it has no country-level progress or partial retry boundary.

### One import source per country

Rejected because countries are execution shards of one GeoNames source, not
independent provenance sources.

### A separate import-batch model

Rejected because `import_runs` already represents one execution and owns its
items.

### Read current environment values inside jobs

Rejected because delayed or retried work must use the parameters captured when
the run was created.

## Consequences

- Country items can progress and fail independently.
- Full and replay reconciliation is country-scoped, preventing one shard from
  marking another country's records missing.
- A parent run exposes aggregate progress and partial failure.
- Retries remain tied to persisted work definitions and attempt counts.
- Artifact storage is organized by run and country and recorded on each item.
- The orchestration introduces more persistent states, so idempotency and
  finalization require focused tests.
