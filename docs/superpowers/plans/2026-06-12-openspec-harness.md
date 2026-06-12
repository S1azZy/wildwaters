# OpenSpec Harness Integration Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a reproducible OpenSpec specification layer that uses the existing Wild Waters harness, supports three task levels, and validates specifications in CI.

**Architecture:** OpenSpec is a pinned project-local npm dependency executed through `bin/openspec`. Project-local Node/npm wrappers prefer the asdf version even when another Node appears earlier in the caller's PATH. The OpenSpec wrapper isolates global configuration into the repository, enables only selected skills, and disables telemetry. A project Codex skill chooses the task level and orchestrates discovery while `AGENTS.md`, existing docs, domain skills, RSpec, and Make verification remain authoritative.

**Tech Stack:** Node.js 24.16.0, npm, OpenSpec 1.4.1, Bash, Codex skills, RSpec, Make, GitHub Actions

---

### Task 1: Pin The Node And OpenSpec Toolchain

**Files:**
- Modify: `.tool-versions`
- Modify: `.gitignore`
- Create: `package.json`
- Create: `package-lock.json`
- Create: `spec/tooling/open_spec_configuration_spec.rb`

- [ ] **Step 1: Add the tooling expectation spec**

Create `spec/tooling/open_spec_configuration_spec.rb` with expectations that:

```ruby
# frozen_string_literal: true

require "json"
require "yaml"

RSpec.describe "OpenSpec configuration" do
  let(:root) { Pathname(__dir__).join("../..").expand_path }

  it "pins the shared Node and OpenSpec versions" do
    expect(root.join(".tool-versions").read).to include("nodejs 24.16.0")

    package = JSON.parse(root.join("package.json").read)
    expect(package.dig("engines", "node")).to eq("24.16.0")
    expect(package.dig("devDependencies", "@fission-ai/openspec")).to eq("1.4.1")
  end
end
```

- [ ] **Step 2: Run the narrow spec and confirm the expected failure**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null \
  spec/tooling/open_spec_configuration_spec.rb
```

Expected: failure because `package.json` does not exist and Node is not pinned.

- [ ] **Step 3: Pin Node and create the npm package**

Set `.tool-versions` to:

```text
ruby 4.0.3
nodejs 24.16.0
```

Add `/node_modules/` to `.gitignore`.

Create `package.json`:

```json
{
  "name": "wildwaters-tooling",
  "private": true,
  "engines": {
    "node": "24.16.0"
  },
  "scripts": {
    "openspec:validate": "bin/openspec validate --all --strict"
  },
  "devDependencies": {
    "@fission-ai/openspec": "1.4.1"
  }
}
```

- [ ] **Step 4: Install the pinned local Node release and dependency**

Run:

```bash
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git
asdf install nodejs 24.16.0
npm install --package-lock-only
npm ci
```

Expected: Node `24.16.0`, npm installation succeeds, and `package-lock.json` is
created without untracked dependency contents.

- [ ] **Step 5: Run the narrow spec**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null \
  spec/tooling/open_spec_configuration_spec.rb
```

Expected: pass.

### Task 2: Add A Project-Scoped OpenSpec Runner

**Files:**
- Create: `bin/node`
- Create: `bin/npm`
- Create: `bin/openspec`
- Create: `config/openspec/config.json`
- Modify: `spec/tooling/open_spec_configuration_spec.rb`

- [ ] **Step 1: Extend the tooling spec**

Add expectations that the wrapper:

```ruby
it "isolates OpenSpec configuration and disables telemetry" do
  runner = root.join("bin/openspec").read
  config = JSON.parse(root.join("config/openspec/config.json").read)

  expect(runner).to include('XDG_CONFIG_HOME="${ROOT_DIR}/config"')
  expect(runner).to include('OPENSPEC_TELEMETRY="0"')
  expect(runner).to include("npm exec -- openspec")
  expect(config).to include(
    "profile" => "custom",
    "delivery" => "skills",
    "workflows" => %w[explore propose apply verify sync archive],
  )
end
```

Also require `bin/node` and `bin/npm` to prefer `asdf which node`, with a
system Node fallback for CI and the devcontainer.

- [ ] **Step 2: Run the narrow spec and confirm the expected failure**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null \
  spec/tooling/open_spec_configuration_spec.rb
