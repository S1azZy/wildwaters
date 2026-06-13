# frozen_string_literal: true

require "json"
require "pathname"
require "yaml"

class OpenSpecConfiguration
end

RSpec.describe OpenSpecConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:config) { YAML.safe_load(root.join("openspec/config.yaml").read) }
  let(:makefile) { root.join("Makefile").read }
  let(:workflow) { root.join(".github/workflows/ci.yml").read }
  let(:skill_names) do
    Dir[root.join(".codex/skills/openspec-*/SKILL.md")]
      .map { |path| Pathname(path).dirname.basename.to_s }
  end
  let(:spec_paths) { Dir[root.join("openspec/specs/*/spec.md")].map { |path| Pathname(path) } }
  let(:spec_names) { spec_paths.map { |path| path.dirname.basename.to_s } }

  it "pins the shared Node and OpenSpec versions" do
    expect(root.join(".tool-versions").read).to include("nodejs 24.16.0")

    package = JSON.parse(root.join("package.json").read)
    expect(package.dig("engines", "node")).to eq("24.16.0")
    expect(package.dig("devDependencies", "@fission-ai/openspec")).to eq("1.4.1")
  end

  it "routes project npm commands through the asdf Node version" do
    node_runner = root.join("bin/node").read
    npm_runner = root.join("bin/npm").read

    expect(node_runner).to include("asdf which node")
    expect(node_runner).to include('exec "${ASDF_NODE}" "$@"')
    expect(npm_runner).to include("asdf which node")
    expect(npm_runner).to include('exec npm "$@"')
  end

  it "isolates OpenSpec configuration and disables telemetry" do
    runner = root.join("bin/openspec").read
    cli_config = JSON.parse(root.join("config/openspec/config.json").read)

    expect(runner).to include('XDG_CONFIG_HOME="${ROOT_DIR}/config"')
    expect(runner).to include('OPENSPEC_TELEMETRY="0"')
    expect(runner).to include("asdf which node")
    expect(runner).to include("npm exec -- openspec")
    expect(cli_config).to include(
      "profile" => "custom",
      "delivery" => "skills",
      "workflows" => %w[explore propose apply verify sync archive],
    )
  end

  it "layers feature specifications over the existing harness" do
    expected_sources = %w[
      AGENTS.md docs/DEVELOPMENT.md docs/CONTEXT_MAP.md
      docs/FOUNDATIONS.md docs/QUALITY_SECURITY.md docs/TODO.md
    ]

    expect(config.fetch("schema")).to eq("spec-driven")
    expect(config.fetch("context")).to include(*expected_sources)
    expect(config.fetch("rules").keys).to contain_exactly("proposal", "specs", "design", "tasks")
  end

  it "keeps a capability baseline for implemented behavior" do
    expect(spec_names).to contain_exactly(
      "admin-job-operations",
      "authentication",
      "design-system-shell",
      "geonames-region-import",
      "password-reset",
      "region-management",
      "spot-waterfall-domain",
      "waterfall-discovery",
    )
  end

  it "keeps every capability specification structurally valid" do
    spec_paths.each do |path|
      content = path.read

      expect(content).to include("## Purpose", "## Requirements")
      expect(content).to match(/^### Requirement: .+/)
      expect(content).to match(/\b(?:SHALL|MUST)\b/)
      expect(content).to match(/^#### Scenario: .+/)
      expect(content).to match(/^- \*\*WHEN\*\* .+/)
      expect(content).to match(/^- \*\*THEN\*\* .+/)
    end
  end

  it "keeps unimplemented work outside ADRs and baseline specifications" do
    todo = root.join("docs/TODO.md").read
    adr_index = root.join("docs/adr/README.md").read

    expect(todo).to include("This document is the ordered queue for known behavior that is not implemented.")
    expect(adr_index).to include("Move unimplemented work to `docs/TODO.md`")
  end

  it "installs only the selected OpenSpec skills" do
    expect(skill_names).to contain_exactly(
      "openspec-explore",
      "openspec-propose",
      "openspec-apply-change",
      "openspec-verify-change",
      "openspec-sync-specs",
      "openspec-archive-change",
    )
    expect(Dir[root.join(".codex/prompts/opsx-*.md")]).to be_empty
  end

  it "integrates installation and adapter updates with Make" do
    expect(makefile).to include("setup: openspec-install")
    expect(makefile).to include("openspec-install:\n\tbin/npm ci")
    expect(makefile).to include("openspec-update:\n\tbin/openspec update --force")
  end

  it "integrates validation and tool diagnostics with Make" do
    expect(makefile).to include("openspec-validate:\n\tbin/openspec validate --all --strict")
    expect(makefile).to include("verify: openspec-validate")
    expect(makefile).not_to include("verify-fast: openspec-validate")
    expect(makefile).to include("bin/node --version")
    expect(makefile).to include("bin/npm --version")
    expect(makefile).to include("bin/openspec --version")
  end

  it "validates specifications in a dedicated CI job" do
    expect(workflow).to include("specifications:")
    expect(workflow).to include("uses: actions/setup-node@v6")
    expect(workflow).to include('node-version: "24.16.0"')
    expect(workflow).to include("run: npm ci")
    expect(workflow).to include("run: make openspec-validate")
  end
end
