## Why

GeoNames region import is an operational side effect and should have one clear,
audited operator entrypoint. Moving launch into the admin service-actions page
keeps import execution behind the existing admin boundary, shows operators the
latest run state, and removes shell/rake launch paths that can drift from the
product-owned workflow.

Task level: 2. This changes admin behavior, import orchestration entrypoints,
and observable documentation. No ADR is required because the queued import
architecture already exists in ADR 0004; this change applies that architecture
through the application-owned admin UI and refactors internals without changing
the public import contracts.

## What Changes

- Add a protected admin service action for GeoNames region import launch.
- Render a service-actions panel showing the latest GeoNames import run:
  status, run timing, initiator, mode, effective parameter snapshot, item
  counts, result statistics, and failure summary when present.
- Add a button that enqueues a GeoNames import run from environment-backed
  settings through `Imports::GeoNames::Settings` and
  `Imports::GeoNames::EnqueueRegionImport`.
- Persist the effective ENV-derived configuration in the import run and item
  parameter snapshots, as the current queue architecture requires.
- Keep `Imports::GeoNames::EnqueueRegionImport` and run-item jobs as the shared
  orchestration path; the admin controller is only an operator adapter.
- **BREAKING** Remove shell/rake/Make/README operator launch paths for starting
  or retrying GeoNames region imports so the only supported operator launch is
  the admin button.
- Update project command documentation so it no longer advertises GeoNames
  import Make or rake targets as supported launch paths.
- Refactor `Imports::Regions::ApplySourceRecord` into focused private
  collaborators for source-record persistence, parent lookup, region
  synchronization, provenance link refresh, and name synchronization without
  changing `ApplySourceRecord.call(input:)`.
- Remove dead import code that is no longer used by the apply pipeline.

Non-goals:

- Do not add scheduled imports, automatic recurring imports, retry controls, or
  a general import management console.
- Do not add new gems, packages, database tables, triggers, stored procedures,
  or a new authorization framework.
- Do not change GeoNames dataset normalization, country sharding, job payloads,
  run item processing, retry interactor behavior, or finalization semantics
  except where needed to remove unsupported operator adapters.
- Do not expose secrets, raw ENV values outside the persisted import parameter
  snapshot, credentials, user objects, raw roles, or policy internals in
  Inertia props.

Assumptions:

- Existing `Admin::BaseController` authorization remains the access boundary for
  the service-actions page and POST action.
- The canonical GeoNames source key remains environment-backed and defaults to
  `geonames_regions`.
- The latest-run panel can be read-only and show the most recent run for the
  configured source, including active, succeeded, failed, or partially failed
  runs.
- Removing shell/rake/Make launch paths is acceptable even though the underlying
  interactors remain callable from application code and tests.

Unresolved questions:

- None for this slice. Retry UI and scheduled imports remain future work.

## Capabilities

### New Capabilities

- `admin-geonames-import-action`: Defines the admin-only GeoNames import launch
  action, latest-run panel, button behavior, and least-data Inertia contract.

### Modified Capabilities

- `admin-service-actions`: Service actions changes from a placeholder into a
  real admin workspace containing the GeoNames import action.
- `geonames-region-import`: GeoNames import launch becomes admin-only at the
  operator boundary while preserving queued orchestration, ENV-backed settings,
  run/item parameter snapshots, and region apply behavior.

## Impact

- Rails routes/controllers: admin service-actions GET props and a new admin
  POST action under the existing admin namespace.
- Import interactors: `Imports::GeoNames::Settings`,
  `Imports::GeoNames::EnqueueRegionImport`, and focused
  `Imports::Regions::*` apply collaborators.
- Import models/read props: latest run and item summary for the configured
  GeoNames source.
- React frontend: `Admin/ServiceActions` page, localized copy, action button,
  and latest-run rendering.
- Documentation and command surface: remove GeoNames import rake task file,
  Make targets, and README/project command references for direct launch.
- Specs: request specs for guest/member/admin access and enqueue behavior,
  component specs for panel/button states, interactor specs for preserved apply
  behavior and collaborator boundaries, and tooling/spec checks for removed
  rake tasks.
- Verification risks: admin bypass, duplicate active run handling, leaking
  sensitive state through props, stale non-admin launch docs, breaking queued
  import snapshots, and changing region apply semantics during refactor.
