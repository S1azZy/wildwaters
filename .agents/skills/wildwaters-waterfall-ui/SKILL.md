---
name: wildwaters-waterfall-ui
description: Use this skill when changing Wild Waters waterfall discovery UI: public waterfall browse/detail Inertia pages, Explore map chrome, filters, result rail/cards, MapLibre-adjacent controls, waterfall-facing ru/en copy, or shared React/shadcn components used by waterfall pages. Do not use for backend-only query or import changes unless they alter the waterfall UI contract.
---

# Wild Waters Waterfall UI

## Purpose

Keep waterfall discovery UI work aligned with the current Wild Waters frontend:
Rails-owned routes/I18n/data selection, Inertia React pages, TypeScript,
shadcn/ui primitives, Wild Waters wrappers, Tailwind tokens, and MapLibre as a
feature-owned map engine.

This skill is for the public waterfall product surface. It is not a generic
frontend design skill.

## Task packet

Before editing, classify through `docs/DEVELOPMENT.md`.

```text
Surface: explore | detail | filters | result rail | map controls | copy | shared component
Change kind: visual-only | UI behavior | Inertia prop contract | map-data contract
Behavior change: yes/no
OpenSpec: none | required by SDD Level 2/3
Rails contract:
React owner:
MapLibre/PostGIS impact: none | UI only | data/query
Tests:
Verification:
```

## Read

Load only the slice that matches the task.

- Workflow and verification: `docs/DEVELOPMENT.md`.
- Context routing: `docs/CONTEXT_MAP.md` rows for Waterfall pages, Explore map
  UI, Inertia page/layout, UI components, styles/design tokens, and I18n copy.
- Product boundary: `docs/FOUNDATIONS.md` waterfall-first MVP and frontend
  architecture boundaries.
- Frontend architecture: `docs/adr/0005-business-frontend-architecture.md`.
- Component foundation: `docs/adr/0006-shadcn-ui-component-foundation.md` and
  `docs/frontend/DESIGN_GUIDE.md`.
- Map behavior only when touched: `docs/adr/0001-map-browse-stack.md`,
  `app/frontend/lib/maplibre.ts`, `app/frontend/pages/Waterfalls/useExploreMap.ts`,
  and matching map/request/system specs.
- Target vertical slice: the page/component/hook, Rails controller or presenter
  that builds its props, matching request spec, React test, and system spec
  only when browser/map behavior changes.

## Do not read by default

- Legacy ERB/Hotwire/Stimulus/ViewComponent history.
- Import ADRs or import code.
- Admin/auth/security docs unless the UI exposes protected, private, admin, or
  user-owned data.
- All React components, all locale files, or all specs.
- `db/structure.sql`, unless a separate schema/PostGIS task requires generated
  schema inspection.

## Ownership boundaries

- Rails owns routes, URLs, translated copy, authorization decisions, data
  selection, form endpoints, and Inertia prop contracts.
- React owns rendering, local interaction state, typed page composition, and
  accessible component behavior.
- `app/frontend/pages/Waterfalls/**` owns waterfall-specific page regions and
  feature-local hooks.
- `app/frontend/components/ui` owns shadcn-generated primitives.
- `app/frontend/components/ww` owns repeated Wild Waters product concepts built
  from primitives.
- MapLibre lifecycle and map data behavior stay feature-owned; shadcn owns
  controls around the map, not the map engine.
- Bounded JSON endpoints such as map data are allowed for dynamic map payloads;
  they are not a general client API or client-side data layer.

## Procedure

1. Identify the surface and contract: page props, local UI state, map payload,
   copy, or shared component API.
2. Preserve waterfall-first product behavior. Do not introduce generic outdoor
   platform, future spot-type, routing, recommendation, social, or moderation
   abstractions without an approved product change.
3. Keep Inertia pages as route-level orchestration. Move repeated or visually
   distinct regions into typed feature components; move map/browser lifecycle,
   refs, cancellation, and persistence into local hooks.
4. Choose UI building blocks in ADR 0006 order: installed shadcn primitive,
   existing Wild Waters wrapper, new wrapper for repeated product concepts,
   custom component only for map-specific or unmatched semantics.
5. Keep Rails-owned copy in `config/locales/en.yml` and
   `config/locales/ru.yml`, delivered through typed props unless a separate
   approved I18n architecture change says otherwise.
6. Keep map payloads lean and display-ready. If a UI change needs new query,
   bounds, nearby, or payload behavior, also use `wildwaters-postgis-discovery-query`.
7. For behavior or prop-contract changes, write/update the narrow request spec
   and React Testing Library test first. Add/update a system/browser smoke only
   when layout, map behavior, navigation, or responsive interaction changes.
8. For visual-only polish, edit the smallest surface and verify the narrowest
   relevant component or browser check. Do not add tests that only assert a
   retired implementation detail is absent.
9. Update `CHANGES.md` when the change is user-facing, process-affecting, or
   changes the UI contract.

## Proof

Use the smallest proof that matches the change:

- Inertia prop/copy contract: request spec plus relevant React page/component
  test.
- Component behavior/accessibility: React Testing Library test with user-visible
  labels, roles, states, and keyboard behavior.
- Explore map controls or responsive layout: targeted component test plus
  system/browser smoke when real browser layout or MapLibre integration matters.
- Map data shape: request/query/presenter spec, then frontend test if the UI
  consumes the changed field.
- Visual-only token/class polish: component/browser smoke or `make
  frontend-format` when no behavior changed.

Final gate follows `docs/DEVELOPMENT.md`, normally `make verify-fast` for
waterfall React/Inertia page work.

## Output

```text
Loaded:
Skipped:
Surface:
Change kind:
Rails contract:
React owner:
Component layer: page | feature component | ww wrapper | shadcn primitive
Map/Data impact:
Locale keys:
Tests:
Verification:
Open question:
```

## Gotchas

- Do not reintroduce ERB/Hotwire/Stimulus/ViewComponent for application-owned
  business waterfall UI.
- Do not add a second route catalog, translation catalog, global state store,
  or general client-query layer.
- Do not move Rails authorization, URLs, I18n, data selection, or form endpoint
  ownership into React.
- Do not expand `components/ww` for one-off page details; keep those
  feature-local until reuse is real.
- Do not edit generated shadcn primitive internals for product styling that
  belongs in wrappers, variants, tokens, or page composition.
- Do not use migration-era negative assertions such as checking that old
  importmap/Stimulus details are absent.
- Do not hide map payload bloat inside frontend convenience fields; keep public
  waterfall map data product-shaped and bounded.

## Examples

```text
Request: "Make Explore result cards show a new region label."
Use this skill. Check Rails presenter/props, locale copy if any, result card
component, request spec for exposed props/payload, and React test for visible
card content. If the data is not already display-ready, inspect query/presenter
ownership before adding fields.
```

```text
Request: "Change the map zoom buttons."
Use this skill. Treat the shadcn/button wrapper as the visible control layer and
`useExploreMap`/MapLibre as the lifecycle layer. Verify accessible labels and
keyboard/button behavior; use browser smoke if real map integration changes.
```
