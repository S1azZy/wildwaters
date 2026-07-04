## Context

Wild Waters is a Rails monolith whose application-owned business frontend uses
Vite, Inertia Rails, React, strict TypeScript, and Tailwind under ADR 0005.
ADR 0002 owns the Digital Naturalist visual language and token vocabulary. The
current React UI has application-owned shell, auth form, dashboard, waterfall
detail, and Explore map components, but controls are still mostly page-local
Tailwind/CSS rather than a kit-backed component system.

This change adopts shadcn/ui after the framework migration is complete. It is
not a second frontend framework and does not move route, form submission,
authorization, I18n, or domain ownership out of Rails/Inertia.

## Goals / Non-Goals

**Goals:**

- Install and configure shadcn/ui for the existing Vite/Tailwind project.
- Establish a kit-first component policy for business and future admin UI.
- Keep shadcn generated primitives separate from Wild Waters product
  compositions.
- Preserve the map-first Explore shape while restyling filters, cards, panels,
  and controls with shadcn-backed primitives.
- Refresh auth forms, the dashboard placeholder, shared shell controls, and
  waterfall pages enough that the kit is proven on real screens.
- Create durable docs for the frontend design workflow and component-selection
  rules.

**Non-Goals:**

- Replacing Inertia/Rails ownership of routes, URLs, I18n, CSRF, sessions, or
  authorization.
- Changing MapLibre loading, map data payloads, clustering, or PostGIS query
  behavior.
- Building the future admin import operations feature.
- Adopting SSR, a separate SPA/API, a global query client, or route generation.
- Pixel-matching AllTrails or using third-party assets as implementation input.

## Decisions

### Adopt shadcn/ui as source-owned primitives

Use shadcn/ui because it provides accessible, attractive defaults while copying
component source into the application. That matches the project preference for a
pleasant pet-project UI without a designer, but avoids locking Wild Waters into
a fully opinionated product kit.

Alternatives considered:

- HeroUI: more complete out of the box, especially for tables, but it is a
  runtime library with stronger vendor API ownership and less source-level
  control over the AllTrails-inspired map-first composition.
- Radix Themes/Primitives directly: strong accessibility foundation, but too
  low-level for the desired implementation speed. shadcn already gives a
  practical Radix-backed recipe layer.

### Keep three frontend component layers

- `app/frontend/components/ui`: shadcn-generated primitives and only their
  direct support files.
- `app/frontend/components/ww`: Wild Waters reusable compositions built from
  shadcn primitives, such as `FormField`, `SubmitButton`, `PageHeader`,
  `FilterTrigger`, `MapControlButton`, `WaterfallCard`, `EmptyState`,
  `DataTable`, and `AdminToolbar`.
- `app/frontend/pages/**`: route orchestration and feature-specific layout.

Existing shell components may migrate gradually into this shape. The first
implementation wave should not move files solely for cosmetic directory
neatness; it should create the boundary for new and migrated controls, then
move only where it reduces confusion.

### Use kit primitives first, then compositions, then custom controls

Development order for UI work:

1. Use an existing shadcn component or block.
2. Compose a Wild Waters wrapper around shadcn primitives when the product has
   a repeated concept or repeated state contract.
3. Create a fully custom component only when no shadcn primitive can express
   the required semantics, behavior, or map-specific layout.

Fully custom map rendering and MapLibre lifecycle remain allowed because the UI
kit does not own map engines or geospatial behavior.

### Map shadcn tokens to Digital Naturalist

The implementation should configure shadcn with the existing Tailwind 4 and
`@/*` alias setup. Shadcn semantic colors should map back to Digital Naturalist
rather than creating a second palette. The canonical token source remains
`app/frontend/styles/design_tokens.css`; the global Tailwind/shadcn entrypoint
remains `app/frontend/entrypoints/application.css`.

The first shadcn theme pass should prioritize:

- forest/water primary and secondary surfaces;
- white/raised floating panels for map and admin UI;
- soft but restrained radii;
- accessible focus rings and invalid states;
- light mode only unless a later change introduces dark mode.

### Store durable guidance in docs plus ADR

Create a new ADR for the architectural decision to adopt shadcn/ui and its
component ownership boundaries. Create a working frontend design guide at
`docs/frontend/DESIGN_GUIDE.md` and route future UI-kit/design-system work to
it from `docs/CONTEXT_MAP.md`.

The ADR owns the durable decision. The design guide owns day-to-day workflow:
design intent first, token/component selection second, page implementation
third, with shadcn-first component selection.

### Preserve Explore map behavior while refreshing UI chrome

The Explore screen can visually move closer to an AllTrails-inspired pattern:

- full-screen MapLibre canvas remains the primary surface;
- desktop result rail remains a docked/floating panel;
- filters become shadcn-backed pill/dropdown/popover controls;
- result cards become shadcn-backed Wild Waters cards;
- map control buttons become shared icon-button compositions;
- mobile keeps a map/list-first shape and avoids hiding the map behind
  unrelated page content.

No map query, payload, clustering, or provider behavior changes belong in this
change.

## Migration Plan

1. **Planning and docs:** create OpenSpec artifacts, ADR, design guide, context
   map updates, and `CHANGES.md` entry.
2. **Tooling foundation:** initialize shadcn for the existing Vite project,
   commit `components.json`, generated support files, locked npm dependency
   updates, and the initial component inventory.
3. **Shared primitives:** add Wild Waters wrappers for buttons, fields, badges,
   cards, empty states, icon actions, page headers, and feedback.
4. **Auth and shell migration:** refresh auth forms and shell controls with
   shadcn-backed fields/buttons/cards while preserving Inertia `useForm`,
   Rails-generated URLs, translated copy, and flash semantics.
5. **Public waterfall migration:** refresh waterfall detail cards/facts and
   Explore filter/result/map-control chrome while preserving MapLibre behavior.
6. **Admin readiness pass:** add minimal table, toolbar, pagination, dialog,
   and sheet compositions needed before future admin screens.
7. **Verification and cleanup:** update tests, remove superseded local CSS
   only after replacement coverage exists, run frontend gates and applicable
   project verification.

Rollback strategy: shadcn adoption is source and dependency based. If a
component migration causes regression, revert the page-level wrapper migration
while leaving the installed kit foundation in place. If dependency installation
or audit fails, do not migrate UI surfaces until the dependency graph is
resolved.

## Risks / Trade-offs

- [Package graph grows] -> Keep the initial component inventory focused, run
  dependency audit, and avoid adding community registry components in the first
  wave.
- [Local shadcn edits diverge from upstream] -> Prefer Wild Waters wrappers for
  product styling and edit generated primitives only for stable theme/variant
  needs.
- [Tailwind class sprawl continues] -> Document the rule that `className` is
  for layout/composition and repeated visual contracts move into wrappers or
  shadcn variants.
- [Explore map regression] -> Keep MapLibre lifecycle and payload code out of
  scope; verify with component/browser smoke focused on map presence, filters,
  result cards, and responsive controls.
- [Auth behavior regression] -> Preserve Inertia `useForm`, Rails URLs, CSRF,
  translated props, and existing request/component coverage while replacing
  only visual primitives.
- [Design guide becomes stale] -> Route UI-kit work through
  `docs/CONTEXT_MAP.md` and make `CHANGES.md` updates required for process or
  design-system changes.
