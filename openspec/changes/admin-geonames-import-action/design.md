## Context

Wild Waters already has a queued GeoNames import architecture: environment
defaults are normalized by `ApplicationConfig`, enqueue creates one
`Imports::Run` plus country `Imports::RunItem` rows, and jobs receive only item
ids. The current operator surface still exposes shell/rake launch adapters and
the admin service-actions page is only a placeholder.

The desired product boundary is now stricter: an operator starts region import
only from the admin service-actions UI, while configuration still comes from
ENV-backed application settings and is persisted into import run/item
snapshots.

## Goals / Non-Goals

**Goals:**

- Make `/admin/service-actions` the only supported operator launch surface for
  GeoNames region imports.
- Keep launch behind the existing `Admin::BaseController` authorization
  boundary.
- Keep the controller thin: call the existing enqueue interactor, set flash,
  redirect back. The enqueue interactor resolves ENV-backed settings.
- Show the latest run for the configured GeoNames source with useful status,
  timing, parameter, item, result, and failure data.
- Remove direct rake/Make/README launch paths for enqueue and retry.
- Preserve queued import semantics and job payloads.
- Decompose `Imports::Regions::ApplySourceRecord` into focused private
  collaborators without changing its public call contract.

**Non-Goals:**

- Retry UI, recurring/scheduled imports, import cancellation, or a general
  import operations dashboard.
- New persistence tables, schema changes, gems, packages, or external services.
- Changing GeoNames download/build/apply/reconcile/finalize contracts.
- Exposing raw ENV secrets, user objects, roles, policy internals, or credential
  material to React.

## Decisions

### Use a POST action under service actions

Add a POST route below the existing admin namespace, for example
`/admin/service-actions/geonames-region-import`. The action lives under
`Admin::ServiceActionsController` or a small nested admin controller, but it
must inherit the same admin boundary and redirect back to the service-actions
page.

Alternative considered: keep the rake task and have the UI shell out. That
would duplicate operational behavior, weaken auditability, and keep two launch
paths alive.

### Snapshot ENV-derived settings through existing import settings

The admin POST action should call:

1. `Imports::GeoNames::EnqueueRegionImport.call`

`EnqueueRegionImport` resolves effective settings through
`Imports::GeoNames::Settings` using `yield`, so the settings path follows the
same interactor result flow as source lookup, run persistence, and job enqueue.
`Settings` reads the already-normalized `ApplicationConfig` GeoNames values and
applies its default admin service-actions initiator. This preserves ADR 0004:
environment values are boot/default input, while the run and item rows store the
durable effective snapshot.

Alternative considered: pass form fields from React. The request asks for ENV
configuration only, and client-supplied values would widen the authorization
and validation surface.

### Render a latest-run read model from Rails props

The service-actions GET should prepare display-ready, least-data props for the
latest run belonging to the configured source. Include only operational import
data: run id, status, mode, initiator, started/finished timestamps, duration
when available, run params, aggregate stats, item status counts, and sanitized
failure summary. React should not infer authorization from raw roles or receive
model objects.

Alternative considered: have React fetch import status separately. The current
admin pages are Inertia pages with server-owned props; a separate API would add
unneeded surface for this one panel.

### Remove unsupported operator adapters

Delete the rake task file and Make targets that enqueue or retry GeoNames
imports. Update README and command documentation to say import launch happens
from the admin service-actions UI. The underlying interactors remain callable
from application code and tests, because jobs and specs still need the domain
use cases.

Alternative considered: leave the CLI path as a fallback. That contradicts the
target behavior and creates two sources of operational truth.

### Refactor apply pipeline with private collaborators

Keep `Imports::Regions::ApplySourceRecord.call(input:)` unchanged and move its
internal responsibilities into small classes under `Imports::Regions`, such as:

- source record persistence and snapshot capture;
- parent region lookup from source links;
- linked/existing/new region synchronization;
- provenance link refresh;
- region name synchronization.

The collaborators should use simple `ApplicationInteractor`-style result
contracts or focused plain objects only where no business result boundary is
needed. They are private implementation collaborators, not new operator
entrypoints.

Alternative considered: split the public apply pipeline into several externally
called interactors. That would increase contract surface during a refactor whose
goal is clarity without behavioral change.

## Risks / Trade-offs

- [Admin bypass] -> Keep routes under `Admin::BaseController` and cover guest,
  member, and admin POST/GET requests.
- [Duplicate active run] -> Preserve `run_already_active` failure handling and
  render a clear admin flash without enqueueing duplicate jobs.
- [Leaky props] -> Use request specs to reject raw role, session, user, policy,
  credential, and token keys.
- [Stale direct launch path] -> Search for import task names and remove/update
  Make, rake, README, and development-command references.
- [Apply refactor regression] -> Add/expand interactor specs for create,
  reapply, changed snapshot, structural match, parent missing, and name sync
  before refactoring.
- [Queue semantics drift] -> Keep job payloads as run item ids and verify
  enqueue specs still pass.

## Migration Plan

1. Add OpenSpec deltas for admin service-actions and GeoNames import launch.
2. Add failing request/component specs for the admin panel and POST action.
3. Add focused apply-pipeline specs that prove current behavior before
   refactor.
4. Implement the admin route/controller props/action and React panel.
5. Remove rake/Make/README direct launch paths.
6. Refactor `ApplySourceRecord` into private collaborators while keeping specs
   green.
7. Update `CHANGES.md`.
8. Run strict OpenSpec validation, focused specs, frontend checks, and the
   applicable project gate.

Rollback strategy: restore the removed operator adapters and revert the admin
POST/panel. Existing import run, item, and job models require no data rollback
because this change adds no schema.

## Open Questions

None. Retry and scheduling remain separate future changes.
