# Frontend Design Guide

This guide owns the working frontend design process for Wild Waters. ADR 0002
owns the durable Digital Naturalist visual direction, ADR 0005 owns the
Inertia React frontend architecture, and ADR 0006 owns the shadcn/ui component
foundation.

## Design Workflow

Use this order for application-owned business and admin UI:

1. Define the screen intent and user task.
2. Choose the page structure and responsive behavior.
3. Select existing Digital Naturalist tokens and shadcn primitives.
4. Add or reuse Wild Waters wrappers for repeated product concepts.
5. Compose the page from typed React components and Rails-provided Inertia
   props.
6. Verify behavior, accessibility, visual states, and production build output.

Avoid starting from page-local Tailwind classes when the interface needs a
standard button, field, card, table, overlay, empty state, feedback message, or
navigation control.

## Visual Direction

Wild Waters should feel like a calm, map-first nature guide:

- map and outdoor content are the primary surfaces;
- controls should be clear, compact, and touch-friendly;
- panels should feel light, raised, and readable over maps;
- hierarchy should come from spacing, type, surface, and elevation before heavy
  borders;
- colors should stay rooted in forest, water, stone, and warm trail tones;
- public screens may be more editorial, while admin screens should be denser
  and quieter.

AllTrails-style map-first exploration is inspiration for layout patterns, not a
pixel-matching target.

## Component Layers

Use the layers defined by ADR 0006:

- `app/frontend/components/ui`: shadcn-generated primitives and direct support
  files.
- `app/frontend/components/ww`: Wild Waters wrappers and reusable product
  compositions.
- `app/frontend/pages/**`: route orchestration, page-specific layout, and
  feature-local components that are not stable shared concepts yet.

Page files should stay as route-level orchestration. Move repeated or visually
distinct regions into typed components, and move browser lifecycle concerns
into hooks when that keeps the page readable.

## Shadcn-First Rule

For every new or migrated control:

1. Prefer an installed shadcn primitive and built-in variant.
2. Install another official shadcn primitive when the product need is current
   and the component is a good semantic match.
3. Compose a Wild Waters wrapper when the same product concept or state contract
   appears in more than one place.
4. Build a fully custom component only when shadcn cannot express the required
   semantics, behavior, or map-specific layout.

Custom components are allowed for MapLibre canvas integration and other
behavior that a UI kit does not own. The reason should be clear from the
component name, nearby test, or design note.

## Tokens And Styling

The executable token source remains
`app/frontend/styles/design_tokens.css`, loaded through
`app/frontend/entrypoints/application.css`.

Use shadcn semantic colors, radii, focus rings, invalid states, and variants as
the component API. Map those semantics back to Digital Naturalist tokens rather
than introducing raw one-off color ramps.

Prefer `className` for layout and local composition. When the same visual state
or product concept repeats, promote it into a wrapper, variant, or token.

Current default:

- light mode only;
- forest/water primary actions;
- white or raised surfaces for floating map/admin panels;
- restrained radii and shadows;
- accessible focus and invalid states.

## Current Starter Inventory

The first shadcn inventory should cover:

- actions: buttons, icon buttons, dropdown actions;
- forms: labels, fields, inputs, textarea, select, checkbox, radio, switch,
  validation states;
- surfaces: cards, badges, separators, scroll areas;
- overlays: dialog, sheet, drawer, popover, tooltip;
- feedback: alert, toast, skeleton, spinner/progress;
- navigation: tabs, pagination, breadcrumbs where useful;
- data: table scaffolding for admin screens;
- media/result cards: carousel or image-card support when a current screen
  needs it.

Do not add community registry components in the first wave unless a separate
approved change chooses that dependency.

## Rails, I18n, And Tests

Rails continues to own routes, URLs, translated copy, form endpoints, sessions,
CSRF, authorization, and data selection. React components should receive typed
props and submit through the existing Inertia/Rails contracts.

Add or update tests when a component owns behavior, accessibility semantics,
state transitions, validation display, or a public prop contract. Pure visual
replacement can use the narrowest relevant component or browser smoke check.
