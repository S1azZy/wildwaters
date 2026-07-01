## 1. Failing Contracts

- [x] 1.1 Add request coverage for `/admin` and `/admin/service-actions` guest,
  member, and admin access, including exact redirect targets, flash messages,
  Inertia component, and sensitive prop exclusion.
- [x] 1.2 Extend `/admin/jobs` request coverage so the mounted jobs engine keeps
  its guest/member/admin behavior after the application-owned admin namespace
  exists.
- [x] 1.3 Add shared shell request coverage proving admin navigation props are
  present only for admins and raw role/user/session data is not serialized.
- [x] 1.4 Add component coverage for the authenticated account dropdown: disabled
  Profile, conditional Admin, bottom Log out, guest sign-in fallback, keyboard
  accessibility, and no admin item for members.
- [x] 1.5 Add component coverage for the admin service-actions page and shell:
  top toolbar, single service-actions sidebar item, current state, central
  placeholder, and no enabled service command action.
- [x] 1.6 Run the narrow request/component specs through the supported
  container/Make path and confirm they fail for the expected missing behavior.

## 2. Rails Admin Boundary

- [x] 2.1 Add application-owned admin routes for the admin root and
  service-actions page without shadowing `/admin/jobs`.
- [x] 2.2 Implement the admin service-actions controller under
  `Admin::BaseController` with least-data localized Inertia props and the
  Inertia layout.
- [x] 2.3 Extend shared shell props with a minimal account/admin navigation
  contract that exposes the admin entry only when `current_user.admin?`.
- [x] 2.4 Add `en` and `ru` locale entries for account dropdown labels, admin
  navigation, admin toolbar, and service-actions placeholder copy.
- [x] 2.5 Run the focused request specs until the admin authorization and prop
  contracts are green.

## 3. React Admin Shell And Account Menu

- [x] 3.1 Implement or extend shared header components so authenticated users get
  a shadcn-backed account dropdown instead of the current single profile link.
- [x] 3.2 Keep the dropdown Profile item disabled and visually muted, show Admin
  only from the Rails-provided admin navigation contract, and submit Log out
  through the existing `DELETE /session` Inertia/Rails flow.
- [x] 3.3 Add admin shell components built from shadcn-backed primitives and
  Wild Waters compositions: top toolbar, left sidebar, and central workspace.
- [x] 3.4 Implement `Admin/ServiceActions` as a typed route-level Inertia page
  using the admin shell and placeholder copy.
- [x] 3.5 Run the focused component tests, frontend typecheck, lint, format, and
  build-relevant checks through Make/container targets until green.

## 4. Documentation And Verification

- [x] 4.1 Add a dated `CHANGES.md` entry for the admin namespace, service-actions
  placeholder, admin-only account entry, and preserved sign-out behavior.
- [x] 4.2 Run `bin/openspec validate add-admin-service-actions --strict` and
  resolve artifact issues.
- [ ] 4.3 Run the narrow request/component specs, then `make security` for the
  admin/auth boundary.
  - Narrow request/component specs passed. `make security` is blocked by
    `crass 1.0.6` advisories requiring `crass >= 1.0.7`; dependency updates
    need separate approval.
- [x] 4.4 Run `make verify-fast`, recording any unrelated existing blocker
  exactly.
- [x] 4.5 If implementation learning changes the approved admin shell, props,
  authorization, or service-actions scope, update these OpenSpec artifacts and
  obtain approval before continuing.
