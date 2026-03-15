# AGENTS.md

## Project

Wild Waters is a Rails monolith for discovering and sharing natural water places, starting with waterfalls.

Core product goals:
- waterfall-first public catalog
- region hierarchy
- map browsing and nearby discovery
- accounts, profiles, follows, reviews, photos, and check-ins
- lightweight activity feed
- bilingual UI (`ru`/`en`)

## Canonical docs

Use these files as the documentation baseline:
- `docs/FOUNDATIONS.md`
- `docs/QUALITY_SECURITY.md`
- `docs/PLAN.md`

Do not create extra feature docs unless explicitly requested.

## Priorities

When tradeoffs appear, prioritize in this order:
1. product value
2. maintainability and consistency
3. delivery speed
4. educational value

## MVP non-goals

Do not build in MVP:
- generic non-waterfall behavior
- AI features
- offline-first sync
- real-time features without a concrete need
- native mobile apps
- complex recommendation or moderation systems
- speculative abstractions for unsupported future spot types

## Stack

Mandatory:
- Ruby `3.4.x` until Ruby 4 is stable
- Rails `8.1.x`
- PostgreSQL `18.x` + PostGIS
- Hotwire (`Turbo + Stimulus`)
- Tailwind CSS
- ERB
- Docker / docker-compose
- Kamal placeholders
- RSpec
- `yabi`
- Pundit
- Active Storage
- I18n with `ru` and `en`

Preferred:
- auth: Rails-native approach unless blocked
- admin: Rails namespace admin UI
- forms: standard Rails forms first
- pagination: Pagy when needed
- enums/state: Rails enum unless richer data justifies a table
- jobs: Rails built-in stack first (`Solid Queue`)

## Architecture

1. Keep controllers thin.
2. Keep models thin; persistence and local invariants only.
3. Business use cases live in `app/interactors` and use one consistent `yabi` style.
4. Authorization is explicit and centralized.
5. Keep web and API flows aligned through shared domain/use-case logic.
6. Waterfall-first behavior is a hard product rule even if the schema is extensible.
7. Avoid speculative abstractions and one-off local patterns.
8. Naming, testing, authorization, UI, and service patterns must stay uniform.

## Database

- Prefer SQL-forward migrations in Rails wrappers.
- Use explicit `up` / `down`.
- Use `structure.sql`, not `schema.rb`.
- Do not edit `db/structure.sql` by hand; it may change only as a generated artifact of migrations/schema dump.
- Default to `NOT NULL`, `FOREIGN KEY`, and indexes where justified.
- Use `CHECK` only for true storage-level invariants.
- Do not add triggers or stored procedures unless explicitly approved.
- Prefer PostgreSQL `uuidv7()` UUID primary keys for main domain tables.
- Match foreign key types to referenced primary keys.
- If generators are used, prefer `--skip-migration` when that helps preserve migration style.

## Security

- Never store plaintext passwords.
- Never log passwords, reset tokens, secrets, or raw credentials.
- Secrets only via env/credentials.
- CSRF must stay enabled.
- Session/cookie settings must be strict.
- Authorization is required on every user-owned resource.
- Admin access must be role-protected.
- Brakeman, bundler-audit, RuboCop, and RSpec must run in CI.
- Authentication flows must be security-first.

## Quality gates

Before merge:
- tests pass
- linters pass
- security scans pass
- no obvious N+1 in changed areas
- policy coverage exists for new secured flows
- new business logic uses the canonical `yabi` interactor style
- new code matches project conventions
- migrations follow project DB rules
- `CHANGES.md` is updated
- RuboCop runs with autocorrect by default

## Git workflow

- Work in a dedicated branch.
- Codex branches must use the `codex/` prefix.
- Merge through GitHub Pull Requests, not direct commits to `main`.
- Before opening or updating a PR, run the local verification flow.

## Coding style

- Favor readability over cleverness.
- Prefer explicit names.
- Keep methods short.
- Avoid hidden side effects.
- Avoid fat helpers.
- Prefer boring, inspectable Rails patterns.
- Use POROs for business operations.
- Add comments only when they reduce real complexity.

## Testing rules

- Prefer integration with the real database over mocks/stubs.
- Do not mock app code without a concrete need.
- Persistence-touching business logic should be tested against the real database.
- Use `test-prof` when improving test performance or factory usage.
- Use `shared_context` / `shared_examples` only when they reduce duplication without hiding intent.

## Strict rules

1. Every code change starts with a failing test.
2. Do not write production code before the test is red.
3. If the test is not red first, rewrite the test before writing code.
4. The only valid flow is: red test, minimal code, green test.
5. Code written before the test is a process error and must be corrected.

## Not to do

- Do not write code before writing the test.
- Push to main

## Directory expectations

- `app/interactors`
- `app/policies`
- `app/presenters` or `app/view_models` if needed
- `app/components` only after an explicit project decision
- `spec/requests`
- `spec/system`
- `spec/interactors`
- `spec/policies`
- `spec/models`

## Agent behavior

When generating code:
- prefer stable, boring solutions
- prefer official Rails conventions over exotic gems
- explain tradeoffs when introducing dependencies
- do not invent undocumented requirements
- implement the smallest safe and testable solution when uncertain
- preserve project coherence over local optimization
- keep `CHANGES.md` current
- run RuboCop with autocorrect by default
