## Context

Wild Waters already has `Region`, `RegionClosure`, and `RegionName` as the
domain model for product-facing hierarchy and browse context. The admin area is
Rails/Inertia/React with shadcn/ui primitives, and the users directory provides
the nearest pattern for protected list pages with search, pagination, localized
copy, and least-data props.

## Goals / Non-Goals

**Goals:**
- Give admins a compact read-only region reference under `/admin/regions`.
- Make hierarchy understandable in a table without introducing a tree-grid
  dependency.
- Reuse installed shadcn primitives and existing admin layout/navigation.
- Keep Rails responsible for routing, authorization, I18n, pagination, and data
  selection.

**Non-Goals:**
- No region create/edit/delete/reparent flow.
- No import source/provenance management.
- No closure-table writes, schema changes, or PostGIS query changes.
- No new frontend package such as TanStack Table.

## Decisions

### Use a flat hierarchy table for the first slice

The approved UI is a normal shadcn `Table` where each row includes display-ready
hierarchy data: `depth`, parent path, and children count. The region name cell
uses indentation based on `depth`, making tree structure visible while keeping
pagination, search, and accessibility simple.

Alternatives considered:
- Collapsible tree table: more visually direct, but more complex with
  pagination, filtered search results, keyboard semantics, and future actions.
- Level tabs or kind filters only: simpler, but hides the actual parent chain.

### Keep the page read-only

The first directory exposes only reference data already visible to admins: name,
slug, kind, status, country code, parent path, children count, and created date.
Mutating region hierarchy would need a separate design because closure rows,
source provenance, waterfall associations, and import retry behavior all make
edits higher risk.

### Query with existing relational data

The controller should build one paginated relation ordered by hierarchy-friendly
fields, preload parent/children data as needed, and derive display props without
serializing raw model objects. Search should match region `name`, `slug`, and
`country_code`. Parent path may be derived from closure rows for the current
page only, avoiding a new table or materialized path column.

### No ADR

This change follows existing admin, frontend, and region architecture. It does
not introduce a durable cross-cutting decision, dependency, storage model, or
new integration boundary.

## Risks / Trade-offs

- [Hierarchy can span pages] -> Show parent path on every row so context remains
  visible even when ancestors are on another page.
- [Large trees can make path lookup noisy] -> Limit parent-path derivation to
  the paginated page and use existing closure relations.
- [Admin bypass] -> Keep the controller under `Admin::BaseController` and cover
  guest, member, and admin request scenarios.
- [Overexposed data] -> Serialize explicit row props only; do not expose source
  links, raw model objects, geometry, import records, or policy internals.
- [UI regression] -> Cover the table, search, navigation, empty state, and
  accessibility in component tests.
