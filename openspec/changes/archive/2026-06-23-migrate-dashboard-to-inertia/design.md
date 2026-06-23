## Context

The public waterfall detail route already proves the Vite/Inertia/React runtime
and shared typed React application shell. The Dashboard remains a protected ERB
placeholder that renders a localized title, heading, signed-in email sentence,
and Rails `button_to` sign-out action. It is the smallest remaining route that
can prove authenticated Inertia props and a state-changing request.

Rails continues to own authentication, request-scoped locale selection, CSRF,
persisted-session revocation, flash, and redirects. The installed
`inertia_rails` integration sets the `XSRF-TOKEN` cookie and maps Inertia's
`X-XSRF-TOKEN` request header into Rails CSRF verification, so no token belongs
in page props.

## Goals / Non-Goals

**Goals:**

- Move only `GET /dashboard` from the legacy Rails runtime to an Inertia React
  page while preserving the current design and placeholder content.
- Keep guest authentication enforcement and the existing `DELETE /session`
  business behavior unchanged.
- Use a typed, display-ready, least-data page contract localized by Rails.
- Prove the Inertia sign-out mutation and transition back to the legacy sign-in
  runtime in a real browser.
- Remove the superseded Dashboard ERB template after parity is established.

**Non-Goals:**

- Adding profile, settings, locale editing, saved-waterfall, or other account
  functionality.
- Migrating sign-in, registration, or password-reset pages.
- Changing session issuance, cookie attributes, CSRF policy, routes,
  authorization policy, or authentication interactors.
- Redesigning the Dashboard, adopting a UI kit, adding SSR, or optimizing all
  navigation between migrated pages.

## Decisions

### Migrate the complete route through the existing Inertia layout

`DashboardController#show` will render `Dashboard/Show` through the isolated
Inertia layout. Guest requests continue to stop in `require_authentication`
before any page props are produced. The legacy and React runtimes will not
co-own the route.

This follows ADR 0005 and the waterfall-detail pattern. React islands inside
the ERB page were rejected because they would introduce mixed lifecycle
ownership, while migrating the whole auth-screen group was rejected as too much
form validation and error-response behavior for this proof slice.

### Send display-ready copy instead of a user object

The page-specific contract will contain:

- `copy.title`
- `copy.heading`
- `copy.signedInAs`, already interpolated with the current user's primary email
- `copy.signOut`
- `urls.signOut`
- the existing shared `shell`

The primary email is necessarily present inside the user-visible sentence, but
it will not be exposed as a reusable account object or separate identity prop.
The exact top-level and nested prop keys will be asserted, including the
absence of session, credential, token, role, status, policy, and unrelated user
fields.

Passing a general `user` object was rejected because it expands the private
response surface without serving the placeholder. Formatting the sentence in
React was rejected because Rails owns localization and display formatting.

### Use the standard Inertia Link as an accessible DELETE button

The page will render Inertia's `Link` with `as="button"`, `method="delete"`,
and the Rails-generated session URL. This provides button semantics and uses
the adapter's supported request pipeline, including the CSRF cookie/header
bridge already supplied by `inertia_rails 3.21.2`.

A hand-built fetch call was rejected because it would duplicate Inertia request
and redirect handling. A native form with a CSRF token prop was rejected because
it would expose infrastructure data to the page contract and bypass the
migration's first-mutation proof. A plain link using a non-GET method was
rejected because destructive actions require button semantics.

Rails keeps the existing sign-out result: revoke the persisted session, clear
browser authentication, issue the localized notice, and reach the legacy
sign-in route. Plain Rails requests continue to receive the existing
`303 See Other` redirect. Inertia sign-out requests use the adapter-supported
`inertia_location(new_session_path)` response so the browser performs a full
document visit to the legacy route instead of trying to consume non-Inertia
HTML as an Inertia response. The browser system test is the authoritative
proof that Inertia performs the cross-runtime transition correctly.

### Keep the shared header unchanged

The authenticated Profile action may continue using a normal anchor even when
its Dashboard destination is migrated. Full-document navigation remains valid
during route-by-route migration and avoids expanding this slice into shared
navigation optimization. Explore and guest sign-in still target legacy routes.

### Preserve the existing visual surface

The React page will port the current Dashboard layout and utility classes into
one focused component inside `AppShell`. No reusable account-card abstraction
or new visual primitive is justified by this placeholder.

### No ADR

No ADR is created. The route, rendering boundary, typed-prop ownership, and
migration strategy are already owned by ADR 0005.

## Risks / Trade-offs

- [The first Inertia DELETE could fail CSRF verification] -> Use only the
  adapter-supported Link transport and prove the real click path with Selenium;
  do not send CSRF material as props or disable verification.
- [The redirect from an Inertia mutation to a legacy page could leave the
  browser in a protocol error state] -> Assert the final sign-in URL, legacy
  runtime markers, localized notice, and revoked session in browser/request
  coverage.
- [Private identity data could spread into shared props or history] -> Keep the
  email only inside page-specific display-ready copy, assert the exact prop
  shape, and retain no general user object.
- [Migrating the placeholder could invite premature account features] -> Keep
  the ERB content and styling at parity and treat future profile/value-loop work
  as separate OpenSpec changes.
- [Normal anchors between migrated pages cause full reloads] -> Accept the
  functional behavior during migration; optimize navigation only when a
  concrete shared-shell change is justified.

## Migration Plan

1. Add failing request specs for guest protection and the exact authenticated
   Inertia page/prop/runtime contract.
2. Add a failing React component/accessibility test for the placeholder and
   sign-out button.
3. Implement the controller response, typed page component, and standard
   Inertia DELETE action with no auth/session backend changes.
4. Add browser proof for authenticated rendering, sign-out revocation, flash,
   and the transition to the legacy sign-in runtime.
5. Remove the Dashboard ERB template only after parity tests pass.
6. Update `CHANGES.md`, complete OpenSpec tasks, and run the narrow plus full
   frontend/Rails/security gates required by `docs/DEVELOPMENT.md`.

Rollback restores the ERB render path and template. There is no schema,
dependency, route, or persisted-data migration.

## Open Questions

None. Dashboard remains the approved placeholder and the existing sign-out
endpoint remains authoritative.
