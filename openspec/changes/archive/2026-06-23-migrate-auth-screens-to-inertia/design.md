## Context

The Vite/Inertia/React frontend already owns waterfall detail and Dashboard.
The sign-in, registration, password-reset request, and password-reset edit
screens remain ERB pages rendered inside a shared auth shell component. Their
controllers also own state-changing actions, including persisted session
issuance, account creation, enumeration-safe reset requests, reset-token
validation, and session revocation after password changes.

Rails remains the source of truth for authentication, localization, form URLs,
flash, CSRF, redirects, and all security-sensitive state. React receives only
display-ready copy, safe form defaults, and Rails-generated URLs.

## Goals / Non-Goals

**Goals:**

- Move all application-owned auth screens to Inertia React in one PR.
- Preserve the current visual design, routes, copy, generic errors, and backend
  auth/password-reset behavior.
- Use a shared typed React auth shell that mirrors the existing ERB shell.
- Prove successful submissions, validation failures, flash, and cross-runtime
  navigation in request, component, and browser coverage.
- Remove the superseded auth ERB page templates after parity is established.

**Non-Goals:**

- Changing password rules, session cookie policy, CSRF policy, reset-token
  lifetime, mailer rendering, Mission Control, or authorization semantics.
- Introducing SSR, a UI kit, route helpers generated into TypeScript, or a
  design-system migration.
- Migrating the public explore homepage or waterfall index in this slice.

## Decisions

### Migrate complete auth pages instead of partial islands

Each auth GET response will render an Inertia component through the isolated
`inertia` layout. Failed `POST /session`, failed `POST /registration`, and
failed `PATCH /password-reset/:token` responses render the same page components
with `422 Unprocessable Content` and safe public error state.

Partial React islands were rejected because they would keep two browser
runtimes owning one form lifecycle. Keeping failures in ERB was rejected because
it would make the most security-sensitive branch diverge from the migrated page.

### Keep Rails-owned display-ready props

Page props contain translated shell copy, translated field labels, Rails URLs,
safe field defaults, and page-specific form copy. They do not contain password
values, session objects, user objects, policy internals, password-reset token
fields, or account identity objects. The reset edit form receives the token only
as part of the Rails-generated submit URL because the route itself carries the
token.

React does not import Rails locale files or infer backend routes. This follows
the existing frontend-platform contract.

### Preserve existing redirects and add Inertia-safe legacy hops

Successful registration still redirects to Dashboard. Successful reset request
and reset update still redirect to sign-in. Successful sign-in still redirects
to the public explore homepage. Because explore remains legacy-owned, an
Inertia sign-in submission uses `inertia_location(root_path)` after Rails issues
the session and flash, causing a full document visit to the legacy page.

### Use standard Inertia forms

React pages use the Inertia React form API so requests travel through the
adapter-supported CSRF pipeline provided by `inertia_rails`. No CSRF token is
added to page props and Rails CSRF verification remains enabled.

### Leave old shared Ruby auth component cleanup to final legacy-stack removal

The superseded auth ERB page templates are removed in this slice. Ruby UI
components that become unused can be retired during the final old-stack cleanup
unless tooling proves they are no longer referenced and safe to delete now.

## Risks / Trade-offs

- [Sensitive prop leakage] -> Assert exact prop shape and nested-key exclusions
  for auth screens; keep passwords and token fields out of props.
- [CSRF regression] -> Use standard Inertia forms and prove real browser form
  submissions; do not disable CSRF or pass tokens as props.
- [Enumeration leakage] -> Preserve the same reset-request redirect and generic
  success message for existing and missing emails.
- [Legacy destination protocol mismatch] -> Use Inertia external-location
  response for sign-in success because the explore homepage remains legacy.
- [Large auth-screen PR] -> Keep this slice strictly to render transport and
  template retirement; no backend semantics or redesign.

## Migration Plan

1. Add failing request specs for all auth Inertia page contracts, safe props,
   failed submissions, and runtime isolation.
2. Add failing React component/accessibility tests for the shared auth shell and
   each auth page.
3. Add browser coverage for the migrated sign-in, registration, reset request,
   and reset edit flows.
4. Implement the shared React auth shell, typed pages, controller render props,
   and Inertia-safe sign-in redirect to the legacy explore page.
5. Remove the four auth ERB page templates after parity tests pass.
6. Sync baseline specs, archive the completed change, update `CHANGES.md`, and
   run the required frontend, Rails, security, and full verification gates.

Rollback restores the ERB render path and templates. There is no schema,
dependency, route, or persisted-data migration.

## Open Questions

None. The current design and auth behavior are explicitly preserved.
