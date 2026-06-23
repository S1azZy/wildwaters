## Why

The protected Dashboard is the smallest remaining application-owned business
route and is a useful next migration slice after the public waterfall detail
page. Moving it now proves authenticated Inertia rendering, localized private
page props, and a state-changing sign-out interaction before the more complex
authentication forms are migrated.

## What Changes

- Render the existing protected Dashboard placeholder through an Inertia React
  page and the shared typed React application shell.
- Preserve the current localized title, heading, signed-in identity copy, and
  sign-out action without redesigning or expanding Dashboard functionality.
- Submit sign-out through an accessible Inertia `DELETE /session` button while
  preserving Rails CSRF protection, persisted-session revocation, flash, and
  redirect behavior.
- Keep guest Dashboard requests on the existing Rails authentication redirect
  path.
- Remove the superseded Dashboard ERB template after request, component,
  accessibility, and browser coverage proves the migrated route.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `authentication`: Specify the authenticated Dashboard response and the
  existing sign-out behavior when initiated from the migrated Inertia page.
- `frontend-platform`: Extend the route-by-route migration proof with the first
  protected production Inertia page and state-changing interaction.

## Impact

- Expected outcome: authenticated users see the same Dashboard content and can
  sign out from a React page; guests, sessions, redirects, and localization
  retain their current behavior.
- Task level: Level 2 specified behavior change. No ADR is required because the
  change applies the architecture already accepted in ADR 0005.
- Scope: `DashboardController#show`, the Dashboard page contract and React
  component, sign-out interaction wiring, the Dashboard ERB template, and
  matching Rails/frontend/browser tests.
- Non-goals: profile fields, locale editing, saved waterfalls, account
  settings, auth-form migration, new authorization policy, visual redesign,
  SSR, UI-kit adoption, or changes to Mission Control.
- Dependencies and schema: no new package, gem, service, migration, API, or
  persistent data.
- Assumptions: the shared Inertia shell and request-scoped user locale are the
  supported foundations; `DELETE /session` remains the sole sign-out endpoint.
- Unresolved questions: none. The placeholder scope and current design are
  explicitly preserved.
- Special verification risks: page props must not expose raw session material
  or unnecessary user attributes; the Inertia mutation must retain CSRF,
  session revocation, accessible button semantics, flash, and a correct
  transition to the legacy sign-in route.
