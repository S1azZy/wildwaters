# frozen_string_literal: true

require "json"

class DevcontainerConfiguration
end

RSpec.describe DevcontainerConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:devcontainer_path) { root.join(".devcontainer/devcontainer.json") }
  let(:codex_config_path) { root.join(".codex/config.toml") }
  let(:post_create_path) { root.join(".devcontainer/post-create.sh") }
  let(:dockerfile_dev_path) { root.join("Dockerfile.dev") }
  let(:devcontainer_config) { JSON.parse(devcontainer_path.read) }
  let(:post_create) { post_create_path.read }

  it "runs from the Rails compose service" do
    expect(devcontainer_config).to include(
      "dockerComposeFile" => "../docker-compose.yml",
      "service" => "web",
      "workspaceFolder" => "/app",
      "shutdownAction" => "stopCompose",
    )

    expect(devcontainer_config.fetch("runServices")).to contain_exactly("db", "jobs")
    expect(devcontainer_config.fetch("forwardPorts")).to include(3000, 5432)
    expect(devcontainer_config.fetch("postCreateCommand")).to eq(".devcontainer/post-create.sh")
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

  it "configures Codex for autonomous work inside the container sandbox" do
    codex_config = codex_config_path.read

    expect(codex_config).to include('approval_policy = "never"')
    expect(codex_config).to include('sandbox_mode = "workspace-write"')
    expect(codex_config).to include("network_access = true")
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

  it "installs the agent and GitHub tools in the development image" do
    dockerfile = dockerfile_dev_path.read

    expect(dockerfile).to include("cli.github.com/packages")
    expect(dockerfile).to include("bubblewrap")
    expect(dockerfile).to include("gh")
    expect(dockerfile).to include("npm install -g @openai/codex")
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
