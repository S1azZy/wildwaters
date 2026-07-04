## Context

Wild Waters is a Rails monolith with application-owned business/admin UI on
Inertia, React, TypeScript, Tailwind, and shadcn/ui. Rails owns routes,
sessions, CSRF, authorization, I18n, and page prop selection. React owns local
rendering and interaction state for migrated application-owned pages.

The repository already contains `User#role`, `User#admin?`, an `admin` role,
and `Admin::BaseController#require_admin!`. Mission Control Jobs is mounted at
`/admin/jobs` and is already protected by that boundary. What is missing is an
application-owned admin landing surface, service-actions placeholder, and a
header entry point that is visible only to admins.

## Goals / Non-Goals

**Goals:**

- Add the first application-owned admin Inertia page under `/admin`.
- Keep authorization centralized in the Rails admin controller boundary.
- Build an admin shell from existing shadcn/ui primitives and Wild Waters
  compositions: top toolbar, left sidebar, central workspace.
- Add one initial sidebar item for service actions.
- Add an account dropdown for authenticated users with disabled `Profile`,
  conditional `Admin`, and bottom `Log out`.
- Keep shared props least-data: expose only the admin navigation capability/URL
  needed by the shell, not the raw role.
- Preserve current guest sign-in behavior and existing sign-out semantics.

**Non-Goals:**

- Starting imports or any other operational command.
- User/role management screens.
- A new authorization framework, policy engine, dependency, service, or data
  model.
- Replacing or redesigning Mission Control Jobs.
- Revealing raw roles or user objects in Inertia props.
- Adding SSR or a separate SPA/API.

## Decisions

### Use existing roles and admin controller boundary

The implementation should reuse the existing `role` column, `User#admin?`, and
`Admin::BaseController`. A new migration for roles would be redundant and would
risk churn around an already implemented auth foundation.

Alternative considered: introduce a new role model or permission table now.
That is too broad for a first admin shell and not needed until multiple roles
or resource-level admin permissions appear.

### Expose an admin capability, not a raw role

The shared shell should receive a small admin navigation contract only when the
current user can access the admin surface, for example a label and URL or an
`available` flag with URL. It should not receive `role`, `admin: true` as a
proxy for all privileges, a user object, or policy internals.

Alternative considered: pass `current_user.role` through shared props and let
React decide. That would leak more server state than the shell needs and would
move an authorization-adjacent decision to the client.

### Build a Wild Waters admin shell from shadcn primitives

The shadcn `sidebar-07` block is the layout inspiration: collapsible sidebar,
inset content, top toolbar, and a central workspace. The implementation should
not copy the block wholesale because it is Next/dashboard-shaped and includes
unneeded team/project/user examples. Instead, use installed primitives such as
dropdown menu, button, separator, empty state/card/table-ready surfaces, and
install the official sidebar primitive only if it is not already present.

Alternative considered: hand-roll the sidebar with page-local Tailwind. That
would work for one page, but it would violate ADR 0006's shadcn-first direction
right as the admin UI begins.

### Keep service actions as a placeholder

The first service-actions page should describe the future workspace without
rendering buttons that imply operational behavior. Future commands such as
starting GeoNames import require their own spec because they introduce
side-effects, idempotency, job enqueueing, audit/feedback, and operational
failure states.

Alternative considered: include a disabled "Start import" command now. That
creates ambiguous acceptance behavior and risks stale UI once the real import
command design exists.

### Preserve `/admin/jobs` behavior

The application-owned admin namespace must coexist with the mounted Mission
Control Jobs engine. `/admin` and `/admin/service-actions` belong to the
application-owned Inertia admin UI; `/admin/jobs` remains the engine surface
and keeps the same guest/member/admin behavior.

## Risks / Trade-offs

- [Admin bypass] -> Keep all admin controllers under `Admin::BaseController`
  and cover guest, member, and admin requests.
- [Role leakage through props] -> Test shell prop keys and pass only a minimal
  admin navigation capability.
- [Broken sign-out] -> Keep the existing `DELETE /session` endpoint and cover
  the dropdown action in component/request behavior.
- [Inaccessible dropdown/sidebar] -> Use shadcn/radix primitives, named menu
  items, disabled semantics for `Profile`, keyboard-accessible links/actions,
  and component accessibility checks.
- [Mission Control route regression] -> Keep `/admin/jobs` coverage and do not
  move the engine into the Inertia page.
- [Placeholder looks actionable] -> Use empty-state/status copy, not command
  buttons, until service command execution is specified.

## Migration Plan

1. Add failing request specs for `/admin`, `/admin/service-actions`, shared
   shell admin navigation, and `/admin/jobs` coexistence.
2. Add failing component tests for the account dropdown and admin page shell.
3. Implement Rails routes/controller/props with `Admin::BaseController`.
4. Implement React account dropdown and admin shell/page using shadcn-backed
   primitives and Wild Waters wrappers.
5. Add `en` and `ru` locale entries.
6. Update `CHANGES.md`.
7. Run narrow request and component specs, then `make security` and
   `make verify-fast`.

Rollback strategy: remove the new application-owned admin routes/page and
admin shell props. Existing user roles and `/admin/jobs` should remain
untouched.

## Open Questions

None for this slice. Real service command execution will need a separate
OpenSpec change.