```

Expected: failure because the runner and scoped config do not exist.

- [ ] **Step 3: Create the scoped config**

Create `config/openspec/config.json`:

```json
{
  "featureFlags": {},
  "profile": "custom",
  "delivery": "skills",
  "workflows": [
    "explore",
    "propose",
    "apply",
    "verify",
    "sync",
    "archive"
  ]
}
```

- [ ] **Step 4: Create the runner**

Create executable `bin/node`, `bin/npm`, and `bin/openspec`. The first two keep
toolchain selection deterministic; `bin/openspec` additionally scopes config
and disables telemetry:

```bash
#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

export XDG_CONFIG_HOME="${ROOT_DIR}/config"
export OPENSPEC_TELEMETRY="0"

cd "${ROOT_DIR}"
exec npm exec -- openspec "$@"
```

- [ ] **Step 5: Verify the runner**

Run:

```bash
bin/openspec --version
bin/openspec config list --json
```

Expected: version `1.4.1`, `profile` is `custom`, and `delivery` is `skills`.

### Task 3: Initialize OpenSpec And Configure Harness References

**Files:**
- Create: `openspec/config.yaml`
- Create: `openspec/specs/`
- Create: `openspec/changes/`
- Create: `.codex/skills/openspec-explore/SKILL.md`
- Create: `.codex/skills/openspec-propose/SKILL.md`
- Create: `.codex/skills/openspec-apply-change/SKILL.md`
- Create: `.codex/skills/openspec-verify-change/SKILL.md`
- Create: `.codex/skills/openspec-sync-specs/SKILL.md`
- Create: `.codex/skills/openspec-archive-change/SKILL.md`
- Modify: `spec/tooling/open_spec_configuration_spec.rb`

- [ ] **Step 1: Add structural expectations**

Expect the OpenSpec config to use `spec-driven`, reference the existing harness,
and require artifact-specific rules. Expect exactly the selected generated
OpenSpec skills and no global prompt files inside the repository.

- [ ] **Step 2: Run the narrow spec and confirm it fails**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null \
  spec/tooling/open_spec_configuration_spec.rb
```

Expected: failure because OpenSpec has not been initialized.

- [ ] **Step 3: Initialize selected Codex skills**

Run:

```bash
bin/openspec init --tools codex --profile custom
```

Expected: OpenSpec structure and the six selected skills are created under the
repository; no `$CODEX_HOME/prompts/opsx-*.md` files are generated.

- [ ] **Step 4: Configure OpenSpec over the harness**

Set `openspec/config.yaml` to use `schema: spec-driven`. Add compact context that
requires agents to read `AGENTS.md`, classify through `docs/DEVELOPMENT.md`, load
context through `docs/CONTEXT_MAP.md`, preserve `docs/FOUNDATIONS.md` and
`docs/QUALITY_SECURITY.md`, use existing domain skills, and treat RSpec/Make
verification as authoritative.

Add artifact rules from the approved design:

- proposal: level, outcome, scope, non-goals, assumptions, risks, ADR decision;
- specs: observable requirements and GIVEN/WHEN/THEN scenarios;
- design: existing patterns, alternatives, data/security/operations/rollback;
- tasks: red/green increments, exact verification, artifact feedback loop,
  `CHANGES.md`.

- [ ] **Step 5: Validate generated structure**

Run:

```bash
bin/openspec validate --all --strict
```

Expected: success with no validation errors.

### Task 4: Create The Wild Waters SDD Orchestration Skill

**Files:**
- Create: `.codex/skills/wildwaters-spec-driven-change/SKILL.md`
- Create: `.codex/skills/wildwaters-spec-driven-change/agents/openai.yaml`

- [ ] **Step 1: Add pressure scenarios for the skill**

Run fresh read-only Codex sessions with these prompts and save the baseline
outputs outside the repository:

```text
Change one button label from "Map" to "Explore".
I have an idea for private waterfall notes, but I am not sure who should see them.
Add offline map synchronization with a new persistence strategy.
The implementation disproved an assumption in the approved feature design. Continue.
```

- [ ] **Step 2: Establish the baseline**

For each prompt, record whether Codex:

- selects the wrong task level;
- creates OpenSpec artifacts before user confirmation;
- omits risk or alternative analysis;
- treats an ADR as the feature specification;
- continues divergent implementation without updating artifacts.

- [ ] **Step 3: Generate the skill skeleton**

