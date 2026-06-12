---
name: wildwaters-waterfall-ui
description: Use this skill when changing Wild Waters public waterfall browse or detail UI, explore map UI, waterfall filters, ERB/Hotwire/Tailwind views, UI components used by waterfall pages, or bilingual waterfall-facing copy.
---

# Wild Waters Waterfall UI

## When to use

Use for public waterfall browse/detail pages, map-first explore UI, filters, result rails, waterfall cards, ERB/Hotwire/Tailwind presentation, related UI components, and `ru`/`en` waterfall-facing copy.

Do not use for generic backend-only query changes unless they alter the UI contract.

## Read

- `docs/DEVELOPMENT.md` UI-only and behavior-changing loops.
- `docs/CONTEXT_MAP.md` rows for waterfall pages, explore map UI, UI components, styles/design tokens, Stimulus behavior, and I18n copy as applicable.
- `docs/FOUNDATIONS.md` product boundary for waterfall-first MVP behavior.
- The target view/component/controller/presenter/query and matching request/system/component spec.
- `config/locales/en.yml` and `config/locales/ru.yml` only when user-facing text changes.
- `docs/adr/0001-map-browse-stack.md` only when changing MapLibre map behavior.
- `docs/adr/0002-design-system-foundation.md` only when changing shared component/design-system patterns.

## Do not read by default

- Imports ADRs.
- Security docs unless the UI exposes protected, private, admin, or user-owned resources.
- All locale files beyond `en` and `ru`.
- Every UI component; inspect only the target component and one neighbor.

## Procedure

1. Decide whether the change is UI-only visual polish or behavior-changing UI.
2. Preserve waterfall-first MVP behavior; do not add generic outdoor or future spot-type UX without explicit approval.
3. Keep controller logic thin; use presenters/queries/interactors according to existing patterns.
4. Add both `ru` and `en` locale entries for new user-facing text.
5. For behavior changes, write or update the relevant request/system/component spec first.
6. For visual-only polish, edit the smallest surface and verify with the narrowest relevant check or browser pass.
7. Keep map payload and UI state lean; do not add explanatory in-app text about implementation details.
8. Update `CHANGES.md` for user-facing behavior or process changes.

## Outputs

```text
Loaded:
Skipped:
Change kind:
UI contract:
Locale keys:
Spec/browser check:
Verification:
Open question:
```

## Token economy

- Read one vertical slice: view/component, caller, presenter/query, and matching spec.
- Use `rg "waterfalls|map_data|explore|t\\(|I18n"` to locate exact touchpoints.
- Open locale keys by path/search, not the whole file when possible.
- Summarize screenshots or browser observations rather than pasting large DOM snapshots.
