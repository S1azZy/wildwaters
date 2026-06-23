## 1. Retirement Proof

- [x] 1.1 Update frontend tooling specs to assert the retired Importmap,
  Turbo, Stimulus, ViewComponent, legacy layout, and component surfaces are
  absent.
- [x] 1.2 Run the narrow tooling spec and confirm it fails on the current legacy
  stack before implementation.

## 2. Legacy Stack Removal

- [x] 2.1 Remove retired Importmap, Turbo, Stimulus, and ViewComponent gems,
  bin/config files, CI checks, source files, UI component files, and component
  specs.
- [x] 2.2 Refresh the bundle lockfile in the web container.
- [x] 2.3 Remove stale stylesheet source globs and update any request/system
  specs that still describe legacy-boundary navigation instead of document
  navigation.

## 3. Documentation And OpenSpec

- [x] 3.1 Update docs, ADR implementation notes, Context Map rows, and
  `CHANGES.md` to describe the completed Inertia business frontend boundary.
- [x] 3.2 Sync the completed frontend-platform delta spec into the baseline.

## 4. Verification

- [x] 4.1 Run `bin/openspec validate --all --strict`.
- [x] 4.2 Run the narrow tooling spec, frontend verification, and the applicable
  project gate from `docs/DEVELOPMENT.md`.
- [x] 4.3 Inspect the final diff for leftover retired stack references, archive
  `retire-legacy-frontend-stack`, and prepare the PR.
