## 1. Lock the Rails and Inertia Response Contract

- [ ] 1.1 Extend `spec/requests/waterfalls_spec.rb` with failing examples that require `Waterfalls/Show`, explicit public waterfall props, translated display facts and actions, the isolated Inertia layout, and the unchanged stale-slug behavior.
- [ ] 1.2 Add failing request examples for the exact guest and authenticated `shell` shared-prop shapes and exclusion of credentials, raw session data, unpublished state, coordinates, model internals, and policy internals.
- [ ] 1.3 Preserve and strengthen the existing draft and missing waterfall examples so they prove `404` responses do not serialize waterfall props or render the Inertia shell.
- [ ] 1.4 Run the narrow waterfall request specs and confirm they fail for the missing Inertia response and shared shell contracts before production code changes.

## 2. Build the Minimal Shared React Shell

- [ ] 2.1 Add failing React Testing Library tests for guest and authenticated header states, brand and Explore navigation, full-document legacy links, document title, allowed flash messages, status/alert semantics, keyboard navigation, and axe-core accessibility.
- [ ] 2.2 Define strict namespaced shared prop and flash types, then add the minimal application-owned `AppShell`, `SiteHeader`, and `Flash` React components using the current DOM hooks, CSS classes, and Digital Naturalist tokens.
- [ ] 2.3 Add lazy inherited `inertia_share` data to `ApplicationController` with only translated shell labels, Rails-generated legacy URLs, and the authentication boolean; keep standard Rails flash in Inertia's page-level flash channel.
- [ ] 2.4 Run the shell component tests, frontend typecheck, frontend lint, and the narrow waterfall request specs until the shared shell contract is green.

## 3. Migrate Waterfall Detail

- [ ] 3.1 Add a failing React Testing Library test for the waterfall detail page covering required content, optional field omission, ordered translated facts, the Explore action, responsive structure, document title, keyboard access, and axe-core accessibility.
- [ ] 3.2 Change `WaterfallsController#show` to render `Waterfalls/Show` with an explicit display-ready prop serializer while retaining `Waterfall.with_public_spot_data` and public-id-prefix lookup.
- [ ] 3.3 Implement the typed feature-owned waterfall detail page inside the shared React shell, preserve the existing content and styling, and use normal anchors for all currently legacy destinations.
- [ ] 3.4 Remove `app/views/waterfalls/show.html.erb` only after the request and component tests pass, then run the narrow waterfall request and frontend component suites.

## 4. Prove the Runtime Boundary and Retire Smoke

- [ ] 4.1 Add or update Selenium system coverage for desktop and mobile waterfall detail rendering, guest and authenticated header parity, and navigation from legacy Explore to React detail and back through full document visits.
- [ ] 4.2 Verify the migrated page loads only the Inertia/Vite runtime while Explore continues to load importmap/Turbo/Stimulus, with no route loading both browser runtimes.
- [ ] 4.3 Remove the development/test smoke route, controller, React page, translations, request/routing/component/browser specs, and any tooling assertions that require the obsolete surface.
- [ ] 4.4 Replace smoke-specific runtime proof with waterfall-detail production-route assertions, then run the narrow request, component, routing/tooling, design-shell, and browser specs.

## 5. Review Exposure, Parity, and Delivery

- [ ] 5.1 Review shared and page-specific Inertia props for accidental secrets, unnecessary user/model data, untranslated copy, duplicated route or domain logic, and history-persisted flash data.
- [ ] 5.2 Compare the legacy and migrated waterfall detail at desktop and mobile widths, including optional-content states, header actions, focus order, accessible names, document title, and the JavaScript-required fallback.
- [ ] 5.3 Run `make verify-fast`, the production Vite build, and `make verify`; record any unrelated blocker exactly.
- [ ] 5.4 Update `CHANGES.md` and any implementation-owned context documentation in a documentation-only branch, preserving the repository's branch separation policy.
- [ ] 5.5 If implementation learning changes intent, requirements, shell ownership, prop exposure, or runtime-boundary design, update these approved OpenSpec artifacts and obtain approval before divergent work continues.
- [ ] 5.6 Invoke `$openspec-verify-change`, run `bin/openspec validate --all --strict`, and archive the change only after implementation and all applicable gates pass.
