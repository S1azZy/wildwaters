## 1. Failing Migration Contract

- [ ] 1.1 Extend `spec/requests/authentication_spec.rb` with the unchanged guest
  redirect plus exact authenticated `Dashboard/Show` Inertia component, layout,
  localized prop, and sensitive-key exclusion expectations.
- [ ] 1.2 Add `app/frontend/test/pages/Dashboard/Show.test.tsx` to require the
  current placeholder copy, document title, accessible sign-out button, shared
  authenticated shell, and no extra account rendering.
- [ ] 1.3 Add a focused Selenium Dashboard system spec that signs in, proves the
  Inertia runtime, activates sign-out, and expects the revoked session,
  localized notice, final sign-in URL, and legacy runtime.
- [ ] 1.4 Run the narrow request, component, and system specs and confirm they
  fail for the expected missing Dashboard Inertia implementation.

## 2. Typed Dashboard Page

- [ ] 2.1 Add typed `Dashboard/Show` props containing only display-ready `copy`,
  Rails-generated `urls`, and the existing shared `shell` contract.
- [ ] 2.2 Implement the React placeholder through `AppShell`, preserving the
  current layout/classes and using an Inertia `Link` rendered as a button with
  `method="delete"` for sign-out.
- [ ] 2.3 Run the focused Dashboard component test, frontend typecheck, lint, and
  format checks until they pass.

## 3. Rails Inertia Integration

- [ ] 3.1 Change `DashboardController#show` to use the isolated Inertia layout
  and render `Dashboard/Show` with translated display-ready props after
  `require_authentication` succeeds.
- [ ] 3.2 Run `spec/requests/authentication_spec.rb` until guest protection,
  authenticated `en`/`ru` props, exact exposure, and existing session behavior
  pass.
- [ ] 3.3 Run the focused Dashboard Selenium spec until the CSRF-protected
  Inertia DELETE, session revocation, flash, and legacy sign-in transition pass.
- [ ] 3.4 If the installed Inertia redirect or CSRF behavior differs from the
  approved design, update the affected OpenSpec artifacts and obtain approval
  before introducing a custom transport or changing session behavior.

## 4. Legacy Retirement And Verification

- [ ] 4.1 Remove `app/views/dashboard/show.html.erb` after the migrated parity
  tests pass, and prove no application-owned Dashboard ERB page remains.
- [ ] 4.2 Add a dated `CHANGES.md` entry describing the protected Dashboard
  migration and preserved sign-out/authentication behavior.
- [ ] 4.3 Run `bin/openspec validate migrate-dashboard-to-inertia --strict`, the
  focused request/component/system specs, and `make frontend-verify`.
- [ ] 4.4 Run `make security`, `make verify-fast`, and the pre-PR `make verify`,
  recording any unrelated existing blocker exactly.
