## Context

Phase 0 established the Vite/Inertia/React/TypeScript build, an isolated Inertia
root document, shared Tailwind output, and a development/test smoke page. All
production business routes still use the legacy ERB/Turbo/Stimulus layout.

The waterfall detail route is the preferred first production slice under ADR
0005. It is read-only, has no MapLibre lifecycle, and already has request
coverage for public-id lookup and publication boundaries. Its current ERB view
does, however, inherit the legacy application layout, so migrating it also
requires the smallest viable React equivalent of the site header, content
frame, flash region, and document title.

Rails remains responsible for route resolution, published-only selection,
session state, CSRF, I18n, URL generation, and display-value formatting.
Inertia transports explicit props, and React owns the migrated document body.
The Explore route remains legacy, so every current link on the detail page
crosses the runtime boundary.

There are no persistence, authorization-policy, PostGIS query, background job,
retry/idempotency, or external-service changes. No dependency is added.

## Goals / Non-Goals

**Goals:**

- migrate `WaterfallsController#show` and its existing public URL to an Inertia
  React page without changing lookup or publication behavior;
- preserve the current waterfall name, region, summary, description, detail
  attributes, back action, responsive layout, and Digital Naturalist styling;
- introduce a minimal typed React application shell that preserves current
  guest/authenticated header behavior and accessible flash rendering;
- keep shared props small, namespaced, translated, URL-explicit, and free of
  sensitive session or model data;
- prove the first production route through request, component, accessibility,
  and browser tests;
- remove the temporary smoke surface once its runtime proof is superseded.

**Non-Goals:**

- migrate Explore, MapLibre, authentication, dashboard, or any other route;
- redesign waterfall detail or create speculative detail-page components;
- add editing, saving, reviews, photos, or other waterfall interactions;
- introduce SSR, a UI kit, client-side route generation, global state, or a
  general request/query library;
- change waterfall models, scopes, URLs, publication rules, or database access.

## Decisions

### Use inherited, namespaced Inertia shared data for the React shell

`ApplicationController` will expose a lazy `shell` shared prop for Inertia
responses. It contains only:

- translated brand, navigation, and action labels;
- Rails-generated Explore, sign-in, and dashboard URLs;
- an authenticated boolean sufficient to select the existing header action.

CSRF metadata remains in the root document. Page-specific waterfall data stays
in the action response instead of shared data. Standard `notice` and `alert`
messages use Inertia Rails flash data and are read from `page.flash`.

This follows the adapter's inherited `inertia_share` mechanism and keeps shared
payload growth visible. Passing shell data manually from each controller was
rejected because it would duplicate a cross-page contract immediately.
Serializing the current user was rejected because the header needs only an
authentication state and target URL.

### Add a minimal application-owned React shell, not a component library

The first migrated page will use typed React components for:

- `AppShell`, which owns the site shell, document title, header, flash region,
  and content frame;
- `SiteHeader`, which ports the current header structure and stable CSS hooks;
- `Flash`, which ports current notice/alert accessibility semantics.

These are application primitives directly required by the route. The waterfall
detail composition remains feature-owned. General button, card, typography, or
data-list abstractions are deferred until a second React consumer demonstrates
stable reuse.

Adopting a UI kit now was rejected by ADR 0005 because framework migration and
component-system replacement would make parity regressions harder to isolate.

### Send display-ready, page-specific waterfall props

`WaterfallsController#show` continues to load through
`Waterfall.with_public_spot_data` and the public-id prefix. It serializes an
explicit contract containing:

- identity needed by the page, such as the public id;
- name, region name, optional summary, and optional description;
- a compact ordered list of present detail facts with translated labels and
  Rails-formatted values;
- translated page actions and the Rails-generated Explore URL.

Rails formats values such as height, seasonality, difficulty, and plunge-pool
labels so React does not duplicate I18n or domain presentation rules. The
frontend receives no Active Record serialization, coordinates, unpublished
state, session records, credentials, or policy internals.

