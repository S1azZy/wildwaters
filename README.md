# Wild Waters

[![CI](https://img.shields.io/github/actions/workflow/status/S1azZy/wildwaters/ci.yml?branch=main&style=for-the-badge&label=CI)](https://github.com/S1azZy/wildwaters/actions/workflows/ci.yml)
![Coverage](https://img.shields.io/badge/Coverage-SimpleCov-0ea5e9?style=for-the-badge)
![Ruby](https://img.shields.io/badge/Ruby-3.4.4-cc342d?style=for-the-badge&logo=ruby&logoColor=white)
![Rails](https://img.shields.io/badge/Rails-8.1.x-d30001?style=for-the-badge&logo=rubyonrails&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-18-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![PostGIS](https://img.shields.io/badge/PostGIS-enabled-2f855a?style=for-the-badge)
![Hotwire](https://img.shields.io/badge/Hotwire-Turbo%20%2B%20Stimulus-ef4444?style=for-the-badge)
![Tailwind CSS](https://img.shields.io/badge/Tailwind_CSS-4.x-06b6d4?style=for-the-badge&logo=tailwindcss&logoColor=white)
![Docker](https://img.shields.io/badge/Docker-ready-2496ed?style=for-the-badge&logo=docker&logoColor=white)

Wild Waters is a Rails monolith for discovering natural water places, starting with waterfalls.

Product:
- name: `Wild Waters`
- tagline: `Swim the World`
- current focus: waterfall-first MVP
- architecture direction: extensible `Spot` root model without turning MVP into a generic outdoor platform

## Documentation

- Foundations: [`docs/FOUNDATIONS.md`](/Users/a.tselovalnikov/projects/wildwaters/docs/FOUNDATIONS.md)
- Delivery plan: [`docs/PLAN.md`](/Users/a.tselovalnikov/projects/wildwaters/docs/PLAN.md)
- Quality and security: [`docs/QUALITY_SECURITY.md`](/Users/a.tselovalnikov/projects/wildwaters/docs/QUALITY_SECURITY.md)
- Changes log: [`CHANGES.md`](/Users/a.tselovalnikov/projects/wildwaters/CHANGES.md)

## Stack

- Ruby `3.4.4`
- Rails `8.1.x`
- PostgreSQL `18` + PostGIS
- Hotwire (`Turbo + Stimulus`)
- Tailwind CSS
- Active Storage
- Active Job + Solid Queue
- Docker + docker-compose
- Kamal

## Current bootstrap state

This repository currently contains:
- product and architecture documentation
- a fresh Rails application skeleton
- a resolved Ruby bundle with `Gemfile.lock`
- Docker and local developer workflow scaffolding

It intentionally does not yet contain:
- business/domain code
- app-specific models, policies, services, or API resources

## Local bootstrap

1. Ensure Ruby `3.4.4` is available via `asdf`.
2. Run `bundle install`.
3. Start PostgreSQL/PostGIS with `docker compose up -d db`.
4. Create and prepare the database with `bin/rails db:prepare`.
5. Run the app with `bin/dev` or `docker compose up web`.

## Common commands

- `make setup` — build and start the local stack in Docker
- `make install-hooks` — enable the repository pre-commit hook
- `make doctor` — check local toolchain versions
- `make bundle` — install gems
- `make up` — start local containers in the foreground
- `make down` — stop local containers
- `make logs` — view web container logs
- `make bash` — shell into the web container
- `make shell` — open Rails console in the web container
- `make lint` — run RuboCop with autocorrect inside the app container
- `make test` — run test suite
- `make security` — run `bundler-audit` and `brakeman`
- `make verify-fast` — quick local verification
- `make verify` — fuller local verification
- `make ci` — run the full CI entrypoint locally in the app container
- `make migration NAME=CreateUsers` — generate a migration skeleton

## Notes

- The app is configured for PostgreSQL/PostGIS from the start.
- Local Docker and CI use `postgis/postgis`, which is based on the official `postgres` image and preinstalls the required PostGIS extensions.
- For PostgreSQL `18`, the container volume path is `/var/lib/postgresql`, not the older `/var/lib/postgresql/data`.
- MVP behavior remains waterfall-only even though the domain will later expand through `Spot`.
- Phase sequencing is defined in [`docs/PLAN.md`](/Users/a.tselovalnikov/projects/wildwaters/docs/PLAN.md).
