# frozen_string_literal: true

require "json"
require "pathname"

class FrontendFoundationConfiguration
end

RSpec.describe FrontendFoundationConfiguration do
  let(:root) { Pathname(__dir__).join("../..").expand_path }
  let(:package) { JSON.parse(root.join("package.json").read) }
  let(:scripts) { package.fetch("scripts") }
  let(:shadcn_config) { JSON.parse(root.join("components.json").read) }
  let(:shadcn_inventory) do
    %w[
      alert alert-dialog avatar badge breadcrumb button card carousel checkbox
      command dialog drawer dropdown-menu empty field hover-card input
      input-group label pagination popover progress radio-group scroll-area
      select separator sheet skeleton sonner spinner switch table tabs textarea
      toggle toggle-group tooltip
    ]
  end

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
      "frontend:format" => 'prettier --check "app/frontend/**/*.{ts,tsx,css}" vite.config.ts eslint.config.mjs package.json tsconfig.json components.json',
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

  it "provides RTK-backed agent commands for compact local feedback" do
    makefile = root.join("Makefile").read
    dev_dockerfile = root.join("Dockerfile.dev").read

    expect(dev_dockerfile).to include(
      "ARG RTK_VERSION=0.43.0",
      "github.com/rtk-ai/rtk/releases/download/v${RTK_VERSION}",
      "RTK_TELEMETRY_DISABLED=1",
      "RTK_TEE_DIR=/app/tmp/rtk/tee",
    )
    expect(makefile).to include(
      "agent-rspec:",
      "WW_SKIP_SIMPLECOV=1 RAILS_ENV=test rtk rspec $(SPEC)",
      "rtk rspec $(SPEC)",
      "agent-frontend-test: frontend-install",
      "rtk vitest run --coverage --passWithNoTests",
      "agent-rubocop:",
      "rtk rubocop -A --config /app/.rubocop.yml",
      "agent-verify-fast: frontend-install",
    )
  end

  it "exposes npm dependency freshness through Make" do
    makefile = root.join("Makefile").read

    expect(makefile).to include("frontend-outdated:", "bin/npm outdated")
  end

  it "configures the shadcn Radix preset for Vite React" do
    expect(shadcn_config).to include(
      "style" => "radix-nova",
      "rsc" => false,
      "tsx" => true,
      "iconLibrary" => "lucide"
    )
  end

  it "routes shadcn CSS and generated imports through frontend paths" do
    expect(shadcn_config.fetch("tailwind")).to include(
      "css" => "app/frontend/entrypoints/application.css",
      "cssVariables" => true
    )
    expect(shadcn_config.fetch("aliases")).to include(
      "components" => "@/components",
      "ui" => "@/components/ui",
      "utils" => "@/lib/utils",
    )
  end

  it "pins the shadcn core dependency graph in npm" do
    expect(package.fetch("dependencies")).to include(
      "class-variance-authority" => "^0.7.1",
      "clsx" => "^2.1.1",
      "lucide-react" => "^1.21.0",
      "radix-ui" => "^1.6.0",
      "shadcn" => "^4.11.0",
      "tailwind-merge" => "^3.6.0"
    )
  end

  it "pins the shadcn generated component dependencies in npm" do
    expect(package.fetch("dependencies")).to include(
      "cmdk" => "^1.1.1",
      "embla-carousel-react" => "^8.6.0",
      "sonner" => "^2.0.7",
      "tw-animate-css" => "^1.4.0",
      "vaul" => "^1.1.2"
    )
  end

  it "provides the initial shadcn primitive inventory" do
    ui_dir = root.join("app/frontend/components/ui")
    missing_components = shadcn_inventory.reject { |component| ui_dir.join("#{component}.tsx").exist? }

    expect(ui_dir).to exist
    expect(missing_components).to be_empty
  end

  it "maps shadcn semantic tokens to the Digital Naturalist vocabulary" do
    stylesheet = root.join("app/frontend/entrypoints/application.css").read

    expect(stylesheet).to include(
      "--primary: var(--color-primary-500)",
      "--secondary: var(--color-secondary-100)",
      "--accent: var(--color-tertiary-100)",
      "--background: var(--color-surface-base)",
      "--radius: var(--radius-ui-md)",
    )
    expect(stylesheet).not_to include("Geist Variable")
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
