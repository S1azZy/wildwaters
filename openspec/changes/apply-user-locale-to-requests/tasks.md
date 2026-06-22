## 1. Request Contract

- [x] 1.1 Add request specs proving that an active `ru` user's translated
  response uses Russian and an active `en` user's response uses English.
- [x] 1.2 Add request specs proving that guests use the application default
  locale and that a prior authenticated `ru` request cannot leak its locale
  into a later guest request.
- [x] 1.3 Run `bundle exec rspec spec/requests/authentication_spec.rb` and
  confirm the new examples fail for the expected missing locale-selection
  behavior.

## 2. Request-Scoped Locale

- [x] 2.1 Add the minimal `ApplicationController` around callback that runs
  request processing inside `I18n.with_locale(current_user&.locale ||
  I18n.default_locale)` after session restoration.
- [x] 2.2 Run `bundle exec rspec spec/requests/authentication_spec.rb` until all
  authentication request examples pass.
- [x] 2.3 If callback behavior differs from the approved design, update the
  affected OpenSpec artifact and obtain approval before changing the intended
  contract.

## 3. Documentation And Verification

- [x] 3.1 Add a dated `CHANGES.md` entry and remove the completed stored-user
  locale item from `docs/TODO.md`.
- [x] 3.2 Run `bin/openspec validate apply-user-locale-to-requests --strict`.
- [x] 3.3 Run `make security` and record any unrelated existing failure
  exactly.
- [x] 3.4 Run `make verify-fast` and record any unrelated existing failure
  exactly.
