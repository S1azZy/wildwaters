# Changes

## 2026-06-14
- Accepted ADR 0005 and proposed the `frontend-foundation` OpenSpec change for
  a route-by-route migration of the application-owned business frontend to
  Vite, Inertia Rails, React, strict TypeScript, and Vite-owned Tailwind, while
  preserving the current design and deferring SSR and UI-kit adoption.
- Refreshed project dependencies by updating `shoulda-matchers` to `8.0.1`, Ruby to `4.0.5`, and RubyGems/Bundler to `4.0.14`; aligned the production build with Bundler's version-file lookup; and confirmed Node `24.16.0`, OpenSpec `1.4.1`, MapLibre GL JS `5.24.0`, PostgreSQL 18/PostGIS 3.6, Importmap pins, and the remaining Bundler set are current.

## 2026-06-13
- Split the OpenSpec baseline tooling assertions to satisfy the project RSpec lint limits and updated Brakeman to `8.0.5` so the enforced latest-version security gate remains green.
- Reconstructed the OpenSpec baseline from current code and RSpec across authentication, password reset, waterfall discovery, region and spot domains, GeoNames imports, admin job operations, and the shared design-system shell.
- Rewrote ADR 0001-0004 as records of implemented architecture, preserving durable stack choices, design-system foundations, data contracts, and execution boundaries while removing rollout plans and future requirements.
- Added a prioritized `docs/TODO.md` for unimplemented contract gaps, product layers, import operations, enrichment, and scale work.
- Updated the documentation ownership model, legacy OpenSpec policy, harness checks, and README, including the current GeoNames environment variable names.

## 2026-06-12
- Added a project-scoped OpenSpec workflow over the existing Codex harness, with native asdf-managed Node, pinned tooling, generated OpenSpec skills, strict validation, and a Wild Waters orchestration skill.
- Defined direct, specified-feature, and architectural-feature task levels with discovery, approval, specification revision, verification, archive, and focused ADR promotion rules.

## 2026-05-17
- Added project-local Codex skills for Wild Waters yabi interactors, auth/security flows, PostGIS discovery queries, GeoNames imports, and waterfall UI work so agents can load focused workflow guidance only when needed.
- Refreshed the current actionable dependency freshness set by updating Bundler-resolved gems including `bootsnap`, `dry-configurable`, `jbuilder`, `puma`, `selenium-webdriver`, `tailwindcss-ruby`, and `view_component`.
- Tightened `make outdated` to use Bundler's strict mode so the freshness gate tracks updateable dependencies within current constraints and does not fail on upstream-blocked transitive releases such as `diff-lcs` `2.0.0`.
- Clarified the development workflow so PR tasks start from a `codex/` branch in the current checkout unless the user explicitly asks for a separate worktree.
- Streamlined `AGENTS.md` into a concise Codex operating contract with task routing, execution flow, command references, permission boundaries, database rules, and explicit done criteria.
- Split agent workflow, command selection, permission boundaries, and verification matrices into `docs/DEVELOPMENT.md`; clarified ownership across the documentation set and removed stale README duplication.
- Refocused `docs/FOUNDATIONS.md` on durable product, architecture, domain, data, and database boundaries by removing startup-era roadmap, suggested-schema, and stack/tooling duplication.
- Removed the stale `docs/PLAN.md`, added task-packet and harness-regression guidance to `docs/DEVELOPMENT.md`, and reshaped `docs/QUALITY_SECURITY.md` around a security risk matrix.
- Added `docs/CONTEXT_MAP.md` as the source of truth for task-specific context loading so Codex can avoid broad repository scans.

## 2026-04-24
- Added a working Dev Container setup for agent-driven development with the existing Rails/PostGIS compose stack, mounted local Codex/GitHub/SSH authentication, project-scoped autonomous Codex sandbox settings, and a separate agent-oriented devcontainer image while keeping the regular development image minimal.
- Implemented ADR 0004 GeoNames queued import orchestration with `import_run_items`, run parameter snapshots, per-country Active Job execution, item finalization, partial-failure run status, failed-item retry, country-scoped missing-upstream reconciliation, and `make import_geonames` / retry entrypoints.
- Removed the legacy synchronous GeoNames import rake tasks and `Imports::RunSourceJob` so GeoNames region imports use only the queued orchestration flow.
- Reworked GeoNames run-item processing into a flat use-case orchestrator backed by focused download, dataset-build, dataset-apply, and missing-upstream reconciliation interactors.
- Removed the GeoNames `app/lib` layer by moving dump download/build logic and dataset normalization into the import interactors that own those steps.
- Added explicit dry-configurable/dotenv application configuration with typed `BootConfig` and `ApplicationConfig`, centralized ENV loading, example env files, and GeoNames import defaults backed by the new config layer.
- Added ADR 0004 to define the target GeoNames queued import orchestration with `import_run_items`, environment-backed defaults, run parameter snapshots, per-country Solid Queue jobs, partial retry, and country-scoped reconciliation.
- Refreshed the current dependency freshness set by vendoring `MapLibre GL JS/CSS` `5.24.0`.

