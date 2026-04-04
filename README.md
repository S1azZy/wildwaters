# Wild Waters

<a href="https://github.com/s1azzy-dev/wildwaters/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/s1azzy-dev/wildwaters/actions/workflows/ci.yml/badge.svg?branch=main" height="28"></a>
<img alt="Coverage" src="https://img.shields.io/badge/Coverage-SimpleCov-0ea5e9?style=for-the-badge" height="28">

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

- Ruby `4.0.2`
- Rails `8.1.x`
- PostgreSQL `18` + PostGIS
- Hotwire (`Turbo + Stimulus`)
- Tailwind CSS
- ERB views
- `yabi` interactors
- Pundit
- I18n (`ru` / `en`)
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

1. Ensure Ruby `4.0.2` is available via `asdf`.
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

## GeoNames Import

The repository supports two GeoNames region import paths:

- local-file mode with extracted dump files you already have
- network mode that downloads official GeoNames country dumps, prepares local artifacts, and runs the existing import pipeline

Recommended operator flow for the first real import:

```bash
docker compose exec web bash -lc \
  "COUNTRY_CODES=AD \
   LANGUAGES=en,ru \
   INITIATED_BY=manual \
   bundle exec rake imports:geonames:regions_from_network"
```

What the command does:

- downloads official GeoNames country dumps for the requested ISO country codes
- downloads country-scoped alternate names unless `DOWNLOAD_ALTERNATE_NAMES=0`
- writes prepared artifacts under `tmp/imports/geonames/<source_key>/`
- upserts the `geonames_regions` source config
- runs the existing region import into PostgreSQL

Useful environment variables:

- `COUNTRY_CODES=AD,FR` — required ISO country codes to import
- `LANGUAGES=en,ru` — alternate-name languages to keep during import
- `SOURCE_KEY=geonames_regions` — import source key
- `DOWNLOAD_DIR=tmp/imports/geonames/custom` — where prepared dump artifacts should be stored
- `DOWNLOAD_ALTERNATE_NAMES=0` — skip alternate names download if you only need the base dump
- `MODE=full` — import mode passed into `import_runs`
- `INITIATED_BY=manual` — audit label for the run

If you already have extracted files locally, keep using the existing task:

```bash
docker compose exec web bash -lc \
  "COUNTRY_CODES=AD \
   ALL_COUNTRIES_PATH=tmp/imports/geonames/geonames_regions/all_countries.txt \
   ALTERNATE_NAMES_PATH=tmp/imports/geonames/geonames_regions/alternate_names.txt \
   bundle exec rake imports:geonames:regions"
```

## Notes

- The app is configured for PostgreSQL/PostGIS from the start.
- User-facing and primary domain tables should prefer PostgreSQL `uuidv7()` primary keys; internal tables may use `bigint` where simpler.
- Local Docker and CI use `postgis/postgis`, which is based on the official `postgres` image and preinstalls the required PostGIS extensions.
- For PostgreSQL `18`, the container volume path is `/var/lib/postgresql`, not the older `/var/lib/postgresql/data`.
- MVP behavior remains waterfall-only even though the domain will later expand through `Spot`.
- Phase sequencing is defined in [`docs/PLAN.md`](/Users/a.tselovalnikov/projects/wildwaters/docs/PLAN.md).
