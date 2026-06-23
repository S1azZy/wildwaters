## 1. Failing Migration Contract

- [x] 1.1 Add request specs requiring `Sessions/New`, `Registrations/New`,
  `PasswordResets/New`, and `PasswordResets/Edit` Inertia components with exact
  localized props, isolated runtime, and sensitive-key exclusions.
- [x] 1.2 Add request specs requiring failed sign-in, registration, and reset
  update submissions to render the migrated page with `422` and safe generic
  public error state.
- [x] 1.3 Add React component/accessibility tests for the shared auth shell and
  each auth page, including form labels, links, submit actions, and document
  titles.
- [x] 1.4 Add browser coverage for migrated sign-in, registration, reset request,
  and reset edit behavior, including CSRF-backed submissions and redirects.
- [x] 1.5 Run the focused request/frontend/system specs and confirm they fail for
  the expected missing auth Inertia implementation.

## 2. Typed Auth Pages

- [x] 2.1 Add typed shared auth shell props and reusable React form primitives
  that preserve the existing auth CSS classes and accessible labels.
- [x] 2.2 Implement `Sessions/New`, `Registrations/New`,
  `PasswordResets/New`, and `PasswordResets/Edit` React pages through
  `AppShell`.
- [x] 2.3 Extend `AppShell` only as needed for auth layout classes while keeping
  Dashboard and Waterfalls behavior unchanged.
- [x] 2.4 Run focused frontend tests, typecheck, lint, and format until green.

## 3. Rails Inertia Integration

- [x] 3.1 Change auth controllers to render the four GET screens through the
  isolated Inertia layout with display-ready props.
- [x] 3.2 Render failed auth submissions through the same Inertia page contracts
  with existing public failure messages and no backend semantic changes.
- [x] 3.3 Preserve successful redirects, using Inertia external-location behavior
  only where a migrated form targets a legacy destination.
- [x] 3.4 Run focused auth/password-reset request specs and browser specs until
  green.

## 4. Legacy Retirement And Verification

- [x] 4.1 Remove the four superseded auth ERB page templates after migrated
  parity coverage passes.
- [x] 4.2 Sync the implemented behavior into baseline OpenSpec specs and archive
  this completed change in the same PR.
- [x] 4.3 Add a dated `CHANGES.md` entry describing the auth screen migration and
  preserved security behavior.
- [x] 4.4 Run `bin/openspec validate --all --strict`, focused request/frontend/
  system specs, `make frontend-verify`, `make security`, `make verify-fast`,
  and pre-PR `make verify`, recording any unrelated blocker exactly.
