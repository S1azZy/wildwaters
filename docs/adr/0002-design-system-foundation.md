# ADR 0002: Design System Foundation

- Status: Accepted
- Decided: 2026-03-22
- Normalized to implementation: 2026-06-13
- Partially superseded: ADR 0005 replaces the ERB/ViewComponent implementation
  boundary for migrated routes; this ADR continues to own Digital Naturalist
  and its token vocabulary.

## Context

Wild Waters needs a coherent visual language across public discovery and
authentication screens without replacing Rails views with a client-side UI
framework.

The application uses ERB, Tailwind CSS, Hotwire, and bilingual `ru`/`en` copy.
Some UI patterns are stable and shared, while page composition and map-specific
markup remain feature-owned.

## Decision

Adopt a design system called **Digital Naturalist** and implement it with
semantic Tailwind tokens plus a selective ViewComponent layer.

### Visual direction

Digital Naturalist combines map-first product clarity with the calm, editorial
character of a premium nature guide. It is intentionally neither a generic
SaaS dashboard nor a visual copy of another outdoor product.

The durable principles are:

- the map is the primary discovery canvas, with controls and results layered
  around it instead of competing with it;
- tonal surfaces, spacing, and elevation create hierarchy before hard borders
  do;
- the palette is rooted in forest, water, stone, and warm trail tones;
- geometry is soft and confident, using generous radii and restrained shadows;
- typography separates expressive display hierarchy from highly readable body
  copy;
- shared patterns should become more consistent before new one-off variants are
  introduced.

Intentional asymmetry is allowed where it supports the map, results rail, or
editorial hierarchy. It is not a reason for inconsistent component states.

### Token foundation

The executable token catalog lives in
`app/frontend/styles/design_tokens.css` and is loaded through
`app/frontend/entrypoints/application.css`.

The canonical families are:

- display type: `Plus Jakarta Sans`;
- body type: `Inter`;
- primary forest green anchored at `#2c5601`;
- secondary water blue anchored at `#3e7b91`;
- tertiary warm sand anchored at `#ffe8cc`;
- neutral ink anchored at `#111827`;
- semantic danger, success, and information colors;
- base, subtle, raised, overlay, and inverse surfaces;
- `sm`, `md`, `lg`, `xl`, and pill radii;
- ambient and floating elevation shadows.

The token file is the exact source of truth for ramps and values. Changing a
single shade is a design-system maintenance change; replacing the vocabulary,
typography, or visual direction is an architecture change and must update this
ADR.

### Rendering and component boundary

- ViewComponent owns reusable UI primitives and application-shell elements on
  unmigrated legacy routes;
- page structure and feature-specific composition remain in ERB views until a
  route migrates under ADR 0005;
- migrated routes port stable primitives into application-owned typed React
  components while preserving this token vocabulary;
- Stimulus owns focused interaction behavior without becoming a second
  rendering architecture;
- user-facing component and page copy is provided through Rails I18n;
- component extraction is driven by stable reuse, not by a requirement to turn
  every partial or page fragment into a component.

The shared component layer covers the application shell, authentication shell,
buttons, icon actions, fields, badges, cards, filter chips, flash messages, and
empty states. This list describes the current implementation, not a closed
component inventory.

Feature pages may use local Tailwind composition where no stable shared API has
emerged. Existing raw utility colors do not invalidate the token system, but a
new reusable concept should use or extend semantic tokens instead of creating a
parallel palette.

## Alternatives Considered

### Page-local Tailwind only

This keeps each page independent but duplicates primitives and makes shared
states difficult to test consistently.

### Componentize complete pages

Moving complete screens into components would add indirection without changing
the Rails page-composition model.

### Adopt a client-side component framework

The current interaction model is covered by ERB, Hotwire, Stimulus, and
ViewComponent. A second frontend application architecture is not justified.

## Consequences

- Shared primitives have explicit Ruby APIs and component specs.
- Semantic tokens provide a common vocabulary without forbidding all local
  utility classes.
- The design system is intentionally hybrid: shared primitives are components,
  while feature composition remains close to its Rails view.
- Visual review must check both component consistency and the Digital Naturalist
  direction; component reuse alone is not sufficient.
- New shared primitives should follow existing component and token patterns.
- A broad redesign or a different frontend framework would require a separate
  architecture decision.
