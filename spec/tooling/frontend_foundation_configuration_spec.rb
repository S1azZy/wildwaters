# frozen_string_literal: true

require "json"
require "pathname"

class FrontendFoundationConfiguration
end

RSpec.describe FrontendFoundationConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:package) { JSON.parse(root.join("package.json").read) }
  let(:scripts) { package.fetch("scripts") }

  it "pins the approved frontend runtime and build dependencies" do
    expect(package.fetch("dependencies")).to include(
      "@inertiajs/react" => "3.4.0",
      "react" => "19.2.7",
      "react-dom" => "19.2.7",
    )
    expect(package.fetch("devDependencies")).to include(
      "@tailwindcss/vite" => "4.3.1",
      "tailwindcss" => "4.3.1",
      "typescript" => "6.0.3",
      "vite" => "8.0.16",
      "vitest" => "4.1.9",
    )
  end

  it "provides deterministic frontend quality scripts" do
    expect(scripts).to include(
      "frontend:audit" => "npm audit --audit-level=high",
      "frontend:build" => "RAILS_ENV=production vite build",
      "frontend:format" => 'prettier --check "app/frontend/**/*.{ts,tsx,css}" vite.config.ts eslint.config.mjs package.json tsconfig.json',
      "frontend:lint" => "eslint .",
      "frontend:test" => "vitest run --coverage --passWithNoTests",
      "frontend:typecheck" => "tsc --noEmit"
    )
  end

  it "runs every frontend quality gate through the verification script" do
    expect(scripts.fetch("frontend:verify")).to include(
      "frontend:format",
      "frontend:lint",
      "frontend:typecheck",
      "frontend:test",
      "frontend:build",
      "frontend:audit",
    )
  end

  it "uses strict TypeScript and the shared Vitest setup" do
    tsconfig = root.join("tsconfig.json").read
    vite_config = root.join("vite.config.ts").read

    expect(tsconfig).to include('"strict": true', '"noEmit": true')
    expect(vite_config).to include("react()", "tailwindcss()", 'setupFiles: ["./test/setup.ts"]')
    expect(root.join("app/frontend/test/setup.ts")).to exist
  end

  it "uses the Inertia layout with the Vite React entrypoint" do
    inertia_layout = root.join("app/views/layouts/inertia.html.erb").read

    expect(inertia_layout).to include("vite_react_refresh_tag")
    expect(inertia_layout).to include('vite_typescript_tag "application.tsx"')
  end

  it "declares the frontend entrypoints and Rails integration" do
    expect(root.join("app/frontend/entrypoints/application.tsx")).to exist
    expect(root.join("app/frontend/entrypoints/application.css")).to exist
    expect(root.join("config/vite.json")).to exist
    expect(root.join("config/initializers/inertia_rails.rb")).to exist
  end

  it "proves the frontend runtime through a production waterfall page" do
    routes = root.join("config/routes.rb").read
    controller = root.join("app/controllers/waterfalls_controller.rb").read

    expect(root.join("app/frontend/pages/Waterfalls/Index.tsx")).to exist
    expect(root.join("app/frontend/pages/Waterfalls/Show.tsx")).to exist
    expect(controller).to include('render inertia: "Waterfalls/Index"')
    expect(controller).to include('render inertia: "Waterfalls/Show"')
    expect(routes).to include("root \"waterfalls#index\"")
  end

  it "preserves representative Inertia styles in the Vite stylesheet" do
    vite_config = JSON.parse(root.join("config/vite.json").read)
    output_dir = vite_config.fetch("test").fetch("publicOutputDir")
    build_dir = root.join("public", output_dir)
    manifest = JSON.parse(build_dir.join(".vite/manifest.json").read)
    stylesheet = build_dir.join(manifest.fetch("entrypoints/application.css").fetch("file")).read

    expect(stylesheet).to include(
      "--color-primary-500",
      ".site-shell",
      ".auth-shell",
      ".explore-map-shell",
    )
  end

  it "integrates Vite with the supported development process" do
    procfile = root.join("Procfile.dev").read
    dev_script = root.join("bin/dev").read
    vite_ruby_config = root.join("config/vite.json").read

    expect(procfile).to include("vite: bin/vite dev")
    expect(dev_script).to include("foreman start -f Procfile.dev -e /dev/null")
    expect(vite_ruby_config).to include('"host": "0.0.0.0"', '"skipProxy": false')
    expect(root.join("vite.config.ts").read).to include('host: "localhost"', "port: 3036")
  end

  it "integrates frontend verification with delivery commands" do
    makefile = root.join("Makefile").read
    ci = root.join("config/ci.rb").read
    dockerfile = root.join("Dockerfile").read

    expect(makefile).to include("frontend-install:", "frontend-verify:", "bin/npm run frontend:verify")
    expect(ci).to include("Frontend:")
    expect(dockerfile).to include("npm ci", "npm run frontend:build")
  end

  it "exposes npm dependency freshness through Make" do
    makefile = root.join("Makefile").read

    expect(makefile).to include("frontend-outdated:", "bin/npm outdated")
  end

  it "scopes Vite development CSP allowances to development" do
    content_security_policy = root.join("config/initializers/content_security_policy.rb").read

    expect(content_security_policy).to include(
      "Rails.env.development?",
      "ws://localhost:3036",
    )
    expect(content_security_policy).not_to include("http://localhost:3036")
  end
end
