## 1. Architecture And Design Workflow

- [ ] 1.1 Create ADR 0006 for shadcn/ui adoption, component ownership boundaries, alternatives, and consequences.
- [ ] 1.2 Create `docs/frontend/DESIGN_GUIDE.md` with the Wild Waters frontend design workflow, token ownership, shadcn-first component rules, and custom-component exception policy.
- [ ] 1.3 Update `docs/CONTEXT_MAP.md`, `docs/FOUNDATIONS.md`, and `docs/TODO.md` so future frontend/design-system work routes to the ADR, design guide, and shadcn-backed component layer.
- [ ] 1.4 Update `CHANGES.md` for the architecture/process decision.

## 2. Shadcn Tooling Foundation

- [ ] 2.1 Initialize shadcn/ui for the existing Vite React project using the repository package runner and the `@/*` alias.
- [ ] 2.2 Add the focused initial shadcn component inventory for actions, forms, cards, overlays, feedback, navigation, table scaffolding, loading states, and carousel/image card needs.
- [ ] 2.3 Map shadcn semantic tokens to the existing Digital Naturalist vocabulary in the approved frontend CSS entrypoints without creating a second unrelated palette.
- [ ] 2.4 Add or update tooling/configuration specs proving shadcn metadata, generated primitive paths, CSS source discovery, and locked npm dependency ownership.

## 3. Shared Wild Waters Components

- [ ] 3.1 Add Wild Waters wrappers around shadcn primitives for repeated actions, fields, badges, cards, empty states, icon controls, page headers, and feedback states.
- [ ] 3.2 Add focused React component tests and accessibility checks for the wrappers' visible labels, disabled/invalid states, live regions, and keyboard-reachable controls.
- [ ] 3.3 Migrate `AppShell`, `SiteHeader`, and `Flash` to kit-backed primitives or wrappers while preserving typed shell props, translated copy, Rails URLs, and flash semantics.

## 4. Auth And Dashboard Migration

- [ ] 4.1 Replace auth form visual primitives with shadcn-backed fields, buttons, cards, and error states while preserving Inertia `useForm`, form names, Rails-generated submit URLs, processing state, and current auth behavior.
- [ ] 4.2 Refresh the dashboard placeholder with shadcn-backed layout/actions and keep the protected dashboard contract unchanged.
- [ ] 4.3 Update auth/dashboard component tests and run the narrow frontend tests for shell, auth pages, and dashboard.

## 5. Waterfall And Explore Migration

- [ ] 5.1 Refresh the waterfall detail page with shadcn-backed cards, badges, facts, and navigation while preserving public props and detail behavior.
- [ ] 5.2 Refresh Explore filter controls, result cards, result rail/panel, map style/zoom controls, empty/loading states, and responsive map/list controls with shadcn-backed wrappers.
- [ ] 5.3 Keep MapLibre lifecycle, map payload shape, filtering, and map security behavior unchanged; update tests only for user-visible UI contracts and accessibility.
- [ ] 5.4 Run the narrow waterfall/explore request, component, and browser smoke checks required by the migration.

## 6. Verification And Follow-Through

- [ ] 6.1 Run `bin/openspec validate adopt-shadcn-ui --strict` and then `bin/openspec validate --all --strict`.
- [ ] 6.2 Run frontend format, lint, typecheck, component tests, production build, and npm audit through the repository Make/container workflow.
- [ ] 6.3 Run the applicable Wild Waters verification gate from `docs/DEVELOPMENT.md`; before PR or merge, run `make verify`.
- [ ] 6.4 Remove superseded local CSS/classes only after replacement components and tests prove the new contract.
- [ ] 6.5 Review changed OpenSpec artifacts, ADR, docs, lockfile, generated shadcn files, React components, and tests before marking the change ready for archive.
