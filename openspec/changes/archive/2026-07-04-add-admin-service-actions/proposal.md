## Why

Wild Waters needs a first application-owned admin surface before operational
tools such as imports can move behind a clear product admin shell. The project
already has `member`/`admin` roles and an admin-only Mission Control Jobs
boundary, so this change turns that foundation into a Rails-authorized Inertia
admin namespace with an initial service-actions placeholder.

Task level: 2. This is a specified behavior, authorization, and UI change. No
ADR is required because it applies the existing Rails/Inertia architecture from
ADR 0005 and shadcn/ui component foundation from ADR 0006.

## What Changes

- Add an application-owned `Admin` namespace route and Inertia page for the
  first admin subsection: service actions.
- Protect all application-owned admin routes with the existing explicit admin
  role check through `Admin::BaseController`.
- Render the admin page through a custom admin layout built from existing
  shadcn/ui primitives and Wild Waters compositions: a top toolbar, a left
  sidebar, and a central working area.
- Include only one sidebar item for now: service actions.
- Render a service-actions placeholder that establishes where future service
  commands, such as starting an import, will live without executing any
  operational command in this change.
- Replace the current single authenticated header action with an account
  dropdown for authenticated users.
- Show `Profile` inside the account dropdown as a disabled grey placeholder.
- Show `Admin` in the dropdown only when Rails says the current user can access
  the admin surface.
- Keep `Log out` as the bottom account-dropdown action and submit it through
  the existing Rails-owned `DELETE /session` flow.
- Preserve the guest header sign-in behavior.

Non-goals:

- Do not build real service command execution, import start/retry controls, job
  scheduling UI, or command audit history.
- Do not add a user-management admin area.
- Do not expose raw user roles, policy internals, session material, credentials,
  reset tokens, or unnecessary user attributes in Inertia props.
- Do not change the existing Mission Control Jobs engine behavior beyond route
  compatibility with the application-owned admin namespace.
- Do not add packages, gems, external services, SSR, a separate SPA/API, or a
  new authorization framework.
- Do not hand-edit `db/structure.sql`.

Assumptions:

- `User#role`, `User#admin?`, and the `role` column already exist and remain
  the role foundation for this slice.
- The first application-owned admin landing page can be the service-actions
  placeholder.
- The account dropdown can expose a minimal admin navigation capability or URL
  for admins instead of exposing the raw role.
- Existing shadcn/ui primitives are enough for the first shell and dropdown; no
  community registry block is required.

Unresolved questions:

- None for the first slice. Future service commands will need a separate
  proposal because they change operational behavior.

## Capabilities

### New Capabilities

- `admin-service-actions`: Defines the application-owned admin namespace,
  service-actions placeholder, admin shell layout, and admin-only access
  boundary.

### Modified Capabilities

- `authentication`: The authenticated application shell adds an account
  dropdown that keeps sign-out accessible and exposes the admin entry only to
  admins.
- `design-system-shell`: The shared header changes from one authenticated
  profile action to a shadcn-backed account dropdown with disabled Profile,
  conditional Admin, and bottom Log out actions.
- `frontend-platform`: The application-owned admin page becomes a protected
  Inertia React route under the existing Vite/React/Tailwind frontend runtime.
- `admin-job-operations`: The existing `/admin/jobs` engine route remains
  admin-only and must not be weakened when the application-owned admin
  namespace is introduced.

## Impact

- Rails routes/controllers: `config/routes.rb`, `Admin::BaseController`, a new
  application-owned admin controller, and request specs for guest/member/admin
  behavior.
- Inertia props: shared shell/account props and page-specific admin service
  actions props, all localized and least-data.
- React frontend: shared header/account dropdown, admin layout components, and
  `Admin/ServiceActions` page/component tests.
- I18n: `en` and `ru` entries for account dropdown, admin navigation, admin
  toolbar, service-actions placeholder, and authorization messages if needed.
- Specs: request coverage for admin-only access and shell prop exposure;
  component/accessibility coverage for account dropdown and admin layout.
- Documentation: OpenSpec artifacts and `CHANGES.md`.
- Verification risks: admin bypass, exposing raw roles through props,
  breaking sign-out, weakening `/admin/jobs`, and creating a sidebar/header
  composition that is not keyboard-accessible.
