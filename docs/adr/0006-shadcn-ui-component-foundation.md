# ADR 0006: Shadcn UI Component Foundation

- Status: Accepted
- Decided: 2026-06-26
- Implementation: `openspec/changes/adopt-shadcn-ui`
- Supersedes: the deferred UI-kit evaluation note in ADR 0005
- Partially supersedes: ADR 0002's custom React primitive implementation
  boundary while preserving Digital Naturalist as the visual language

## Context

Wild Waters is a Rails monolith whose application-owned business frontend uses
Vite, Inertia Rails, React, TypeScript, and Tailwind under ADR 0005. The
current public and authenticated pages share the Digital Naturalist visual
direction from ADR 0002, but many controls are still page-local Tailwind
compositions.

The project is expected to grow into a richer public product and an
application-owned admin interface. There is no dedicated product designer, so
the frontend needs an attractive, accessible, repeatable component foundation
that is faster than hand-tuning every button, form, card, table, and overlay.

## Decision

Adopt shadcn/ui as the preferred component foundation for application-owned
business and admin React interfaces.

### Component ownership

The frontend has three component layers:

- `app/frontend/components/ui` contains shadcn-generated primitives and their
  direct support files.
- `app/frontend/components/ww` contains Wild Waters product compositions built
  from shadcn primitives.
- `app/frontend/pages/**` contains route orchestration and feature-specific
  layout.

Generated shadcn primitives are source-owned by the application, but product
styling and domain-specific behavior should normally live in Wild Waters
wrappers rather than by repeatedly editing generated primitive internals.

### Development order

Frontend work should choose UI building blocks in this order:

1. Use an existing shadcn primitive, variant, or documented composition.
2. Add or reuse a Wild Waters wrapper when a product concept or state contract
   repeats.
3. Create a fully custom control only when no shadcn primitive can express the
   required semantics, behavior, or map-specific layout.

MapLibre rendering, map lifecycle, and geospatial data behavior remain
feature-owned. The UI kit owns visible controls and compositions around the
map, not the map engine.

### Design and token ownership

Digital Naturalist remains the visual north star. Shadcn semantic tokens,
states, and component variants must map back to the existing Wild Waters token
vocabulary instead of introducing a second palette.

The executable token source remains:

- `app/frontend/styles/design_tokens.css`
- `app/frontend/entrypoints/application.css`

The working design process lives in `docs/frontend/DESIGN_GUIDE.md`. ADR 0002
continues to own the durable visual vocabulary; this ADR owns the UI-kit and
component-layer decision.

### Rails and Inertia boundary

This decision does not move routing, sessions, CSRF, authorization, I18n,
business use cases, form submission ownership, or data selection out of Rails.
Inertia remains the page-delivery protocol, and React continues to own
rendering and local interaction state for migrated business routes.

## Alternatives Considered

### HeroUI

HeroUI offers a broad runtime component library and many polished primitives,
including admin-friendly surfaces. It was not selected because Wild Waters
benefits more from source-owned components that can be adapted directly to the
map-first product shell and existing Tailwind token vocabulary.

### Radix Themes or Radix Primitives directly

Radix is an excellent accessibility foundation, but direct Radix adoption would
leave more visual composition work to the project. Shadcn provides a practical
Radix-backed recipe layer while still keeping component source in the
repository.

### Continue with page-local Tailwind and custom React primitives

This keeps dependencies smaller, but it would continue the current pattern of
duplicated buttons, cards, fields, filters, and empty states. That is too slow
and brittle for the planned public and admin UI growth.

## Consequences

- shadcn-generated source and its locked npm dependency graph become
  first-class frontend build inputs.
- Shared business/admin UI should be kit-first unless a documented component
  boundary explains why a custom control is needed.
- The project gains an explicit Wild Waters composition layer for repeated
  product concepts such as form fields, map controls, result cards, page
  headers, feedback, empty states, admin toolbars, and tables.
- Updating shadcn components requires source review because generated files are
  local application code.
- ADR 0002 remains the source for Digital Naturalist; this ADR changes the
  implementation foundation from custom-only React primitives to shadcn-backed
  primitives plus Wild Waters wrappers.
- ADR 0005 remains the source for the Inertia React frontend architecture; this
  ADR resolves its deferred UI-kit decision.
