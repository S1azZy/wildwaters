## Why

Registration already persists each user's supported locale, but subsequent
authenticated requests still render Rails translations with the application
default. Applying the stored locale now gives future Inertia pages and the
remaining Rails-owned business frontend a consistent translated request
context before more authenticated pages are migrated.

## What Changes

- Execute authenticated application requests using the active user's stored
  `en` or `ru` locale.
- Keep unauthenticated requests on the application default locale (`en`).
- Scope the selected locale to one request so it cannot leak into later
  requests handled by the same process or thread.
- Preserve existing authentication, session, redirect, and cookie behavior.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `authentication`: Extend persisted-session behavior so a restored user also
  determines the request-scoped locale.

## Impact

- Expected outcome: Rails translations, flash messages, ERB responses, and
  server-generated Inertia props use the authenticated user's stored locale.
- Task level: Level 2 specified behavior change. No durable architecture
  decision or ADR is required because this uses Rails I18n and the existing
  persisted user field.
- Scope: application-owned controller requests that participate in the normal
  authentication concern.
- Non-goals: locale switching UI, profile locale editing, locale URL segments,
  query or cookie overrides, `Accept-Language` negotiation, mailer locale
  changes, and changes to Mission Control rendering.
- Dependencies and schema: no new dependency, migration, public API, or
  frontend package.
- Assumptions: `User#locale` remains validated against
  `I18n.available_locales`; the configured default locale remains `en`.
- Unresolved questions: none for this change. Guest locale negotiation can be
  proposed separately if product requirements emerge.
- Special verification risk: request locale must be selected only after
  session restoration and must be reset even when request processing raises or
  redirects.