Run the system `skill-creator` initializer for
`wildwaters-spec-driven-change` under `.codex/skills`, including
`agents/openai.yaml`.

- [ ] **Step 4: Write the minimal orchestration skill**

The skill must:

- select Level 1, 2, or 3 using `docs/DEVELOPMENT.md`;
- use one-question-at-a-time discovery for Level 2/3;
- inspect mapped repository context before advice;
- challenge assumptions and surface applicable risks;
- wait for user confirmation before invoking `openspec-propose`;
- hand implementation to generated OpenSpec skills while retaining project TDD,
  permissions, domain skills, and verification;
- promote only durable decisions to ADR;
- use `bin/openspec` for all CLI operations;
- update artifacts when learning changes intent or design;
- require agentic verify plus mechanical/project gates before archive.

- [ ] **Step 5: Validate and forward-test the skill**

Run:

```bash
python3 /Users/a.tselovalnikov/.codex/skills/.system/skill-creator/scripts/quick_validate.py \
  .codex/skills/wildwaters-spec-driven-change
```

Repeat the same prompts with `$wildwaters-spec-driven-change` explicitly
invoked. Expected:

- copy-only change selects Level 1 and creates no OpenSpec change;
- uncertain private-notes feature selects Level 2 and asks one discovery
  question before creating artifacts;
- offline synchronization selects Level 3 and explains why explicit approval
  and an ADR are required;
- disproved assumptions cause the relevant OpenSpec artifacts to be updated
  before implementation resumes.

### Task 5: Integrate The Three Levels Into Project Documentation

**Files:**
- Modify: `AGENTS.md`
- Modify: `docs/DEVELOPMENT.md`
- Modify: `docs/CONTEXT_MAP.md`
- Modify: `docs/adr/README.md`
- Modify: `README.md`
- Modify: `CHANGES.md`

- [ ] **Step 1: Update the owning workflow document**

Add the approved three-level classification and lifecycle to
`docs/DEVELOPMENT.md`. Include:

```text
Level 1: direct existing harness
Level 2: explore -> approve -> propose -> TDD apply -> verify -> archive
Level 3: Level 2 plus ADR for durable architectural decisions
```

State that `bin/openspec validate --all --strict` is mechanical, while
`openspec-verify-change` is agentic and non-blocking by itself.

- [ ] **Step 2: Keep routing documents concise**

Update `AGENTS.md` only with the task-level routing rule and OpenSpec source-map
entry. Update `docs/CONTEXT_MAP.md` so active feature intent comes from the
relevant `openspec/changes/<name>` artifacts and current specified behavior comes
from the relevant `openspec/specs/<capability>`.

- [ ] **Step 3: Clarify ADR scope**

Update `docs/adr/README.md` to state that ADRs capture durable cross-cutting
decisions, while feature behavior and implementation plans belong to OpenSpec.

- [ ] **Step 4: Add the short human guide**

Add a compact README section with:

| Level | Use for | Start |
| --- | --- | --- |
| 1 | Tiny, obvious, local work | Normal Codex request |
| 2 | Meaningful feature or uncertain behavior | Invoke `$wildwaters-spec-driven-change` |
| 3 | Feature with durable architecture choice | Same skill; ADR may be promoted |

List only:

```bash
npm ci
bin/openspec list
bin/openspec update --force
bin/openspec validate --all --strict
make openspec-validate
```

- [ ] **Step 5: Record the process and dependency change**

Add a dated `CHANGES.md` entry without overwriting the user's existing local
skill entry.

- [ ] **Step 6: Check documentation formatting**

Run:

```bash
git diff --check
```

Expected: no whitespace errors.

### Task 6: Add Make And CI Validation

**Files:**
- Modify: `Makefile`
- Modify: `.github/workflows/ci.yml`
- Modify: `spec/tooling/open_spec_configuration_spec.rb`
- Modify: `spec/tooling/devcontainer_configuration_spec.rb`

- [ ] **Step 1: Add failing tooling expectations**

Require:

- `make openspec-install` to run `bin/npm ci`;
- `make openspec-update` to refresh generated skills through the wrapper;
- `make openspec-validate` to run the locked validation script;
- `make setup` to install the local OpenSpec dependency;
- `make doctor` to report Node, npm, and OpenSpec versions;
- full `make verify` to depend on OpenSpec validation;
- a dedicated GitHub Actions job using Node `24.16.0`, `npm ci`, and
  `make openspec-validate`.

