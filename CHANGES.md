# Changes

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
