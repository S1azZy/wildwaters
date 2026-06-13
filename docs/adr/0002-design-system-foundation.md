# ADR 0002: Design System Foundation

- Status: Accepted
- Decided: 2026-03-22
- Normalized to implementation: 2026-06-13

## Context

Wild Waters needs a coherent visual language across public discovery and
authentication screens without replacing Rails views with a client-side UI
framework.

The application uses ERB, Tailwind CSS, Hotwire, and bilingual `ru`/`en` copy.
Some UI patterns are stable and shared, while page composition and map-specific
markup remain feature-owned.

## Decision

Use semantic Tailwind design tokens plus a selective ViewComponent layer.

The implemented boundary is:

- canonical colors, typography, surfaces, radii, and shadows live in
  `app/assets/tailwind/design_tokens.css`;
- Tailwind loads those tokens through `app/assets/tailwind/application.css`;
- ViewComponent owns reusable UI primitives and application-shell elements;
- page structure and feature-specific composition remain in ERB views;
- user-facing component and page copy is provided through Rails I18n;
- component extraction is driven by stable reuse, not by a requirement to turn
  every partial or page fragment into a component.

The component layer currently applies this boundary to the application shell,
authentication screens, form controls, feedback, and common display
primitives. Feature pages may still use local Tailwind composition where no
stable shared API has emerged.

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
- New shared primitives should follow existing component and token patterns.
- A broad redesign or a different frontend framework would require a separate
  architecture decision.
