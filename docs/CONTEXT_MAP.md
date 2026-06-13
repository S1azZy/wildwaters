# Context Map

This document owns task-specific context loading for Codex. Its job is to help
the agent read the smallest useful file set before acting.

Use it after classifying the task with `docs/DEVELOPMENT.md`. Do not use it as a
substitute for inspecting neighboring files; local examples still win.

## Loading Rules

- Start from the relevant row below, not from a repository-wide scan.
- Read listed source-of-truth files first, then the directly relevant app/spec
  files, then neighboring examples.
- Prefer `rg` and targeted file reads over broad directory dumps.
- Read generated artifacts only when the task depends on their generated
  output.
- For Level 2 or 3 work, inspect related active changes before creating a new
  change and read current capability specs before changing existing behavior.
- Treat ADRs as implemented architecture decisions, not feature specifications.
- Use `docs/TODO.md` only when selecting or scoping unimplemented work.
- If a source still conflicts with established code and RSpec, treat the
  implementation as evidence and repair the owning document.
- If the mapped context is insufficient, expand one directory or pattern at a
  time and record what was added in the task packet.

## General Orientation

Read for broad orientation only when starting a new session, changing project
rules, or making cross-cutting decisions.

| Need | Read |
| --- | --- |
| Agent operating rules | `AGENTS.md`, `docs/DEVELOPMENT.md` |
| Product/domain/database boundaries | `docs/FOUNDATIONS.md` |
| Security/testing/merge gates | `docs/QUALITY_SECURITY.md` |
| Spec-driven task levels and lifecycle | `docs/DEVELOPMENT.md` |
| Current capability behavior | `openspec/specs/` |
| Active feature changes | `openspec/changes/`, `bin/openspec list --json` |
| Prioritized unimplemented work | `docs/TODO.md` |
| Human project entrypoint | `README.md` |
| Durable architecture decisions | `docs/adr/README.md`, then the specific ADR |
| Recent project changes | `CHANGES.md` |
| Commands | `Makefile` |
| Dependencies | `Gemfile`, `Gemfile.lock`, `config/importmap.rb` |
| Routes and entrypoints | `config/routes.rb` |

## Backend Context

| Task area | Start with | Then inspect |
| --- | --- | --- |
| Auth/session/password reset | `docs/QUALITY_SECURITY.md`, `config/routes.rb`, `app/controllers/concerns/authentication.rb` | `app/controllers/sessions_controller.rb`, `app/controllers/registrations_controller.rb`, `app/controllers/password_resets_controller.rb`, `app/interactors/auth/`, `app/models/user.rb`, `app/models/user_identity.rb`, `app/models/session.rb`, matching request/interactor/model specs |
| Admin/authorization | `docs/QUALITY_SECURITY.md`, `app/policies/application_policy.rb`, `app/controllers/admin/base_controller.rb` | Matching controller/request/policy specs and neighboring admin flows |
| Waterfall catalog/browse | `docs/FOUNDATIONS.md`, `config/routes.rb`, `app/controllers/waterfalls_controller.rb` | `app/interactors/waterfalls/`, `app/queries/waterfalls/`, `app/presenters/waterfalls/`, `app/models/spot.rb`, `app/models/waterfall.rb`, matching request/system/interactor specs |
| Regions | `docs/FOUNDATIONS.md`, `app/models/region.rb`, `app/models/region_closure.rb`, `app/models/region_name.rb` | `app/interactors/regions/`, region factories, region model/interactor specs, relevant migrations |
| Imports/GeoNames | `docs/FOUNDATIONS.md`, `docs/adr/0003-import-architecture-and-region-ingestion.md`, `docs/adr/0004-geonames-queued-import-orchestration.md` | `app/models/imports/`, `app/interactors/imports/`, `app/jobs/imports/`, import specs, import fixtures |
| Models/domain persistence | Relevant model and matching factory/spec | Neighboring models, relevant migrations, related interactors |
| Interactors/use cases | `app/interactors/application_interactor.rb`, relevant interactor | Matching interactor spec, neighboring interactor in same namespace, relevant contract/model |
| Queries/presenters | Relevant query/presenter | Matching spec, controller/view caller, neighboring query/presenter |
| Jobs/mailers | Relevant job/mailer | Matching specs, queue config, templates for mailers |
| Configuration | `config/configs/`, `config/initializers/01_settings.rb` | Matching config specs, environment files only when needed |
| Migrations/schema | Recent migrations in `db/migrate/`, `docs/FOUNDATIONS.md` | Relevant model/spec; `db/structure.sql` only for generated output inspection |

