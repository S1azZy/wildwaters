SHELL := /bin/bash

COMPOSE := docker compose
APP := $(COMPOSE) run --rm web

.PHONY: setup openspec-install openspec-update openspec-validate install-hooks up down logs shell bash bundle lint rubocop rubocop-autocorrect erb-lint test security verify verify-fast ci migration doctor import_geonames import_geonames_retry_failed bundle-outdated importmap-outdated maplibre-outdated outdated

setup: openspec-install
	$(COMPOSE) up --build -d

openspec-install:
	bin/npm ci

openspec-update:
	bin/openspec update --force

openspec-validate:
	bin/openspec validate --all --strict

install-hooks:
	git config core.hooksPath .githooks

up:
	$(COMPOSE) up --build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f web

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

test:
	$(APP) bash -lc "RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bin/rails tailwindcss:build && RAILS_ENV=test bundle exec rspec"

security:
	$(APP) bash -lc "bin/bundler-audit && bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

verify: openspec-validate
	$(APP) bash -lc "bin/rubocop -A && bin/erb_lint --lint-all && RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bin/rails tailwindcss:build && RAILS_ENV=test bundle exec rspec && bin/bundler-audit && bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"

verify-fast:
	$(APP) bash -lc "bin/rubocop -A && bin/erb_lint --lint-all && RAILS_ENV=test bin/rails db:prepare && RAILS_ENV=test bin/rails tailwindcss:build && RAILS_ENV=test bundle exec rspec"

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

importmap-outdated:
	$(APP) bin/importmap outdated

maplibre-outdated:
	$(APP) bin/check-maplibre-gl

outdated:
	$(APP) bin/check-outdated
