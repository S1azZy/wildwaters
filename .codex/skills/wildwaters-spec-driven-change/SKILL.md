---
name: wildwaters-spec-driven-change
description: Use when a Wild Waters request may need feature discovery, an OpenSpec change, or an ADR; when task size is uncertain; or when implementation learning may require revising an approved specification.
---

# Wild Waters Spec-Driven Change

## Purpose

Select the lightest correct workflow and keep OpenSpec on top of the existing
Wild Waters harness. Do not replace `AGENTS.md`, project docs, domain skills,
RSpec, or Make verification.

## Classify First

Read `AGENTS.md` and the classification rules in `docs/DEVELOPMENT.md`.

| Level | Use for | Workflow |
| --- | --- | --- |
| 1: Direct | Copy, visual polish, obvious narrow bugs, small contract-preserving refactors | Existing project loop only |
| 2: Specified feature | Meaningful behavior, interacting mechanisms, uncertain requirements, persistent acceptance criteria | Explore, approve, propose, apply, verify, archive |
| 3: Architectural feature | Level 2 plus a durable, cross-cutting, difficult-to-reverse decision | Level 2 plus ADR promotion |

State the selected level and reason. Level 1 creates no OpenSpec change and no
ADR.

## Discover Level 2 And 3 Work

1. Load only context selected by `docs/CONTEXT_MAP.md`, then inspect the relevant
   code and tests.
2. Run `bin/openspec list --json` to find related active changes.
3. Use `$openspec-explore` as the thinking stance.
4. Ask one focused question at a time. Do not create artifacts yet.
5. Challenge assumptions. Identify scope, non-goals, unknowns, and applicable
   data, authorization/privacy, migration, retry/idempotency, PostGIS/
   performance, operational, observability, and rollback risks.
6. Compare two or three credible approaches when the choice is non-obvious.
7. Summarize the recommended direction and ask the user to confirm it.

Do not invoke `$openspec-propose` until the user confirms the explored
direction.

## Create And Implement

After confirmation:

1. Invoke `$openspec-propose`. Use `bin/openspec` in place of bare `openspec` in
   every generated skill command.
2. Review proposal, specs, design, and tasks with the user before implementation.
3. For Level 3, create an ADR only for the confirmed durable architecture
   decision. Keep feature behavior and task detail in OpenSpec.
4. Invoke `$openspec-apply-change`.
5. Preserve the project permission matrix, domain skills, red/green loop, and
   verification matrix while applying tasks.

If implementation disproves an assumption, pause. Update the relevant proposal,
spec, design, or tasks and obtain approval for changed intent or architecture
before divergent implementation continues.

## Finish

Before archive:

1. Invoke `$openspec-verify-change`.
2. Run `bin/openspec validate --all --strict`.
3. Run the narrow specs and the applicable `docs/DEVELOPMENT.md` verification
   command.
4. Resolve critical mismatches, then invoke `$openspec-archive-change`.

Agentic verification informs judgment; only mechanical validation, tests, and
project gates provide blocking proof.
