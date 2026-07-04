## Context

Wild Waters already has an application-owned admin namespace protected by
`Admin::BaseController`, plus `User#role`, `User#status`, `User#display_name`,
`User#locale`, and `User#primary_email`. Password material is stored on
`UserIdentity`, not directly on `User`, and must remain outside the admin
directory contract.

The frontend boundary is the existing Rails/Inertia/React architecture from
ADR 0005 and the shadcn/ui component foundation from ADR 0006. Rails owns
routes, authorization, data selection, I18n, and form endpoints; React owns
rendering and local interaction for the admin pages.

## Goals / Non-Goals

**Goals:**

- Add a protected users directory suitable as the first real admin reference
  screen.
- Add an admin dashboard as the `/admin` entrypoint, keeping service actions as
  a secondary admin page.
- Shape the admin navigation after shadcn's dashboard block pattern: compact
  left sidebar, icons for clickable items, and a separated Models section.
- Provide compact admin table, search, pagination, list-level status action,
  and a focused edit page.
- Keep the editable contract limited to `display_name`, `role`, and `status`.
- Keep credential fields out of params, props, rendered forms, and tests.
- Use a standard pagination dependency rather than ad hoc pagination helpers.

**Non-Goals:**

- No password viewing, editing, reset, or identity management.
- No email or locale editing.
- No delete, bulk actions, impersonation, audit log, or role hierarchy.
- No new admin authorization framework or separate API surface.
- No schema migration.

## Decisions

### Use Pagy for Rails pagination

Pagy will provide the server-side pagination primitive for the users directory.
It keeps pagination logic centralized and lightweight while allowing Rails to
serialize only the page links and counts that the Inertia page needs.

Alternatives considered:

- Manual `limit`/`offset`: lowest dependency cost, but likely to duplicate page
  counting, bounds, and link-building as soon as more admin directories appear.
- Kaminari: familiar Rails API, but heavier and more model-scope-oriented than
  this bounded controller use case needs.

### Keep data selection in `Admin::UsersController`

The first directory can stay in a controller-private query method: order by
`created_at DESC, id DESC`, optionally filter by a normalized search term, and
paginate with a fixed default page size. A dedicated query object is deferred
until another admin directory or more complex filters make reuse real.

Search matches `primary_email` and `display_name` case-insensitively. Blank
search behaves like the unfiltered list.

### Serialize a least-data admin user row

User props include only:

- `id`
- `displayName`
- `email`
- `role`
- `status`
- `locale`
- `createdAt`
- URLs/actions needed by the page

The edit page may additionally include `updatedAt` if useful for read-only
context. Props MUST NOT include `password`, `passwordDigest`,
`password_digest`, identity records, session records, reset tokens, or raw
policy internals.

### Edit with Rails-owned forms and interactor-owned writes

The edit form submits to Rails with `PATCH /admin/users/:id`. The controller
accepts only request-shaped input and delegates the write use case to
`Admin::UpdateUser`. That interactor locates the target user, applies only
`display_name`, `role`, and `status` declared explicitly in its
`ValidationContract`, and returns structured failures for missing records or
validation errors. Email, locale, IDs, timestamps, password fields, identity
attributes, and session attributes are ignored or rejected outside the
persisted update.

The list-level suspend/reactivate action also submits to Rails and calls the
same interactor with only `status`. The controller maps the interactor result to
HTTP redirects or validation rendering; it does not own role/status validation
or persistence decisions.

### Reuse the existing admin shell composition

The users index, edit page, service actions page, and dashboard should reuse the
same AppShell/admin sidebar pattern. The shared admin layout should follow the
structure of shadcn's `dashboard-01` block closely enough to provide an inset
admin workspace: left sidebar, page header, and content canvas.

Navigation is structured as top-level clickable items for Dashboard and Service
Actions, followed by a separated, non-clickable `Models` section that contains
Users. Each clickable item carries a stable icon key so React can render
page-appropriate Lucide icons without Rails exposing component names.

Broad admin framework abstractions remain out of scope; keep the shared layout
feature-local under the current admin pages.

## Risks / Trade-offs

- Password exposure -> request specs assert sensitive keys are absent from
  Inertia props; component specs assert no password fields render.
- Privilege escalation -> guest/member/admin request specs cover the admin
  boundary; update specs cover only admin access.
- Accidental wide update -> controller params are allow-listed and specs try to
  submit disallowed email, locale, and password fields.
- Admin lockout by self-suspension or self-demotion -> this pilot allows role
  and status edits for users generally, including self, because the requirement
  did not define self-protection. This is a known follow-up policy decision if
  production admin operations need guardrails.
- Pagination dependency drift -> Pagy is locked through Bundler and verified by
  the existing dependency/security gates.
- Large search performance -> the first pilot uses simple `ILIKE` search. If
  user counts grow, a later change can add indexes or trigram search with
  measured need.

## Migration Plan

1. Add Pagy to the bundle through the containerized dependency flow.
2. Add tests for admin access, least-data props, search, pagination, allowed
   updates, disallowed fields, status action, and React page behavior.
3. Implement controller, routes, I18n, and React pages.
4. Validate OpenSpec and run the required narrow specs and project gate.

Rollback removes the new routes/controller/pages/locales and the Pagy
dependency. No database rollback is needed because no schema change is made.

## Open Questions

None for this pilot.