Using broad `as_json` model payloads was rejected because it makes accidental
exposure and future coupling likely. Recreating translations or enum
humanization in TypeScript was rejected because Rails is the localization
source of truth.

### Treat all current shell and detail links as cross-runtime document visits

Explore, sign-in, and dashboard remain legacy routes in this phase. The React
shell and detail page therefore render normal anchors for those destinations,
not Inertia `Link` components. This intentionally performs a full document
visit and prevents Inertia from assuming ownership of a legacy response.

The component API can distinguish Inertia-owned links later when a second
production route migrates. Building a route registry or automatic ownership
detector now would be speculative.

### Replace the smoke proof after the production route is green

The smoke route, controller, page, translations, and dedicated tests remain
until waterfall request, component, and browser tests prove the production
chain. They are then removed in the same change. The general frontend tooling
and runtime-contract specs remain.

Keeping the smoke page permanently was rejected because it would be a
non-product route with duplicate coverage and ongoing maintenance cost.

### Preserve current error and asset behavior

Draft and missing waterfalls continue to raise not found before an Inertia page
is rendered. The Inertia root document retains localized `noscript` content and
same-origin production assets. Development-only Vite websocket allowances
remain environment-scoped.

No canonical redirect is introduced for stale slugs because the current
baseline explicitly renders by public-id prefix.

## Risks / Trade-offs

- [React header drifts from the legacy header] -> Port the current DOM hooks,
  labels, action rules, and CSS classes; cover guest and authenticated states
  in component and browser tests.
- [Shared props become an accidental global API] -> Namespace under `shell`,
  expose only labels, URLs, and an authentication boolean, and assert the exact
  response shape and excluded sensitive keys.
- [Rails and React disagree on optional values] -> Use explicit nullable
  TypeScript fields and let Rails omit absent detail facts from the ordered
  display list.
- [Cross-runtime links are intercepted by Inertia] -> Use normal anchors for
  all destinations that remain legacy and verify the resulting page in a
  browser test.
- [Flash messages reappear from history state] -> Use Inertia Rails flash data
  rather than regular shared props.
- [Visual parity is subjective] -> Preserve existing classes and content,
  compare desktop and mobile browser renders, and avoid unrelated polish.
- [Removing smoke loses diagnostic coverage] -> Remove it only after the
  production detail request and browser tests cover Rails-to-Inertia-to-React.
- [CSR removes the old server-rendered fallback] -> Keep the localized root
  `noscript` message; SSR remains deferred under ADR 0005.

## Migration Plan

1. Add failing request specs for Inertia component selection, exact page and
   shell props, guest/authenticated state, published-only lookup, and excluded
   sensitive values.
2. Add failing React tests for the shared shell/header/flash behavior and
   waterfall detail rendering, optional fields, document title, keyboard
   navigation, and automated accessibility checks.
3. Add shared prop types and the minimal shell components.
4. Convert `WaterfallsController#show` to the Inertia response and add the
   feature-owned waterfall detail page.
5. Preserve the existing route while removing the obsolete ERB show template.
6. Add or update Selenium coverage for desktop/mobile rendering and a full
   document transition back to legacy Explore.
7. Remove the smoke surface and replace its tooling/runtime assertions with the
   production detail proof.
8. Run narrow Rails and frontend tests, visual browser comparison,
   `make verify-fast`, then `make verify`.

Rollback restores the ERB show response and template and removes the new detail
page. Shared shell components may be removed with it because no other
production Inertia route exists yet. No data or route migration is required.

## Open Questions

- After two or three production React pages, what measured frontend coverage
  threshold provides useful enforcement without encouraging low-value tests?
- Which stable shell primitives, if any, should be promoted beyond
  application-owned components before the future admin UI toolkit evaluation?

An additional ADR is intentionally unnecessary: ADR 0005 already owns the
stack, Rails/React boundary, route-level migration, CSR delivery, shared design
foundation, and deferred UI-kit decision.
