# ADR 0004: GeoNames Queued Import Orchestration

- Status: Accepted
- Date: 2026-04-24

## Context

ADR 0003 introduced the generic import subsystem and the first GeoNames region import path.
The current implementation can load GeoNames region dumps, preserve source provenance, and apply records into the region hierarchy.

The previous operator flow was shaped like a synchronous batch command:

- a rake task receives environment variables
- network mode downloads all requested country dumps in one process
- the task updates `import_sources.config`
- a Rails job runs the import synchronously
- one import run processes the whole dataset in sequence

This is acceptable for the first slice, but it does not match the desired operating model for larger or production-like imports.
GeoNames imports should be observable, resumable, and able to process country shards independently through `Solid Queue`.

Future entrypoints also matter.
The project will likely add an admin UI where an operator can click a button to start a GeoNames import.
That controller must not shell out to `make` or rake.
The same application use case should be callable from:

- `make` / local operator commands
- a Rails admin controller
- future scheduled jobs
- Rails console or one-off maintenance scripts

The project also prefers environment-driven operational defaults.
This fits local Docker, future production deployment, and scheduled operations.
At the same time, each concrete import run must snapshot the effective parameters in the database for auditability and deterministic retries.

## Decision

Move GeoNames region imports to a master/item queue orchestration model.

Use `import_runs` as the master import execution record.
Add `import_run_items` as per-country execution units under an import run.

The target flow is:

1. An entrypoint builds effective GeoNames import settings from environment-backed defaults and optional explicit input.
2. The entrypoint calls one shared interactor, for example `Imports::GeoNames::EnqueueRegionImport`.
3. The interactor creates one `import_run` for the whole requested import.
4. The interactor snapshots effective run parameters into the database.
5. The interactor creates one `import_run_item` per country code.
6. The interactor enqueues one `Solid Queue` job per item with `perform_later`.
7. Each slave job receives only `import_run_item_id`.
8. Each slave job downloads, normalizes, and imports only its country shard.
9. Each slave job marks its item as succeeded or failed and invokes a finalizer.
10. The finalizer closes the parent `import_run` once all items have reached terminal states.

Do not use `perform_async`.
The project uses Rails `Active Job` with `Solid Queue`, so queued work should use `perform_later`.

## Entry Points

`make` remains a local/operator convenience layer only.
It must not own import business logic.

Recommended shape:

```text
make import_geonames
  -> bin/rails imports:geonames:enqueue
  -> Imports::GeoNames::Settings.from_env
  -> Imports::GeoNames::EnqueueRegionImport.call(input:)
```

Future admin UI shape:

```text
Admin::Imports::GeoNamesController#create
  -> Imports::GeoNames::Settings.from_env with optional form overrides
  -> Imports::GeoNames::EnqueueRegionImport.call(input:)
```

Future scheduler shape:

```text
Recurring job
  -> Imports::GeoNames::Settings.from_env
  -> Imports::GeoNames::EnqueueRegionImport.call(input:)
```

All entrypoints must converge on the same interactor.
No controller, rake task, or make target should duplicate import orchestration logic.

## Configuration

Use environment-backed defaults for operator-facing configuration.
The exact implementation may use a small settings object first and may adopt `dry-configurable` if the configuration surface grows enough to justify the dependency.

Expected defaults include:

- `GEONAMES_COUNTRY_CODES`
- `GEONAMES_LANGUAGES`
- `GEONAMES_FEATURE_CODES`
- `GEONAMES_DOWNLOAD_ALTERNATE_NAMES`
- `GEONAMES_DEFAULT_MODE`

Environment values are defaults and operator inputs, not mutable execution state for slave jobs.

Once a run is enqueued, the effective parameters must be persisted with the run and/or items.
Slave jobs must read their work definition from the database, not from current environment values.

This distinction is required because queued jobs may run after deploys, restarts, or configuration changes.
The run must remain understandable later even if current environment defaults have changed.

## Data Model

Keep `import_sources` as stable source metadata:

- key
- target kind
- source role
- fetch mode
- licensing
- display policy
- stable defaults if needed

Do not mutate `import_sources.config` per run as the primary way to pass import parameters.
Run-specific country lists, languages, feature codes, artifact paths, and options belong to the run snapshot and item rows.

Add `import_run_items` for generic shard-scoped work under an import run.

Recommended columns:

- `id bigint primary key`
- `import_run_id bigint not null references import_runs(id)`
- `item_kind text not null`
- `item_key text not null`
- `status text not null`
- `params jsonb not null default '{}'::jsonb`
- `artifact_paths jsonb not null default '{}'::jsonb`
- `stats jsonb not null default '{}'::jsonb`
- `attempts_count integer not null default 0`
- `started_at timestamptz`
- `finished_at timestamptz`
- `error_class text`
- `error_message text`
- timestamps

For GeoNames country imports:

- `item_kind = "country"`
- `item_key = country code`
- `params["country_code"] = country code`

