# AGENTS.md

## Purpose

This file is the Codex operating contract for Wild Waters. Keep it short and
actionable. Product, architecture, quality, and security details live in:

- `docs/FOUNDATIONS.md`
- `docs/QUALITY_SECURITY.md`
- `docs/PLAN.md`

Load those docs only when the task requires them. Do not create extra feature
docs unless explicitly requested.

## Project Invariants

- Rails monolith with Hotwire, ERB, Tailwind, PostgreSQL/PostGIS, RSpec, Pundit,
  Active Storage, I18n (`ru`/`en`), and `yabi`.
- MVP user-facing behavior is waterfall-first.
- Controllers stay thin.
- Models keep persistence and local invariants only.
- Business use cases go in `app/interactors` and use the project canonical
  `yabi` style.
- Authorization is explicit for every user-owned resource.
- User-facing text must have both `ru` and `en` locale entries.
- `db/structure.sql` is generated only; never edit it by hand.
- Keep `CHANGES.md` current for behavior, schema, dependency, process, or
  user-facing changes.

## Task Router

Before editing, classify the task and load only the needed context.

| Task type | Read first | Required workflow |
| --- | --- | --- |
| Product or scope decision | `docs/FOUNDATIONS.md`, `docs/PLAN.md` | Explain tradeoff before editing |
| Behavior change | Relevant app and spec files | Red test, minimal code, green test |
| UI-only visual polish | Existing views, styles, and components | Test only changed behavior/state |
| Interactor or business logic | Existing interactors and specs | Red interactor/request spec first |
| Authorization, admin, or user-owned resource | Existing policies/specs, `docs/QUALITY_SECURITY.md` | Policy coverage required |
| Migration, schema, or PostGIS | Existing migrations, `docs/FOUNDATIONS.md` | Explicit `up`/`down`; generated `structure.sql` only |
| Security, auth, uploads, or sessions | `docs/QUALITY_SECURITY.md` | Security-first review and tests |
| Dependency or tooling | `Gemfile`, lockfiles, `Makefile` | Explain tradeoff and run relevant gates |

If classification is unclear, inspect files first. Ask only when a wrong
assumption would create product, security, data, or schema risk.

## Execution Loop

For behavior-changing work:

1. Inspect relevant files and existing patterns.
2. Write or update the failing spec first.
3. Run the narrowest relevant spec and confirm it fails for the expected reason.
4. Make the smallest production change.
5. Run the narrow spec until green.
6. Run the relevant quality gate.
7. Update `CHANGES.md` when required.
8. Summarize changed files and verification.

If production behavior changes before a red test, stop and correct the process
by adding or reworking the test.

## Commands

Prefer `Makefile` targets:

- Setup: `make setup`
- App up: `make up`
- Doctor: `make doctor`
- Tests: `make test`
- Lint with autocorrect: `make lint`
- RuboCop only: `make rubocop`
- Security: `make security`
- Fast verification: `make verify-fast`
- Full verification: `make verify`
- Migration: `make migration NAME=MigrationName`
- Dependency freshness: `make outdated`

Use narrower `docker compose run --rm web ...` commands only when faster
feedback is needed.

## Permissions

Allowed without asking:

- Read files and search with `rg`.
- Edit files inside this repository for the active task.
- Run non-destructive tests, linters, security checks, and Rails generators.
- Update generated schema artifacts only through Rails tasks or migrations.

Ask first:

- Add a gem, package, external service, or runtime dependency.
- Introduce a new architectural pattern.
- Add triggers, stored procedures, or non-obvious database constraints.
- Create broad abstractions for future non-waterfall spot types.
- Change authentication, authorization, session, cookie, upload, or secret
  handling.
- Run destructive cleanup commands.
- Push, publish, or open a PR unless explicitly requested.

Forbidden:

- Push to `main`.
- Edit `db/structure.sql` by hand.
- Store or log secrets, credentials, passwords, reset tokens, signed blob
  tokens, or raw credentials.
- Disable CSRF.
- Skip authorization on user-owned resources.
- Mock app internals without a concrete reason.
- Add docs outside canonical docs unless explicitly requested.
- Build AI, offline-first, native mobile, or real-time MVP features without
  explicit approval.

## Database Rules

- Use explicit `up` and `down` migrations.
- Prefer SQL-forward Rails migrations.
- Default to `NOT NULL`, foreign keys, and justified indexes.
- Match foreign key types to referenced primary keys.
- Prefer PostgreSQL `uuidv7()` UUID primary keys for main domain tables.
- Use PostGIS-backed queries for location behavior.
- Use `CHECK` only for true storage-level invariants.

## Done Criteria

A task is done only when:

- Required specs pass.
- Relevant lint/security gates pass or failures are explained.
- Authorization and i18n were handled where applicable.
- No obvious N+1 was introduced in changed areas.
- `CHANGES.md` was updated when required.
- Final response lists changed files and commands run.