## 2026-04-04
- Added the default Solid Queue operations stack: `mission_control-jobs` mounted behind admin-only app auth at `/admin/jobs`, dedicated queue database wiring for development/test/production, generated queue runtime config, and a separate Docker `jobs` service for local workers/scheduler checks.
- Removed default demo seeding from `db:prepare`, emptied `db/seeds.rb`, and made GeoNames import the only documented path for loading region data into a fresh environment.
- Fixed CI eager-load boot failures by disabling autoload-path insertion into `$LOAD_PATH` and by aligning the GeoNames import support files with Zeitwerk's `Imports::GeoNames` naming so system and bin specs load correctly under `CI=1`.
- Completed the GeoNames region import slice from ADR 0003 by reconciling omitted records as `missing_upstream` on repeated full/replay runs while preserving matched `Region` rows and provenance links, and by persisting accurate per-run stats on import failures.
- Added official GeoNames Andorra fixtures under `spec/fixtures/imports/geonames/` and extended the import/builder specs to exercise the real upstream dump format, multilingual alternate names, parent-first hierarchy import, and repeatable reruns.
- Added a primary network-loading path for GeoNames region imports: the app can now download official country dumps and country-scoped alternate names from GeoNames, prepare local artifacts under `tmp/imports/geonames/`, upsert the source config, and run the existing import pipeline through a dedicated rake task.
- Narrowed the default GeoNames MVP import slice to `PCLI + ADM1 + PPLA/PPLC` so the region graph stays product-oriented and avoids loading deeper admin levels and generic settlements by default.

## 2026-03-31
- Implemented ADR 0003 stage 1 backend import flow with `Imports` models, a GeoNames region connector, canonical region dataset/application interactors, evolved `Region` and `Regions::CreateRegion` for `region_kind`, `country_code`, `center`, and `region_names`, and seed ingestion that now bootstraps demo regions through the import pipeline.
- Added a real GeoNames dump path for stage 1 via extracted `allCountries` and optional `alternateNamesV2` files, plus a rake task to upsert source config and run a country-scoped region import from local dump files.

## 2026-03-28
- Refined ADR 0003 before merge by making `regions` product-oriented with `region_kind`, keeping exact admin levels in import normalization only, clarifying `region_names` as names/aliases rather than generic translations, tightening import-run/link invariants, and adding explicit guidance for reparenting, missing-upstream records, and a more conservative MVP rollout.
- Added ADR 0003 to define a dedicated import subsystem with source provenance, licensing metadata, async run tracking, domain-specific region linking, multilingual `region_names`, and a balanced MVP region ingestion strategy centered on GeoNames with geoBoundaries and Wikidata enrichment.

## 2026-03-27
- Simplified the shared header navigation to keep only Explore on the left, retained the authenticated Profile action on the right, removed the waterfall card `Map + list` label, and dropped the placeholder auth footer from the shared auth shell.
- Changed successful sign-ins to return users to the public homepage instead of the dashboard while preserving existing sign-out and auth-required flows.
- Refreshed the current outdated set again by moving Rails to `8.1.3`, updating `action_text-trix`, `ffi`, `json`, `parser`, and `thruster`, and vendoring `MapLibre GL JS/CSS` `5.21.1`.
- Redesigned only the sign-in and sign-up pages into a shared premium auth shell with calm full-page gradients, a floating card treatment, localized alternate auth links, and a small placeholder author footer while preserving the existing routes and auth behavior.
- Suppressed resize-induced `moveend` reloads when opening or closing the explore rail so the waterfall cards no longer flicker from an unnecessary list re-render.
- Removed transient explore-map refresh/status UI so the map and results rail no longer flash short-lived messages or end labels during routine list updates.
- Tightened the waterfall explore results rail into a viewport-bounded panel with a compact count summary, a dedicated scrolling list region, and a visible end-of-list marker while keeping the existing collapse/expand behavior.

