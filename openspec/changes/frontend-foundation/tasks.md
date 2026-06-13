## 1. Confirm and Pin the Toolchain

- [ ] 1.1 Re-check the approved major lines against the then-current official Vite Ruby, Inertia Rails, Inertia, React, TypeScript, Tailwind, ESLint, and Vitest compatibility requirements; record exact versions and update `proposal.md` or `design.md` before continuing if the approved architecture would need to change.
- [ ] 1.2 Add the approved Ruby and npm dependencies with exact lockfile resolution, retain npm as the only JavaScript package manager, and verify `npm ci` leaves `package-lock.json` unchanged.
- [ ] 1.3 Add a failing `spec/tooling/frontend_foundation_configuration_spec.rb` that describes the required scripts, strict TypeScript configuration, Vite entrypoints, separate layouts, and supported process/build integration.

## 2. Establish Frontend Build and Quality Configuration

- [ ] 2.1 Add Vite Ruby/Vite Rails, Inertia Rails, React, and strict TypeScript configuration until the initial tooling examples pass.
- [ ] 2.2 Add deterministic npm scripts and configuration for Prettier check, ESLint with TypeScript/React/Hooks/JSX accessibility rules, `tsc --noEmit`, Vitest with jsdom and coverage, Vite production build, and npm audit.
- [ ] 2.3 Add shared Vitest setup for React Testing Library, jest-dom, user-event, cleanup, and the maintained axe-core-compatible assertion adapter selected in task 1.1.
- [ ] 2.4 Run the narrow tooling spec and the frontend format, lint, typecheck, empty-harness test, build, and audit commands; keep the tooling spec red until every declared integration is real.

## 3. Move Tailwind to Vite Without Redesign

- [ ] 3.1 Add or extend a failing system/tooling example that proves representative legacy shell, authentication, and explore utility classes remain in the Vite-built stylesheet.
- [ ] 3.2 Move the Tailwind 4 entrypoint, Digital Naturalist tokens, and current shared CSS into frontend-owned sources, with explicit source discovery for legacy ERB/Ruby and React TypeScript files.
- [ ] 3.3 Update the legacy layout to load the Vite-built stylesheet while retaining its current importmap runtime, then remove `tailwindcss-rails` and its build/watch path only after the parity example passes.
- [ ] 3.4 Run `spec/system/design_system_shell_spec.rb`, `spec/system/waterfall_explore_spec.rb`, the narrow tooling spec, frontend build, and `make erb-lint`.

## 4. Prove the Inertia Runtime Contract

- [ ] 4.1 Add a failing `spec/requests/frontend/smoke_spec.rb` for the development/test-only route, expected Inertia component, translated text and URL props, non-sensitive prop keys, and isolated Inertia layout.
- [ ] 4.2 Add a failing React Testing Library test for the smoke page's typed prop rendering, accessible interaction, shared styles/classes, and JavaScript-required fallback contract where applicable.
- [ ] 4.3 Implement the separate Inertia root layout, shared typed page-prop definitions, and minimal smoke page/controller/route until the request and component tests pass; do not load Turbo, Stimulus, or importmap in the Inertia layout.
- [ ] 4.4 Add a focused routing/configuration example proving the smoke route is restricted to development and test, and add a browser smoke example proving client rendering through Rails.
- [ ] 4.5 Verify CSRF metadata, same-origin production entrypoints, and environment-scoped Vite development CSP/connect allowances without weakening the production policy.

## 5. Integrate Development, Test, CI, and Production Delivery

- [ ] 5.1 Add a failing tooling example for the supported Rails-plus-Vite development process, then update `Procfile.dev`, Docker development configuration, setup, and Make targets so the smoke page supports live frontend development.
- [ ] 5.2 Update test setup and Make targets so frontend assets and tests run deterministically before RSpec examples that resolve Vite entrypoints; preserve narrow commands for fast feedback.
- [ ] 5.3 Update `bin/ci` and GitHub Actions to run `npm ci`, format check, ESLint, typecheck, Vitest with coverage, production build, and npm audit alongside existing Ruby, ERB, RSpec, Brakeman, Bundler, and importmap checks.
- [ ] 5.4 Add the production Docker frontend build stage, copy only compiled assets into the final runtime image, and prove the image does not require a running Node or SSR process.
- [ ] 5.5 Run the narrow tooling/request/component/browser specs, `make verify-fast`, `make security`, and a clean production Docker build; record any unrelated blocker exactly.

## 6. Close the Foundation Change

- [ ] 6.1 Review compiled assets and Inertia response props for accidental secrets, unnecessary global data, duplicate JavaScript runtimes, missing cache fingerprints, and development-only CSP leakage.
- [ ] 6.2 Perform a browser comparison of representative legacy pages and the smoke page, including mobile layout, accessible names, keyboard use, flash behavior, and Vite development reload.
- [ ] 6.3 Update implementation-owned command/context/security documentation and `CHANGES.md` in a documentation-only branch, preserving this branch separation policy.
- [ ] 6.4 If implementation learning changes intent, requirements, architecture, or tool ownership, update these approved OpenSpec artifacts and obtain approval before divergent work continues.
- [ ] 6.5 Run `bin/openspec validate --all --strict`, all narrow specs, `make verify`, and the production image build, then invoke `$openspec-verify-change` before archive.
