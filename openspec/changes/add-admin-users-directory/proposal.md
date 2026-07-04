## Why

Wild Waters needs a first real admin reference-directory screen to validate the
application-owned admin UI pattern beyond placeholders. Users are the right
pilot because the model already has roles, statuses, display names, locales,
emails, and timestamps, while still requiring careful least-data handling around
password credentials.

Task level: 2. This is a specified admin UI, authorization, dependency, and
user-state management change. No ADR is required because it applies the
accepted Rails/Inertia architecture from ADR 0005 and shadcn/ui component
foundation from ADR 0006.

## What Changes

- Add an application-owned admin users directory under `/admin/users`.
- Add a users item to the existing admin navigation alongside service actions.
- Render a paginated users table with a reasonable default page size.
- Support searching users by email or display name.
- Allow admins to open an individual user edit page.
- Allow admins to edit only `display_name`, `role`, and `status`.
- Allow admins to suspend or reactivate a user directly from the list.
- Show email, locale, created date, role, status, and display name as
  display-ready admin data.
- Keep password credentials out of admin props, forms, permitted params, and
  rendered UI.
- Add Pagy as the Rails pagination dependency for this directory.

Non-goals:

- Do not expose, view, edit, reset, or regenerate user passwords.
- Do not edit user email, locale, primary email verification, identities,
  sessions, or password digests.
- Do not add bulk actions, delete users, impersonation, exports, audit history,
  role hierarchies, or a separate admin authorization framework.
- Do not weaken existing `/admin/jobs` or service-actions authorization.
- Do not add a separate SPA/API, external service, or new frontend state
  framework.

Assumptions:

- `users.display_name` already exists and remains nullable.
- `User::ROLES` and `User::STATUSES` remain the source of editable role and
  status options.
- Admin user-management changes can use the existing `Admin::BaseController`
  boundary for this pilot.
- Pagy is the preferred pagination gem for this bounded admin collection.

Unresolved questions:

- None for the pilot directory. More sensitive account operations need separate
  proposals.

## Capabilities

### New Capabilities

- `admin-users-directory`: Defines the protected admin users directory, search,
  pagination, editable fields, list-level status action, least-data props, and
  password exclusion boundary.

### Modified Capabilities

- None. The existing service-actions page keeps its behavior; this change only
  adds another admin navigation target.

## Impact

- Rails routes/controllers: `config/routes.rb`, `Admin::UsersController`, and
  admin request specs for guest, member, admin, list, search, edit, update, and
  status-toggle behavior.
- Models/dependencies: `User` display-name normalization if needed, Pagy in the
  locked bundle, and no schema change.
- Inertia props: localized copy, admin navigation, paginated users, editable
  options, form URLs, and least-data user records.
- React frontend: admin users index/edit pages built from existing shadcn/ui
  primitives and Wild Waters compositions.
- I18n: `en` and `ru` entries for admin users navigation, table, pagination,
  search, form, actions, and flash messages.
- Specs: request coverage for admin authorization and sensitive prop exclusion;
  component coverage for table/search/pagination, list status action, edit form,
  and password-field absence.
- Documentation: OpenSpec artifacts and `CHANGES.md`.
- Verification risks: admin bypass, privilege escalation, password exposure,
  accidental editing of non-allowed user attributes, broken pagination/search,
  and regressions in the existing admin shell.