- [ ] **Step 2: Run the narrow tooling specs and confirm failure**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null \
  spec/tooling/open_spec_configuration_spec.rb \
  spec/tooling/devcontainer_configuration_spec.rb
```

Expected: failure because Make and CI do not contain the new gate.

- [ ] **Step 3: Add Make targets**

Add `openspec-install`, `openspec-update`, and `openspec-validate` to `.PHONY`:

```make
openspec-install:
	bin/npm ci

openspec-update:
	bin/openspec update --force

openspec-validate:
	bin/openspec validate --all --strict
```

Make `setup` depend on `openspec-install` and `verify` depend on
`openspec-validate`. Add `bin/node --version`, `bin/npm --version`, and
`bin/openspec --version` to `doctor`. Keep `verify-fast` focused on Rails
feedback; Level 2/3 completion still runs the explicit OpenSpec gate.

- [ ] **Step 4: Add the CI job**

Add a `specifications` job:

```yaml
specifications:
  runs-on: ubuntu-latest
  steps:
    - name: Checkout code
      uses: actions/checkout@v6
    - name: Set up Node
      uses: actions/setup-node@v6
      with:
        node-version: "24.16.0"
        cache: npm
    - name: Install OpenSpec
      run: npm ci
    - name: Validate specifications
      run: make openspec-validate
```

- [ ] **Step 5: Run the narrow tooling specs**

Run the same focused RSpec command. Expected: pass.

### Task 7: Pin Node In The Devcontainer

**Files:**
- Modify: `Dockerfile.devcontainer`
- Modify: `spec/tooling/devcontainer_configuration_spec.rb`

- [ ] **Step 1: Add the exact-version expectation**

Require the devcontainer Dockerfile to declare `NODE_VERSION=24.16.0`, source
Node from the matching official Node image, and keep Node absent from
`Dockerfile` and `Dockerfile.dev`.

- [ ] **Step 2: Run the devcontainer spec and confirm failure**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null \
  spec/tooling/devcontainer_configuration_spec.rb
```

Expected: failure because the devcontainer currently installs distro
`nodejs`/`npm` without an exact version.

- [ ] **Step 3: Pin the official Node distribution**

Add a Node source stage:

```dockerfile
ARG NODE_VERSION=24.16.0
FROM node:${NODE_VERSION}-bookworm-slim AS node
```

Remove distro `nodejs` and `npm`, copy `/usr/local/bin/node` and
`/usr/local/lib/node_modules` from the Node stage, create the npm/npx symlinks,
then keep the existing global Codex CLI installation.

- [ ] **Step 4: Install project dependencies after container creation**

Add `npm ci` to `.devcontainer/post-create.sh` after `bundle check`, so the
repository-local OpenSpec binary is ready in new devcontainers.

- [ ] **Step 5: Build and verify the devcontainer image**

Run:

```bash
docker compose -f docker-compose.yml -f .devcontainer/docker-compose.yml build web
docker compose -f docker-compose.yml -f .devcontainer/docker-compose.yml run --rm web node --version
docker compose -f docker-compose.yml -f .devcontainer/docker-compose.yml run --rm web npm --version
docker compose -f docker-compose.yml -f .devcontainer/docker-compose.yml run --rm web bin/openspec --version
```

Expected: Node `v24.16.0` and OpenSpec `1.4.1`.

### Task 8: Final Verification

**Files:**
- Review all files changed above

- [ ] **Step 1: Validate the project skill**

Run the skill creator validator and confirm it passes.

- [ ] **Step 2: Validate OpenSpec**

Run:

```bash
bin/npm ci
bin/openspec validate --all --strict
```

Expected: success.

- [ ] **Step 3: Run focused tooling specs**

Run:

```bash
docker compose run --rm web bundle exec rspec --options /dev/null spec/tooling
```

Expected: pass.

- [ ] **Step 4: Run the full project gate**

Run:

```bash
make verify
```

Expected: OpenSpec validation, lint, RSpec, bundler-audit, and Brakeman all pass.

- [ ] **Step 5: Review the final diff**

Run:

```bash
git diff --check
git status --short
```

Expected: no formatting errors and only intended OpenSpec/harness files plus the
user's pre-existing changes.