Enforce uniqueness for one work item per kind/key within a run:

```text
unique(import_run_id, item_kind, item_key)
```

Initial item statuses:

- `queued`
- `running`
- `succeeded`
- `failed`
- `cancelled`

The parent `import_runs` status set should be extended with a partial terminal state, for example `partially_failed`, so a run with 95 succeeded items and 1 failed item is not represented as a total failure.

## Job Boundaries

Use a dedicated slave job, for example:

```ruby
Imports::GeoNames::ImportRunItemJob.perform_later(import_run_item_id)
```

The job should:

1. lock or safely claim the item
2. skip already succeeded items unless explicitly retrying
3. mark the item `running`
4. download GeoNames files for the item's country code
5. build normalized records for that country
6. apply records through shared region import logic
7. reconcile missing upstream records only within that country scope
8. write item stats and artifact paths
9. mark the item `succeeded` or `failed`
10. call the run finalizer

The slave job must not receive the full country list.
It should receive only an item id so retries and auditing stay tied to database state.

## Finalization

Each slave job should invoke a small finalizer after it reaches a terminal item state.

The finalizer should lock the parent `import_run`, inspect all sibling items, and only close the run when no item remains `queued` or `running`.

Recommended logic:

```text
if any item is queued/running
  keep import_run running
else if any item failed
  mark import_run partially_failed
else
  mark import_run succeeded
```

Finalization must update aggregate stats on `import_runs`, such as:

- total item count
- succeeded item count
- failed item count
- processed record count
- created region count
- missing upstream count

## Retry Model

Support partial retry for failed country items.

Recommended operator flow:

```text
make import_geonames_retry_failed RUN_ID=123
```

or an equivalent admin action later:

```text
Retry failed items for run #123
```

The retry action should:

- select failed `import_run_items`
- increment attempt counters or record retry metadata
- clear item error fields
- set items back to `queued`
- enqueue one job per failed item
- move the parent run back to `running` if needed

The first implementation may keep retry attempts on `import_run_items`.
If audit requirements grow, add `import_run_item_attempts` later.

## GeoNames Scope and Reconciliation

GeoNames country imports are shardable by country code, but reconciliation must become country-scoped.

The current full/replay reconciliation marks source records as `missing_upstream` when they are absent from the current dataset.
That is unsafe for per-country jobs because a job importing `AD` must not mark `FR` records as missing.

The new reconciliation rule:

```text
For a country item, only records belonging to that country are eligible for missing_upstream reconciliation.
```

Batch-level reconciliation may be added later, but it must use the run's snapshotted country list rather than current environment defaults.

## Artifacts

Country slave jobs should write local artifacts under a run/item-specific path, for example:

```text
tmp/imports/geonames/<import_run_id>/<country_code>/
```

Expected artifacts:

- base GeoNames country dump
- optional alternate names dump
- optional normalized dataset/debug output if useful

Artifact paths used by an item should be persisted on `import_run_items.artifact_paths`.

## Alternatives Considered

### Keep the current synchronous task

Rejected.
It is simple, but it does not provide country-level progress, partial retry, or queue-controlled concurrency.
It also keeps the future admin UI dependent on command-shaped behavior.

### Create one `import_source` per country

Rejected.
GeoNames is one upstream source.
Countries are execution shards, not separate sources.
Per-country source rows would pollute source metadata and make provenance harder to reason about.

### Add a separate `import_batches` table

Rejected for now.
`import_runs` already represents a concrete execution.
Adding `import_batches` would create overlapping concepts.
The clearer model is one run with many run items.

### Let slave jobs read country lists and settings from ENV

Rejected.
ENV is appropriate for defaults, but queued jobs must execute against a persisted run snapshot.
Otherwise retries and delayed jobs can silently change behavior after environment changes.

## Consequences

Benefits:

- one shared use case for make, admin UI, scheduler, and console
- real async execution through `Solid Queue`
- clear per-country progress
- partial failure is visible instead of collapsing the whole import into failure
- failed countries can be retried without rerunning successful countries
- source metadata remains stable
- run parameters are auditable after environment changes

Trade-offs:

- requires a new `import_run_items` table
- requires country-scoped reconciliation
- requires parent run finalization logic
- requires careful idempotency around item retries
- introduces more operational states than the current synchronous task

## Implementation Notes

Implement this as a staged migration from the current flow:

1. Add `import_run_items` and parent run partial status support.
2. Add GeoNames settings parsing from environment defaults.
3. Add `Imports::GeoNames::EnqueueRegionImport`.
4. Add `Imports::GeoNames::ImportRunItemJob`.
5. Refactor GeoNames download/build/apply logic to accept a single country item.
6. Make missing-upstream reconciliation country-scoped.
7. Add retry-failed entrypoint.
8. Update `make import_geonames` to call the shared interactor through Rails.
9. Remove old synchronous rake tasks once the queued path is verified.

All behavior-changing implementation work must follow the project red-green test rule.