## Frontend Context

| Task area | Start with | Then inspect |
| --- | --- | --- |
| Layout/header/application shell | `app/views/layouts/application.html.erb`, `app/components/ui/site_header_component.*` | `spec/components/ui/site_header_component_spec.rb`, `spec/system/design_system_shell_spec.rb`, shared UI components |
| Auth screens | Relevant auth view in `app/views/sessions/`, `app/views/registrations/`, or `app/views/password_resets/` | `app/components/ui/auth_shell_component.*`, auth request/system specs, locale files |
| Waterfall pages | Relevant `app/views/waterfalls/` template | `app/controllers/waterfalls_controller.rb`, waterfall presenter/query, request/system specs |
| Explore map UI | `app/javascript/controllers/explore_map_controller.js`, `app/views/waterfalls/index.html.erb` | `app/presenters/waterfalls/map_style_catalog.rb`, MapLibre ADR, map system/request specs, local MapLibre assets |
| UI components | Relevant `app/components/ui/*` Ruby and ERB files | Matching component spec, neighboring component APIs, design-system ADR |
| Styles/design tokens | `app/assets/tailwind/design_tokens.css`, `app/assets/tailwind/application.css`, `app/assets/stylesheets/application.css` | Relevant component/view, component/system specs |
| Stimulus behavior | Relevant controller in `app/javascript/controllers/` | View markup that owns targets/actions, matching system spec |
| I18n copy | `config/locales/en.yml`, `config/locales/ru.yml` | View/component using the keys, request/system coverage when behavior changes |

## Test Context

| Test need | Read |
| --- | --- |
| Test framework setup | `spec/rails_helper.rb`, `spec/spec_helper.rb` |
| Factory style | Relevant `spec/factories/*`, neighboring factory |
| Request specs | Relevant file in `spec/requests/`, neighboring request spec |
| System specs | Relevant file in `spec/system/`, neighboring system spec |
| Interactor specs | Relevant file in `spec/interactors/`, neighboring namespace spec |
| Model specs | Relevant file in `spec/models/`, matching model/factory |
| Policy specs | `spec/support/pundit.rb`, relevant file in `spec/policies/` |
| Component specs | Relevant file in `spec/components/ui/`, component Ruby/ERB files |
| Job/mailer specs | Relevant file in `spec/jobs/` or `spec/mailers/` |
| Tooling/bin specs | Relevant file in `spec/bin/`, `spec/tooling/`, or `spec/lib/` |
| External fixtures | Relevant file in `spec/fixtures/` only when the spec uses it |

## Source of Truth

| Subject | Source of truth |
| --- | --- |
| Agent operating contract | `AGENTS.md` |
| Context loading | `docs/CONTEXT_MAP.md` |
| Workflow, permissions, verification | `docs/DEVELOPMENT.md` |
| Product, architecture, domain, database boundaries | `docs/FOUNDATIONS.md` |
| Security/testing/risk gates | `docs/QUALITY_SECURITY.md` |
| Current feature intent and observable behavior | `openspec/specs/` |
| Proposed feature changes, design, and tasks | `openspec/changes/` |
| Known unimplemented work | `docs/TODO.md` |
| Durable architecture decisions | `docs/adr/` |
| Routes | `config/routes.rb` |
| Commands | `Makefile` |
| Dependencies | `Gemfile`, `Gemfile.lock`, `config/importmap.rb` |
| Runtime configuration shape | `config/configs/`, `config/initializers/01_settings.rb` |
| Database schema state | Rails migrations and generated `db/structure.sql` |
| Queue schema state | Queue migrations and generated `db/queue_structure.sql` |
| I18n copy | `config/locales/en.yml`, `config/locales/ru.yml` |
| UI component API | Component Ruby file, template, and matching component spec |
| Current behavior | Relevant app code plus matching request/system/interactor/model spec |

## Updating This Map

Update `docs/CONTEXT_MAP.md` when:

- a new top-level app area, namespace, or repeated workflow is added;
- files are moved, renamed, or made canonical;
- a new ADR changes where agents should look first;
- a repeated Codex failure came from missing or excessive context;
- task routing in `docs/DEVELOPMENT.md` changes;
- README or source ownership changes affect human/agent entrypoints.

Update style:

- Prefer changing one row over adding broad instructions.
- Remove stale paths in the same edit that introduces new ones.
- Keep this file as an index, not a tutorial.
- Validate with `git diff --check` for docs-only updates.
