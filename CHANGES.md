# Changes

## 2026-03-15
- Replaced the README CI badge with the native GitHub Actions badge to avoid external badge lookup failures.
- Simplified the README badges to keep only CI status and coverage.

## 2026-03-12
- Added initial project documentation pack for Wild Waters.
- Defined product foundations, delivery phases, and quality/security baseline.
- Locked waterfall-first MVP scope with future extensibility through the `Spot` root entity.
- Generated a clean Rails 8.1 application skeleton without business code.
- Added bootstrap infrastructure files for Docker, local workflow, tool versions, and Kamal placeholder config.
- Installed Rails framework scaffolding for Hotwire, Tailwind, RSpec, and PostGIS-ready configuration.
- Updated local and CI database images to PostgreSQL 18 via `postgis/postgis:18-3.6`.
- Removed project-level Minitest scaffolding and standardized CI/test entrypoints on RSpec only.
- Synced the bootstrap/tooling layer closer to gymapp: dev Docker image, Make targets, RuboCop/RSpec setup, git hooks, editor config, and GitHub workflow/pull request templates.
- Added bootstrap integration for Pundit and FactoryBot without introducing domain-specific policies or factories.
- Added Shoulda Matchers to the RSpec/Rails bootstrap setup.
- Added a CODEOWNERS file assigning the repository to @s1azzy.
- Added `yabi` as the canonical interactor foundation and introduced app-level base interactor/contract classes for upcoming auth work.
- Added an adapted project `AGENTS.md`, enabled bilingual `ru` / `en` groundwork, and aligned project rules around `yabi`, ERB, `structure.sql`, and preferred `uuidv7()` primary keys for user-facing tables.
- Added Stage 1 auth foundation with `users`, `user_identities`, and `sessions` models/migration to support password auth now and multi-provider auth later.
- Relaxed auth database constraints so provider-specific and other business rules stay in models/interactors unless a `CHECK` is clearly necessary at the storage level.
- Updated auth model normalization to use Rails `normalizes` and formalized the rule to prefer current default framework/library conventions unless the project explicitly decides otherwise.
- Consolidated shared auth provider constants under a small auth namespace and aligned locale validation with the application-level I18n configuration.
- Refined auth provider constants to expose both a canonical list and named values for clearer, safer model logic and specs.
- Added Stage 2 web auth with password sign up/sign in/sign out, persisted session tokens, `Current`-based request authentication, protected dashboard flow, and request/interactor coverage.
- Added `faker` as an optional test/development helper for readable factories without making it mandatory across all specs.
- Added Stage 3 password reset flow with one-time token digests, reset mail delivery, active-session revocation after password change, and generic reset-request responses that do not reveal account existence.
- Extracted a shared `EmailNormalizer` so account and auth flows use one canonical email normalization rule.
- Vendored a local `Nanoid` module in `lib/` to own short public identifier generation without adding a gem dependency.
