## Why

The remaining application-owned authentication screens still use the legacy
Rails runtime while Dashboard and waterfall detail already prove the Inertia
stack. Migrating the complete auth-screen group now removes a central ERB
surface, proves form submissions and validation errors through React, and keeps
Rails as the owner of authentication, CSRF, sessions, password reset, flash,
and redirects.

## What Changes

- Render sign-in, registration, password-reset request, and password-reset edit
  screens as typed Inertia React pages through the existing isolated frontend
  runtime.
- Preserve the current auth shell design, localized copy, form fields, routes,
  redirects, and generic authentication/password-reset failure messages.
- Keep all session issuance, registration, password-reset token validation,
  account enumeration protection, and session revocation behavior in Rails.
- Retire the superseded auth ERB page templates after request, component,
  accessibility, and browser coverage proves parity.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `authentication`: Specify that registration and sign-in pages and validation
  errors render through typed Inertia auth screens.
- `password-reset`: Specify that reset request and reset edit screens render
  through typed Inertia auth screens while retaining enumeration-safe and
  token-safe backend behavior.
- `frontend-platform`: Extend the route-by-route migration proof to include
  form-based guest auth screens and safe cross-runtime redirects.

## Impact

- Expected outcome: visitors see the same auth UI, but the screens are served by
  React/Inertia; successful and failed submissions keep their existing public
  behavior.
- Task level: Level 2 specified behavior change. No ADR is required because the
  work applies the already accepted frontend architecture.
- Scope: auth controllers' render paths, auth React pages/components, auth ERB
  template retirement, request/frontend/system tests, baseline OpenSpec sync,
  and `CHANGES.md`.
- Non-goals: mailers, Mission Control, backend auth semantics, new UI kit,
  redesign, SSR, profile/account features, route changes, or new dependencies.
- Dependencies and schema: no new package, gem, service, migration, API, or
  persisted data.
- Special verification risks: page props must not expose password material, raw
  session state, policy internals, or reset token data beyond the unavoidable
  route URL; Inertia form submissions must retain CSRF protection and safe
  generic errors.
