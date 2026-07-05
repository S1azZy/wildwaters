## Why

Admins need a read-only region reference inside the application-owned admin
workspace so they can inspect the imported/manual region hierarchy without
using consoles or import internals. This is a Level 2 specified feature because
it introduces a protected user-facing admin screen with durable acceptance
criteria.

## What Changes

- Add an application-owned `/admin/regions` Inertia page protected by the
  existing admin boundary.
- Render a paginated, searchable regions directory using a flat table that
  makes hierarchy visible through depth, parent path, and children count.
- Add Regions to the admin Models navigation.
- Keep the first slice read-only: no create, edit, delete, reparent, import
  provenance editing, or closure-table mutation.
- Add localized `en` and `ru` admin copy.

## Capabilities

### New Capabilities
- `admin-regions-directory`: Protected admin reference table for inspecting the
  region hierarchy.

### Modified Capabilities
- `admin-users-directory`: Admin shell model navigation gains Regions without
  changing users behavior.

## Impact

- Affected code: admin routes/controllers, admin navigation props, localized
  admin copy, React admin pages/components, request specs, and component tests.
- No database schema changes, new dependencies, external services, background
  jobs, or ADR are required.
- Verification must include protected admin request coverage, component
  accessibility coverage, OpenSpec validation, and the React/Inertia verification
  gate from `docs/DEVELOPMENT.md`.
