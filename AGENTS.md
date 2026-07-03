# AGENTS.md

## Purpose

This is the always-loaded Codex control plane for Wild Waters. Keep it short.
Use it to choose the right source of truth, permission level, and verification
path. Do not duplicate detailed project rules here.

## Source Map

| Need | Read |
| --- | --- |
| Context loading by task area | `docs/CONTEXT_MAP.md` |
| Agent workflow, commands, permissions, verification | `docs/DEVELOPMENT.md` |
| Product scope, architecture, domain, database, PostGIS | `docs/FOUNDATIONS.md` |
| Security, testing policy, CI and merge gates | `docs/QUALITY_SECURITY.md` |
| Feature intent, acceptance behavior, active changes | `openspec/specs/`, `openspec/changes/` |
| Known unimplemented work | `docs/TODO.md` |
| Durable architecture decisions | `docs/adr/` |

Load only the documents needed for the active task. Do not create extra feature
docs unless explicitly requested.

## Always-On Rules

- Inspect neighboring files before editing and follow the local pattern.
- Read the related baseline spec before changing established behavior.
- Behavior-changing work uses red test, minimal code, green test.
- Keep MVP user-facing behavior waterfall-first.
- Put business use cases in `app/interactors` using the canonical `yabi` style.
- Require explicit authorization for every user-owned resource.
- Add `ru` and `en` locale entries for user-facing text.
- Never edit `db/structure.sql` by hand.
- Run app/runtime commands through Make/container targets; use the host shell
  only for file search, git inspection, editing, and documented host-only
  tooling.
- Prefer documented RTK-backed host commands and `make agent-*` targets when
  they preserve needed detail; use raw `rg`, `sed`, git, or Make commands when
  exact output matters.
- Keep `CHANGES.md` current for behavior, schema, dependency, process, or
  user-facing changes.

## Start Every Task

1. Classify the task type and SDD level with `docs/DEVELOPMENT.md`.
   This gate runs for every repository task unless the user explicitly opts out
   or narrows the request to a different workflow.
2. Load task-specific context from `docs/CONTEXT_MAP.md`.
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
