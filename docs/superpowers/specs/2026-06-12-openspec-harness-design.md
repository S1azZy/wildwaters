# OpenSpec Harness Integration Design

## Goal

Add OpenSpec as a lightweight specification layer over the existing Wild Waters
Codex harness. OpenSpec owns feature intent, behavioral requirements, technical
design, and implementation tasks. Existing project documents, domain skills,
TDD rules, permissions, and verification commands remain authoritative.

## Decisions

- Pin Node.js `24.16.0` in `.tool-versions`.
- Install Node locally through `asdf`, in the devcontainer from the same pinned
  release, and in GitHub Actions through `actions/setup-node`.
- Do not add Node.js to the production image or the regular Rails development
  image.
- Pin `@fission-ai/openspec` `1.4.1` as a project-local development dependency.
- Run OpenSpec through `bin/openspec`, never through an assumed global install.
- Give OpenSpec a repository-scoped XDG config with:
  - `profile: custom`
  - `delivery: skills`
  - workflows: `explore`, `propose`, `apply`, `verify`, `sync`, `archive`
- Disable OpenSpec telemetry in the wrapper.
- Use the OpenSpec-provided Codex skills in `.codex/skills/openspec-*`.
- Add one project-owned orchestration skill for task-level selection, discovery
  quality, risk review, ADR promotion, and handoff back to the existing harness.
- Keep the built-in `spec-driven` schema. Customize it through
  `openspec/config.yaml` rules rather than forking a schema initially.

## Why A Wrapper Is Required

OpenSpec `1.4.1` stores workflow delivery in global user configuration and
defaults to `delivery: both`. For Codex, command delivery writes deprecated
prompt files into the user's global `$CODEX_HOME/prompts`.

`bin/openspec` will set a repository-scoped `XDG_CONFIG_HOME`, disable telemetry,
and execute the locked local package. This prevents global state changes and
makes OpenSpec behavior reproducible across the host, devcontainer, and CI.

## Ownership

| Concern | Owner |
| --- | --- |
| Always-loaded task routing and hard stops | `AGENTS.md` |
| Task levels, SDD lifecycle, permissions, verification | `docs/DEVELOPMENT.md` |
| Task-specific repository context | `docs/CONTEXT_MAP.md` |
| Product, domain, data, and architecture boundaries | `docs/FOUNDATIONS.md` |
| Security and test policy | `docs/QUALITY_SECURITY.md` |
| Feature intent and pending behavioral changes | `openspec/changes/` |
| Current specified behavior after archive | `openspec/specs/` |
| Durable cross-cutting architecture decisions | `docs/adr/` |
| Reusable SDD conversation workflow | project Codex skill |

OpenSpec artifacts may reference the harness but must not copy its detailed
rules. Current code and tests remain the final proof of implemented behavior.

## Three Task Levels

### Level 1: Direct

Use for copy changes, visual-only polish, narrow bugs with an obvious expected
result, and small refactors that do not alter a meaningful contract.

Flow:

```text
classify -> load mapped context -> existing TDD or docs loop -> verify
```

No OpenSpec change and no ADR.

### Level 2: Specified Feature

Use for new or changed user/system behavior, multiple interacting mechanisms,
uncertain requirements, or changes whose acceptance criteria should survive the
chat session.

Flow:

```text
explore -> user confirms direction -> propose -> review artifacts
-> apply in red/green increments -> update artifacts when learning changes intent
-> verify -> mechanical gates -> archive
```

No ADR unless a Level 3 decision emerges during discovery.

### Level 3: Architectural Feature

Use when Level 2 work also includes a cross-cutting, long-lived, difficult to
reverse decision involving domain boundaries, persistence strategy, security
model, external integration, or operational architecture.

Flow:

```text
Level 2 flow -> record the durable decision in ADR
-> keep feature behavior in OpenSpec -> implement -> verify -> archive
```

The ADR captures the selected architectural decision and trade-offs. OpenSpec
captures feature behavior, design details, scenarios, and tasks.

## Discovery Contract

For Level 2 and Level 3 work, the project orchestration skill must:

1. Read `AGENTS.md`, classify the task with `docs/DEVELOPMENT.md`, and load only
   context selected by `docs/CONTEXT_MAP.md`.
2. Inspect relevant code and tests before recommending a design.
3. Ask one focused question at a time.
4. Challenge assumptions and identify non-goals and unknowns.
5. Review applicable risks: data/schema, authorization/privacy, migration,
   retries/idempotency, performance/PostGIS, operations, and rollback.
6. Compare two or three credible approaches when the choice is non-obvious.
7. Create no OpenSpec change until the user confirms the explored direction.

## Artifact Rules

`proposal.md` must state:

- problem and expected outcome;
- task level;
- scope and non-goals;
- assumptions and open questions;
- affected behavior and capabilities;
- risks requiring special verification;
- whether an ADR is required.

Delta specs must:

- describe observable behavior rather than implementation steps;
- use requirements plus GIVEN/WHEN/THEN scenarios;
- include failure scenarios for expected errors, authorization scenarios for
  protected or user-owned resources, and retry scenarios for asynchronous or
  external operations;
- map cleanly to RSpec examples without requiring Cucumber.

`design.md` must:

- reference existing repository patterns and named source-of-truth documents;
- explain alternatives and trade-offs;
- cover data, security, migration, operation, rollback, and observability where
  applicable;
- state whether an ADR is created or intentionally unnecessary.

`tasks.md` must:

- use small red/green implementation increments;
- name relevant tests and verification commands;
- update OpenSpec artifacts before code when implementation learning changes
  the agreed behavior or design;
- include `CHANGES.md` and documentation updates when required.

## Verification

OpenSpec provides two different checks:

- `bin/openspec validate --all --strict` mechanically validates artifacts and is
  mandatory locally and in CI.
- The generated `openspec-verify-change` skill performs agentic comparison
  between artifacts and implementation. It is required before archive, but is
  not a substitute for tests or project verification.

The final gate for a Level 2 or Level 3 change is:

```text
OpenSpec agentic verify
-> bin/openspec validate --all --strict
-> applicable narrow specs
-> docs/DEVELOPMENT.md verification matrix
-> archive
```

## Documentation

- `docs/DEVELOPMENT.md` will own the detailed three-level workflow.
- `README.md` will contain only a compact quick-start table and command list.
- `AGENTS.md` and `docs/CONTEXT_MAP.md` will point to the owning documents and
  OpenSpec artifacts without duplicating the workflow.
- Existing ADRs remain historical records and require no migration.

## Alternatives Rejected

### Global OpenSpec Installation

Rejected because it does not pin the project version and makes local, container,
and CI behavior diverge.

### Docker-Only OpenSpec

Rejected because Codex App and CLI run on the host. Every OpenSpec operation
would require a container hop and interactive discovery would become slower and
more fragile.

### Default OpenSpec Delivery

Rejected because `delivery: both` writes global Codex prompt files. Wild Waters
needs repository-owned skills only.

### Forking The OpenSpec Schema Immediately

Rejected for now. Per-artifact project rules provide the required behavior with
less maintenance. Fork the schema only after real usage reveals a constraint
that configuration cannot express.
