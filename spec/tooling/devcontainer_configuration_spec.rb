# frozen_string_literal: true

require "json"
require "yaml"

class DevcontainerConfiguration
end

RSpec.describe DevcontainerConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:devcontainer_path) { root.join(".devcontainer/devcontainer.json") }
  let(:devcontainer_compose_path) { root.join(".devcontainer/docker-compose.yml") }
  let(:codex_config_path) { root.join(".codex/config.toml") }
  let(:post_create_path) { root.join(".devcontainer/post-create.sh") }
  let(:dockerfile_dev_path) { root.join("Dockerfile.dev") }
  let(:dockerfile_devcontainer_path) { root.join("Dockerfile.devcontainer") }
  let(:devcontainer_config) { JSON.parse(devcontainer_path.read) }
  let(:devcontainer_compose) { YAML.safe_load(devcontainer_compose_path.read) }
  let(:post_create) { post_create_path.read }

  it "runs from the Rails compose service" do
    expect(devcontainer_config).to include(
      "service" => "web",
      "workspaceFolder" => "/app",
      "shutdownAction" => "stopCompose",
    )

    expect(devcontainer_config.fetch("dockerComposeFile")).to eq(
      [ "../docker-compose.yml", "docker-compose.yml" ],
    )
    expect(devcontainer_config.fetch("runServices")).to contain_exactly("db", "jobs")
    expect(devcontainer_config.fetch("forwardPorts")).to include(3000, 5432)
    expect(devcontainer_config.fetch("postCreateCommand")).to eq(".devcontainer/post-create.sh")
  end

  it "keeps the regular dev image minimal while using a separate agent image for devcontainer" do
    dockerfile = dockerfile_dev_path.read
    devcontainer_dockerfile = dockerfile_devcontainer_path.read

    expect(devcontainer_compose.dig("services", "web", "build", "dockerfile")).to eq("Dockerfile.devcontainer")
    expect(devcontainer_compose.dig("services", "web", "build", "context")).to eq(".")
    expect(dockerfile).not_to include("cli.github.com/packages")
    expect(dockerfile).not_to include("npm install -g @openai/codex")
    expect(devcontainer_dockerfile).to include("cli.github.com/packages")
    expect(devcontainer_dockerfile).to include("npm install -g @openai/codex")
  end

  it "mounts local developer credentials without committing secrets" do
    mounts = devcontainer_config.fetch("mounts")
    expect(mounts).to include(
      "source=${localEnv:HOME}/.codex,target=/root/.codex,type=bind,consistency=cached",
      "source=${localEnv:HOME}/.config/gh,target=/root/.config/gh,type=bind,consistency=cached",
      "source=${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,readonly,consistency=cached",
      "source=${localEnv:HOME}/.gitconfig,target=/root/.gitconfig-host,type=bind,readonly,consistency=cached",
    )
  end

  it "keeps the project Codex config safe for regular local work" do
    codex_config = codex_config_path.read

    expect(codex_config).to include('approval_policy = "on-request"')
    expect(codex_config).to include('sandbox_mode = "workspace-write"')
    expect(codex_config).not_to include("writable_roots")
    expect(codex_config).not_to match(/api[_-]?key|token|secret|password/i)
  end

  it "trusts the container workspace for Codex and Git" do
    expect(post_create).to include('[projects."/app"]')
    expect(post_create).to include('trust_level = "trusted"')
    expect(post_create).to include('git config --global --add include.path /root/.gitconfig-host')
    expect(post_create).to include('git config --global --add include.path /root/.gitconfig-devcontainer')
    expect(post_create).to include('git config --file /root/.gitconfig-devcontainer --add safe.directory /app')
    expect(post_create).not_to include('git config --global --add safe.directory /app')
  end

  it "pins Node in the development image without apt Node packages" do
    dockerfile = dockerfile_devcontainer_path.read

    expect(dockerfile).to include("ARG NODE_VERSION=24.16.0")
    expect(dockerfile.index("ARG RUBY_VERSION=4.0.5")).to be < dockerfile.index("FROM node:")
    expect(dockerfile).to include('FROM node:${NODE_VERSION}-bookworm-slim AS node')
    expect(dockerfile).to include("COPY --from=node /usr/local/bin/node /usr/local/bin/node")
    expect(dockerfile).not_to match(/^\s+nodejs\s*\\/m)
    expect(dockerfile).not_to match(/^\s+npm\s*\\/m)
  end

  it "keeps the Ruby and RubyGems versions aligned across the toolchain" do
    ruby_version = "4.0.5"
    rubygems_version = "4.0.14"
    dockerfiles = %w[Dockerfile Dockerfile.dev Dockerfile.devcontainer].map { |path| root.join(path).read }
    compose = root.join("docker-compose.yml").read

    expect(root.join(".ruby-version").read.strip).to eq("ruby-#{ruby_version}")
    expect(root.join(".tool-versions").read).to include("ruby #{ruby_version}")
    expect(compose.scan(/RUBY_VERSION: "#{Regexp.escape(ruby_version)}"/).size).to eq(2)
    expect(dockerfiles.first).to include("COPY Gemfile Gemfile.lock .ruby-version vendor ./")

    expect(dockerfiles).to all(include("ARG RUBY_VERSION=#{ruby_version}"))
    expect(dockerfiles).to all(include("ARG RUBYGEMS_VERSION=#{rubygems_version}"))
  end

  it "installs the agent and GitHub tools in the development image" do
    dockerfile = dockerfile_devcontainer_path.read

    expect(dockerfile).to include("cli.github.com/packages")
    expect(dockerfile).to include("bubblewrap")
    expect(dockerfile).to include("gh")
    expect(dockerfile).to include("npm install -g @openai/codex")
  end

  it "installs project Node dependencies during container creation" do
    expect(devcontainer_compose.dig("services", "web", "build", "args", "NODE_VERSION")).to eq("24.16.0")
    expect(post_create).to include("npm ci")
    expect(post_create).to include("bin/openspec --version")
  end

  it "removes outdated shell aliases before installing the Codex function" do
    expect(post_create).to include("sed -i")
    expect(post_create).to include("alias codex=")
  end

  it "starts Codex with container-safe defaults" do
    codex_function = post_create.match(/codex\(\) \{\n(?<body>.*?)\n\}/m)[:body]

    expect(codex_function).to include("--cd /app")
    expect(codex_function).to include("--dangerously-bypass-approvals-and-sandbox")
    expect(codex_function).to include("-c 'mcp_servers.chrome-devtools.command=\"npx\"'")
    expect(codex_function).not_to include("--sandbox workspace-write")
  end
end
