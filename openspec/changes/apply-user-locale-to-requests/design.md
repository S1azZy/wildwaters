## Context

`User#locale` is already required and restricted to the configured `en` and
`ru` locales. The authentication concern restores `Current.user` in a
`before_action`, while Rails views, controller flash messages, and Inertia
shared props call `t(...)` later in request processing. Today no controller
callback selects a locale, so all of those translations use the configured
default `en`.

This is an authentication-adjacent request behavior change, but it does not
change credential validation, session issuance, cookie attributes,
authorization, or exposed user data.

## Goals / Non-Goals

**Goals:**

- Select the stored locale after an active session has restored the current
  user.
- Keep translation lookup consistent across authorization callbacks, controller
  actions, rendering, flash construction, and server-generated Inertia props.
- Restore the previous locale after every request, including redirects and
  exceptions.
- Prove both authenticated locale choices and guest fallback with request
  specs.

**Non-Goals:**

- Selecting a locale from a URL, request parameter, cookie, browser header, or
  registration form before authentication completes.
- Changing a user's stored locale.
- Translating mailers or engine-owned pages such as Mission Control.
- Changing session, cookie, CSRF, authentication, or authorization semantics.

## Decisions

### Use a request-scoped controller around callback

Add an `around_action` to `ApplicationController` after the authentication
concern has registered `resume_session`. The callback chooses
`current_user&.locale || I18n.default_locale` and runs the remaining callback
chain and action inside `I18n.with_locale`.

The existing callback order is significant: session restoration runs first;
the locale wrapper then covers subclass callbacks such as
`require_authentication`, the controller action, rendering, and Inertia shared
prop evaluation.

`I18n.with_locale` is preferred over assigning `I18n.locale` in a
`before_action` because it restores the previous thread-local locale with an
`ensure` path when processing returns early or raises.

Alternatives considered:

- Select locale inside `resume_session`: rejected because authentication should
  remain responsible for identity/session restoration, while request I18n is an
  application-controller concern.
- Use paired `before_action` and `after_action` callbacks: rejected because an
  `after_action` is easier to bypass during exceptional processing and
  duplicates cleanup already provided by `I18n.with_locale`.
- Negotiate guest locale from `Accept-Language` or a cookie: rejected as a
  separate product behavior with persistence and precedence decisions that are
  not needed for this migration prerequisite.

### Base the request locale on authentication state at request start

The locale is selected after session resumption and before the action. A sign-in
or registration POST that begins without an active session therefore uses the
guest default locale; the newly authenticated user's stored locale applies on
the next request. This keeps locale selection deterministic and avoids coupling
session issuance actions to I18n callback state.

### Keep the stored locale as the trusted source

The callback uses only `User#locale`, whose model validation restricts values to
`I18n.available_locales`, or the configured default for guests. No
client-supplied locale is accepted during ordinary requests, and no additional
user fields are exposed through Inertia.

### No ADR

No ADR is created. The change applies the existing Rails I18n mechanism to an
existing persisted field and does not introduce a durable technology or system
boundary decision.

## Risks / Trade-offs

- [Callback ordering changes could select locale before session restoration]
  -> Add request coverage that renders locale-specific output for an
  authenticated user and keep the locale callback registration adjacent to the
  authentication include.
- [A non-default locale could leak to a later request on the same thread] ->
  Use `I18n.with_locale` and cover a non-default authenticated request followed
  by a guest request.
- [The sign-in success flash can remain English for a user whose stored locale
  is Russian] -> Accept this bounded behavior because the sign-in request began
  unauthenticated; revisit only as part of the future auth-screen locale design.
- [Unexpected invalid persisted locale] -> Rely on the existing model
  validation and database/application write paths; the callback retains the
  default-locale fallback only for the absence of an authenticated user.

## Migration Plan

1. Add failing request specs for authenticated `ru`, authenticated `en`, guest
   fallback, and cross-request isolation.
2. Add the request-scoped locale callback without changing routes, persistence,
   or frontend code.
3. Run the narrow authentication request specs, then the auth/security and fast
   project gates.
4. Update `CHANGES.md` and remove the completed locale item from `docs/TODO.md`
   during implementation.

Rollback is a controller-only revert. No stored data or schema transition is
required.

## Open Questions

None. Guest locale negotiation and locale editing remain separate future
changes.
