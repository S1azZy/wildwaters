SHELL := /bin/bash

# Host-side commands orchestrate Docker, git hooks, and project-local OpenSpec
# wrappers. Rails, Ruby, frontend runtime, test, lint, audit, and dependency
# freshness commands run inside the web container through APP.
COMPOSE := docker compose
APP := $(COMPOSE) run --rm web

.PHONY: setup openspec-install openspec-update openspec-validate frontend-install frontend-format frontend-lint frontend-typecheck frontend-test frontend-build frontend-audit frontend-verify frontend-outdated install-hooks up down logs shell bash bundle lint rubocop rubocop-autocorrect erb-lint test security verify verify-fast ci migration doctor import_geonames import_geonames_retry_failed bundle-outdated maplibre-outdated outdated

setup: openspec-install
	$(COMPOSE) up --build -d

# Host OpenSpec wrapper targets.
openspec-install:
	bin/npm ci

openspec-update:
	bin/openspec update --force

openspec-validate:
	bin/openspec validate --all --strict

# Containerized frontend targets.
frontend-install:
	$(APP) bin/npm ci

frontend-format:
	$(APP) bin/npm run frontend:format

frontend-lint:
	$(APP) bin/npm run frontend:lint

frontend-typecheck:
	$(APP) bin/npm run frontend:typecheck

frontend-test:
	$(APP) bin/npm run frontend:test

frontend-build:
	$(APP) bin/npm run frontend:build

frontend-audit:
	$(APP) bin/npm run frontend:audit

frontend-verify:
	$(APP) bin/npm run frontend:verify

# Host Git and Docker orchestration targets.
install-hooks:
	git config core.hooksPath .githooks

up:
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f web

# Containerized app/runtime targets.
shell:
	$(APP) bin/rails console

bash:
	$(APP) bash

bundle:
	$(APP) bundle install

lint:
	$(APP) bash -lc "bin/rubocop -A && bin/erb_lint --lint-all"

rubocop:
	$(APP) bin/rubocop -A

rubocop-autocorrect:
	$(APP) bin/rubocop -A

erb-lint:
	$(APP) bin/erb_lint --lint-all

test: frontend-install
	$(APP) bash -lc "bin/npm run frontend:build:test && RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bundle exec rspec"

security:
	$(APP) bash -lc "bin/bundler-audit && bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

verify: openspec-validate frontend-install frontend-verify
	$(APP) bash -lc "bin/npm run frontend:build:test && bin/rubocop -A && bin/erb_lint --lint-all && RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bundle exec rspec && bin/bundler-audit && bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

verify-fast: frontend-install
	$(APP) bash -lc "bin/npm run frontend:format && bin/npm run frontend:lint && bin/npm run frontend:typecheck && bin/npm run frontend:test && bin/npm run frontend:build:test && bin/rubocop -A && bin/erb_lint --lint-all && RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bundle exec rspec"

ci:
	$(APP) bin/ci

migration:
ifndef NAME
	$(error NAME is required, for example: make migration NAME=CreateUsers)
endif
	$(APP) bin/rails generate migration $(NAME)

doctor:
	@bin/node --version
	@bin/npm --version
	@bin/openspec --version
	@docker compose version
	@docker info --format '{{.ServerVersion}}'
	$(APP) bash -lc "ruby -v && bundle -v && bin/rails about"

import_geonames:
	$(APP) bin/rails imports:geonames:enqueue

import_geonames_retry_failed:
ifndef RUN_ID
	$(error RUN_ID is required, for example: make import_geonames_retry_failed RUN_ID=123)
endif
	$(APP) bin/rails imports:geonames:retry_failed RUN_ID=$(RUN_ID)

bundle-outdated:
	$(APP) bundle outdated

frontend-outdated:
	$(APP) bin/npm outdated

maplibre-outdated:
	$(APP) bin/check-maplibre-gl

outdated:
	$(APP) bin/check-outdated
