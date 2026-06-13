# Wild Waters

<a href="https://github.com/s1azzy-dev/wildwaters/actions/workflows/ci.yml"><img alt="CI" src="https://github.com/s1azzy-dev/wildwaters/actions/workflows/ci.yml/badge.svg?branch=main" height="28"></a>
<img alt="Coverage" src="https://img.shields.io/badge/Coverage-SimpleCov-0ea5e9?style=for-the-badge" height="28">

Wild Waters is a Rails monolith for discovering natural water places, starting
with waterfalls.

## Documentation Map

| Need | Read |
| --- | --- |
| Context loading by task area | [`docs/CONTEXT_MAP.md`](docs/CONTEXT_MAP.md) |
| Agent workflow, commands, permissions, verification | [`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md) |
| Product scope, architecture, domain, database, PostGIS | [`docs/FOUNDATIONS.md`](docs/FOUNDATIONS.md) |
| Security, testing policy, CI and merge gates | [`docs/QUALITY_SECURITY.md`](docs/QUALITY_SECURITY.md) |
| Current feature specifications and active changes | [`openspec/`](openspec/) |
| Prioritized unimplemented work | [`docs/TODO.md`](docs/TODO.md) |
| Architecture decisions | [`docs/adr/`](docs/adr/) |
| Change history | [`CHANGES.md`](CHANGES.md) |

## Local Bootstrap

Prefer the Makefile workflow documented in
[`docs/DEVELOPMENT.md`](docs/DEVELOPMENT.md).

```bash
make setup
make doctor
make verify-fast
```

Useful local targets:

- `make up` - start local containers in the foreground
- `make down` - stop local containers
- `make logs` - view web container logs
- `make bash` - shell into the web container
- `make shell` - open Rails console in the web container
- `make lint` - run RuboCop with autocorrect and ERB lint
- `make test` - run the full test suite
- `make security` - run bundler-audit and Brakeman
- `make verify` - run the full local verification gate

## Spec-Driven Changes

Use `$wildwaters-spec-driven-change` to choose the workflow:

| Level | Typical work | Artifacts |
| --- | --- | --- |
| 1 | Copy, visual polish, narrow bug or refactor | None; use the normal project loop |
| 2 | Meaningful feature or uncertain behavior | OpenSpec proposal, specs, design, and tasks |
| 3 | Durable cross-cutting architecture change | Level 2 plus a focused ADR |

Level 2 and 3 flow:

```text
explore -> confirm -> propose -> review -> apply -> verify -> archive
```

OpenSpec records current observable behavior and pending behavior changes. The
baseline under `openspec/specs/` was reconstructed from the implemented code and
RSpec suite on 2026-06-13. ADRs record durable technology choices, system
boundaries, execution and persistence models, and design-system foundations.
Future work that has not become a change lives in `docs/TODO.md`.

If an omitted historical behavior is discovered later, the baseline may be
corrected directly only when no code behavior changes and existing RSpec proves
the contract. New or changed behavior always uses the Level 2 or 3 delta flow.
RSpec, project skills, permissions, and Make verification remain implementation
proof.

```bash
bin/openspec list
bin/openspec list --specs
make openspec-validate
make openspec-update
```

## GeoNames Import

The recommended operator flow enqueues one GeoNames import run with one queued
item per country:

```bash
GEONAMES_COUNTRY_CODES=AD GEONAMES_LANGUAGES=en,ru make import_geonames
```

Retry failed country items for an existing run:

```bash
make import_geonames_retry_failed RUN_ID=123
```

`bin/rails db:prepare` only prepares the schema. It does not load demo seeds.

Default MVP import slice:

- `PCLI` - country
- `ADM1` - first-level administrative areas
- `PPLA` and `PPLC` - administrative seats and capitals

If you need a wider slice for a one-off import, override
`GEONAMES_FEATURE_CODES`.

Useful environment variables:

- `GEONAMES_COUNTRY_CODES=AD,FR` - ISO country codes to import
- `GEONAMES_LANGUAGES=en,ru` - alternate-name languages to keep
- `GEONAMES_SOURCE_KEY=geonames_regions` - existing import source key
- `GEONAMES_FEATURE_CODES=PCLI,ADM1` - GeoNames feature codes to include
- `GEONAMES_DOWNLOAD_DIR=tmp/imports/geonames/custom` - artifact root
- `GEONAMES_DOWNLOAD_ALTERNATE_NAMES=0` - skip alternate names download
- `GEONAMES_DEFAULT_MODE=full` - run mode

The rake task name supplies the run's `initiated_by` audit label.

## Notes

- The app is configured for PostgreSQL/PostGIS from the start.
- Local Docker and CI use `postgis/postgis`, based on the official `postgres`
  image with PostGIS extensions installed.
- For PostgreSQL 18, the container volume path is `/var/lib/postgresql`, not the
  older `/var/lib/postgresql/data`.
- MVP behavior remains waterfall-only even though the domain expands through
  `Spot`.
