# AGENTS.md

## Purpose

This is the always-loaded Codex control plane for Wild Waters. Keep it short.
Use it to choose the right source of truth, permission level, and verification
path. Do not duplicate detailed project rules here.

## Source Map

| Need | Read |
| --- | --- |
| Agent workflow, commands, permissions, verification | `docs/DEVELOPMENT.md` |
| Product scope, architecture, domain, database, PostGIS | `docs/FOUNDATIONS.md` |
| Security, testing policy, CI and merge gates | `docs/QUALITY_SECURITY.md` |
| Historical decisions | `docs/adr/` |

Load only the documents needed for the active task. Do not create extra feature
docs unless explicitly requested.

## Always-On Rules

- Inspect neighboring files before editing and follow the local pattern.
- Behavior-changing work uses red test, minimal code, green test.
- Keep MVP user-facing behavior waterfall-first.
- Put business use cases in `app/interactors` using the canonical `yabi` style.
- Require explicit authorization for every user-owned resource.
- Add `ru` and `en` locale entries for user-facing text.
- Never edit `db/structure.sql` by hand.
- Keep `CHANGES.md` current for behavior, schema, dependency, process, or
  user-facing changes.

## Start Every Task

1. Classify the task with `docs/DEVELOPMENT.md`.
2. Read only the mapped docs and relevant neighboring files.
3. Identify whether the task changes behavior, schema, security, dependencies,
   or only documentation/style.
4. Follow the matching execution loop and verification matrix.
5. Stop and ask when the permission matrix says approval is required.

## Hard Stops

- Do not push to `main`.
- Do not store or log secrets, credentials, passwords, reset tokens, signed blob
  tokens, or raw credentials.
- Do not disable CSRF.
- Do not skip authorization on user-owned resources.
- Do not mock app internals without a concrete reason.
- Do not add gems, external services, new architecture patterns, triggers,
  stored procedures, or broad future-type abstractions without approval.
- Do not build AI, offline-first, native mobile, or real-time MVP features
  without explicit approval.

## Done

A task is done only after the applicable verification from
`docs/DEVELOPMENT.md` has passed or the remaining failure is clearly explained.