## 2026-03-24
- Slimmed the explore filter bar by removing its extra frame chrome, moved the map-style control into the on-map toolbar beside zoom controls, and removed the standalone refresh button from the desktop explore controls.
- Reworked the explore screen into an AllTrails-style map-first layout with a dedicated single-band filter bar under the shared header, a collapsible de-emphasized results rail, and CSP-enabled Google font loading for the intended typography.
- Refined the project process rule so mandatory red-green TDD now applies to behavior-changing work, while purely visual UI polish no longer requires artificial failing tests.
- Refreshed the outdated dependency set by moving Rails to `8.1.2.1`, updating `net-ssh`, `nokogiri`, `rubocop`, and `solid_queue`, and vendoring `MapLibre GL JS` `5.21.0` to keep `make outdated` aligned with current safe versions.

## 2026-03-23
- Reworked the public explore homepage into a full-bleed map surface under the shared header, moving the filters into floating map overlays and turning the waterfall list into a floating results rail while preserving existing map/list synchronization.

## 2026-03-22
- Refined the shared site header into a calmer, more mature product shell with a dedicated primary nav, utility action cluster, and improved mobile row while keeping the current route structure intact.
- Completed design-system Phase 2 with shared `Ui::BadgeComponent`, `Ui::CardComponent`, `Ui::EmptyStateComponent`, `Ui::FilterChipComponent`, `Ui::FlashComponent`, `Ui::IconButtonComponent`, `Ui::SelectFieldComponent`, and `Ui::TextFieldComponent`, including the supporting token/CSS layer, field initializer compatibility fixes, accessible flash live-region behavior, and layout-level shared flash rendering.
- Normalized the Bundler lockfile platform list to stable names and pinned Bundler to the repository Ruby version via `.ruby-version` so routine `bundle install` runs stop churning `Gemfile.lock`.
- Added ADR 0002 to fix Wild Waters' design-system direction around the `Digital Naturalist` visual north star, shared design tokens, and a `ViewComponent`-based shared UI layer.
- Started design-system Phase 1 by adopting `ViewComponent`, adding component test support, and introducing the first shared UI class layer with `ApplicationComponent`, `Ui::ButtonComponent`, and `Ui::SiteHeaderComponent`.

## 2026-03-20
- Added a dedicated `bin/check-outdated` runner so `make outdated` always executes Bundler, importmap, and MapLibre freshness checks before returning one combined status code.
- Added dependency freshness checks for `bundle outdated`, `bin/importmap outdated`, and a new local `bin/check-maplibre-gl` script, plus a single `make outdated` aggregator target.
- Added an explore map-style dropdown with four detailed basemaps, including an outdoors-oriented style, and switched the map stack from a simple demo style to a richer multi-style setup.
- Fixed the explore homepage backend contract so the view receives an explicit default basemap id from the controller.
- Added a server-provided MapLibre basemap catalog for Liberty, Bright, and Positron styles and repointed explore CSP allowances from the old demo tile host to OpenFreeMap.
- Vendored MapLibre GL JS/CSS `5.21.0` into local Rails assets, pinned the JS in importmap, switched the explore map Stimulus controller to a module import, and removed the waterfall index CDN tags while keeping the remote demo style URL.

## 2026-03-19
- Added a compact ADR documenting the map browse stack decision: `MapLibre GL JS`, map-first layout, bounds-based loading, clustering, and a future path to vector tiles or PMTiles.
- Updated all bundle dependencies that could be safely advanced from `bundle outdated` and cleaned up deprecated Bundler platform declarations in `Gemfile`.
- Promoted the project runtime baseline to Ruby `4.0.2` after verifying the app, Docker image, and full RSpec suite on the stable Ruby 4 release.
- Reworked the public homepage into a map-first waterfall explore screen with MapLibre, interactor-backed MVP filters, a bounds-based `map_data` endpoint, and no-JavaScript request coverage.
- Hardened waterfall explore backend handling so empty catalog filters stay valid while `map_data` requests still reject missing bounds.
- Updated explore request/interactor/system specs so they stay deterministic even when demo seed waterfalls exist in the test catalog.
- Reworked the shared site header toward the new design direction with a single-row product nav, calmer typography, and a compact desktop action cluster that matches the explore reference more closely.

## 2026-03-15
- Simplified the README badges to keep only CI status and coverage, and switched CI to the native GitHub Actions badge.
- Added the first public waterfall catalog with a published-only index, detail pages resolved by `public_id + slug`, and demo seed data for local product walkthroughs.

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
- Added Region Foundation with hierarchical `regions`, closure-table traversal, and an ingestion-friendly `Regions::CreateRegion` interactor.
- Added Spot Domain Foundation with `spots`, `waterfalls`, and a transactional `Spots::CreateWaterfall` interactor built on top of existing regions.
