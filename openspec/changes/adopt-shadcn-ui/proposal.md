## Why

Wild Waters needs a stable, pleasant, and repeatable frontend design workflow
before the application-owned admin UI and richer public product screens grow.
The existing Inertia React migration preserved the old visual system, but the
project now needs a chosen UI kit, component-selection rules, and a light
design guide so future UI work does not devolve into page-local Tailwind
decisions.

Task level: 3. This introduces a durable component-system foundation and
therefore requires an ADR.

## What Changes

- Adopt shadcn/ui as the application-owned business/admin UI kit for the
  Inertia React frontend.
- Install and configure the shadcn CLI/project metadata for the existing Vite,
  React, TypeScript, and Tailwind stack.
- Add an initial shadcn component inventory sized for current routes and the
  first admin screens: buttons, form fields, inputs, selects, cards, badges,
  alerts, dialogs/sheets/drawers, dropdown/popover primitives, scroll areas,
  tables, pagination, skeletons, tooltips, toasts, and carousel where needed.
- Add Wild Waters composition components on top of shadcn primitives for stable
  product concepts such as form fields, waterfall cards, map controls, filter
  triggers, result panels, page headers, empty states, and admin toolbars.
- Migrate the current shared shell, auth forms, dashboard placeholder,
  waterfall detail, and explore map controls/results surfaces toward shadcn
  primitives while preserving the map-first Explore screen shape.
- Record the UI-kit-first development rule: prefer existing shadcn components,
  compose Wild Waters wrappers as children/compositions of kit primitives, and
  create fully custom controls only when no suitable kit primitive exists.
- Create a design-guide location and workflow for frontend work: design intent
  first, then tokens and reusable components, then page implementation.

Non-goals:

- Do not replace Rails-owned routing, authorization, I18n, CSRF, or Inertia
  page delivery.
- Do not change MapLibre map data loading, map provider strategy, or PostGIS
  query behavior.
- Do not build future non-waterfall spot-type UI or a full admin import
  operations surface in this change.
- Do not introduce SSR, a separate SPA, a generated route catalog, or a global
  client data-query layer.
- Do not require pixel-perfect cloning of AllTrails or any third-party product.

Assumptions:

- The shadcn Radix-based preset remains the default fit for this project unless
  installation proves otherwise.
- The existing `@/*` TypeScript alias can be reused for shadcn imports.
- Rails/I18n continues to supply user-facing copy through typed Inertia props.
- Current screenshots and prior AllTrails exploration are inspiration only,
  not implementation artifacts.

Unresolved questions:

- Which shadcn preset and base style should be selected during initialization
  after previewing generated config in this repository?
- Which visual snapshot/browser verification depth is sufficient for the first
  shadcn migration pass before Playwright is reconsidered?

## Capabilities

### New Capabilities

- `frontend-ui-system`: Defines the shadcn-backed UI-kit contract, Wild Waters
  composition layer, token/design-guide ownership, and frontend design workflow.

### Modified Capabilities

- `frontend-platform`: The frontend platform adds shadcn/ui generated source
  and locked npm dependencies as first-class frontend build inputs.
- `design-system-shell`: Shared shell, flash, form, and reusable-control
  behavior move to kit-first shadcn primitives with Wild Waters wrappers.
- `waterfall-discovery`: The Explore UI may be visually refreshed with
  shadcn-based filters, result cards, and map controls while preserving the
  map-first screen shape and MapLibre behavior.

## Impact

- Frontend dependencies: npm lockfile changes from shadcn and added component
  dependencies.
- Frontend source: `app/frontend/components/`, `app/frontend/pages/`,
  `app/frontend/styles/`, `app/frontend/entrypoints/application.css`,
  `components.json`, and any shadcn-generated support files.
- Tests: React component tests for shared controls, auth forms, shell, explore
  UI, and waterfall pages; request/system coverage remains responsible for
  Rails/Inertia contracts.
- Documentation: new ADR, design-guide/source-of-truth updates, context map
  updates, development workflow notes, and `CHANGES.md`.
- Verification: frontend install/build/typecheck/lint/tests/audit, relevant
  request/component/browser smoke coverage, strict OpenSpec validation, and the
  applicable Wild Waters verification gate.
