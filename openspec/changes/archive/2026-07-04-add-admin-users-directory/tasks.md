## 1. OpenSpec And Red Tests

- [x] 1.1 Validate `add-admin-users-directory` artifacts with `bin/openspec validate add-admin-users-directory --strict`.
- [x] 1.2 Add failing request specs for admin users authorization, index props, search, pagination, edit props, allowed updates, disallowed fields, and list-level status actions.
- [x] 1.3 Add failing React component tests for the admin users index and edit pages, including table/search/pagination, status action, edit form, and password-field absence.

## 2. Backend Implementation

- [x] 2.1 Add Pagy to the bundle through the containerized dependency flow and wire the minimal Pagy controller integration.
- [x] 2.2 Add admin users routes and implement `Admin::UsersController` under the existing admin authorization boundary.
- [x] 2.3 Serialize least-data users props with search, pagination metadata, editable options, read-only details, and no credential/session/identity fields.
- [x] 2.4 Permit only `display_name`, `role`, and `status` on the edit update path.
- [x] 2.5 Implement list-level suspend/reactivate status actions that preserve every other user and credential field.
- [x] 2.6 Add display-name normalization on `User` if needed by the request specs.

## 3. Frontend Implementation

- [x] 3.1 Add localized `en` and `ru` admin users navigation, table, pagination, search, form, action, validation, and flash copy.
- [x] 3.2 Reuse or extract the admin shell/sidebar composition so service actions and users share the same admin navigation behavior.
- [x] 3.3 Implement the typed `Admin/Users/Index` Inertia page with shadcn-backed table, search form, pagination controls, edit links, and status action forms.
- [x] 3.4 Implement the typed `Admin/Users/Edit` Inertia page with read-only account details and editable display-name, role, and status controls.

## 4. Verification And Documentation

- [x] 4.1 Run the focused admin users request spec and frontend page tests until green.
- [x] 4.2 Update `CHANGES.md` with the admin users directory and Pagy dependency.
- [x] 4.3 Run `bin/openspec validate add-admin-users-directory --strict`.
- [x] 4.4 Run the applicable project gate: `make verify-fast`.
- [x] 4.5 Verify the implementation against OpenSpec artifacts and leave the change ready for archive.

## 5. Admin Dashboard Visual Follow-up

- [x] 5.1 Add/update specs so `/admin` renders an empty admin dashboard instead of service actions.
- [x] 5.2 Add/update frontend tests for dashboard-style admin navigation with icons, Service Actions second, a separated `Models` section, and Users inside it.
- [x] 5.3 Implement `Admin::DashboardController`, route `/admin` to it, and point shared shell admin links at the dashboard.
- [x] 5.4 Update the shared admin layout and existing admin pages to use the grouped dashboard-style navigation contract.
- [x] 5.5 Run focused request and frontend tests, strict OpenSpec validation, and the applicable project gate.

## 6. Admin User Update Interactor Correction

- [x] 6.1 Add interactor specs for admin user updates, allowed-only attributes, validation failures, and missing users.
- [x] 6.2 Implement `Admin::UpdateUser` using the canonical `ApplicationInteractor`/`ApplicationContract` style.
- [x] 6.3 Refactor `Admin::UsersController` so update and status actions delegate writes and validation to the interactor.
- [x] 6.4 Run focused interactor/request specs, RuboCop, strict OpenSpec validation, and the applicable project gate.
- [x] 6.5 Declare admin-editable user attributes explicitly in `Admin::UpdateUser::ValidationContract`.
