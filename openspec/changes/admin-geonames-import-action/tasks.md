## 1. Failing Contracts

- [x] 1.1 Add request coverage for admin service-actions GET latest GeoNames
  import props, least-data sensitive-key exclusion, and no side effect on page
  render.
- [x] 1.2 Add request coverage for the GeoNames import POST action: guest,
  member, admin success, and active-run failure without duplicate jobs.
- [x] 1.3 Add component coverage for the service-actions GeoNames panel:
  empty latest-run state, latest-run summary, failure summary, and one POST
  launch button without client-side configuration fields.
- [x] 1.4 Expand import interactor coverage for
  `Imports::Regions::ApplySourceRecord` so create, reapply, changed snapshot,
  structural match, parent missing, link refresh, and name sync behavior are
  pinned before refactor.
- [x] 1.5 Add/update tooling coverage proving unsupported GeoNames rake/Make
  launch paths are not defined or documented.
- [x] 1.6 Run the narrow specs through the supported Make/container path and
  confirm new behavior specs fail for the expected missing implementation.

## 2. Admin Launch Surface

- [x] 2.1 Add the admin POST route under service actions without shadowing
  `/admin/jobs`.
- [x] 2.2 Build latest-run props from the configured GeoNames source with
  status, timestamps, mode, initiator, parameter snapshot, item status counts,
  stats, and sanitized failure summary.
- [x] 2.3 Implement the POST action through `EnqueueRegionImport`, with
  effective settings resolved by `Settings` inside the enqueue pipeline,
  preserving run/item snapshots and job payloads.
- [x] 2.4 Add localized `en` and `ru` copy for the panel, button, status labels,
  empty state, result labels, and success/failure flash messages.
- [x] 2.5 Implement the React panel in `Admin/ServiceActions/Index` using
  existing shadcn/Wild Waters components and Rails-generated URLs.

## 3. Import Pipeline Cleanup

- [x] 3.1 Extract source-record persistence, checksum, and snapshot capture from
  `Imports::Regions::ApplySourceRecord` into a focused private collaborator.
- [x] 3.2 Extract parent lookup and region synchronization into focused private
  collaborators while keeping the existing apply call contract.
- [x] 3.3 Extract provenance link refresh and region-name synchronization into
  focused private collaborators.
- [x] 3.4 Remove dead apply-pipeline code such as the unused `build_center`.
- [x] 3.5 Run focused import interactor specs after each refactor step and keep
  behavior green.

## 4. Remove Direct Operator Launch Paths

- [x] 4.1 Remove GeoNames import rake tasks and their rake specs or replace them
  with a negative task-surface spec.
- [x] 4.2 Remove `make import_geonames` and `make import_geonames_retry_failed`
  targets and update the Makefile phony list.
- [x] 4.3 Update README and `docs/DEVELOPMENT.md` so operators are directed to
  the admin service-actions UI instead of rake/Make/CLI launch commands.
- [x] 4.4 Search for removed task names and update any remaining references.

## 5. Verification And Completion

- [x] 5.1 Update `CHANGES.md` for the admin launch surface, removed operator
  launch paths, and import apply refactor.
- [x] 5.2 Run `bin/openspec validate admin-geonames-import-action --strict` and
  resolve artifact issues.
- [x] 5.3 Run focused request, interactor, rake/tooling, and component specs.
- [x] 5.4 Run frontend verification needed for the touched React page.
- [x] 5.5 Run the applicable project gate from `docs/DEVELOPMENT.md`
  (`make verify-fast`, or `make verify` before publishing).
