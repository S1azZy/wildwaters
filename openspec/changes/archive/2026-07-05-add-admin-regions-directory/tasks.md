## 1. Red Tests

- [x] 1.1 Add request specs for `/admin/regions` guest, member, and admin access, least-data props, hierarchy rows, pagination, and search.
- [x] 1.2 Add component coverage for `Admin/Regions/Index` table rendering, hierarchy offset, search form, pagination, empty state, navigation current state, and accessibility.
- [x] 1.3 Run the focused request and component specs to confirm they fail for the missing route/page.

## 2. Backend Implementation

- [x] 2.1 Add the admin regions route and controller under the existing `Admin::BaseController` boundary.
- [x] 2.2 Build explicit region row props with page-limited hierarchy context, search, pagination, display-ready dates, and no raw model/import/closure/geometry payloads.
- [x] 2.3 Add Regions to admin navigation with localized `en` and `ru` copy.

## 3. Frontend Implementation

- [x] 3.1 Add the `Admin/Regions/Index` Inertia page using the existing admin layout and installed shadcn primitives.
- [x] 3.2 Render the flat hierarchy table with level indentation, badges, search, pagination, and empty state.
- [x] 3.3 Run focused request/component specs until green, then run frontend typecheck/lint/test checks required for the React page.

## 4. Verification And Docs

- [x] 4.1 Add a dated `CHANGES.md` entry for the admin regions directory.
- [x] 4.2 Run `bin/openspec validate add-admin-regions-directory --strict`.
- [x] 4.3 Run the applicable `docs/DEVELOPMENT.md` gate for a React/Inertia admin page: narrow request and component specs, then `make verify-fast`.
- [x] 4.4 Verify the change against OpenSpec artifacts and archive it when implementation, tests, and validation are complete.
