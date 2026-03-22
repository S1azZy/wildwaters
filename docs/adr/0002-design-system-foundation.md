# ADR 0002: Design System Foundation

- Status: Accepted
- Date: 2026-03-22

## Context

Wild Waters now has a working map-first waterfall explore experience, but the UI is still an MVP surface rather than a coherent site-wide design system.

The target direction is no longer a generic outdoor app or a purely atmospheric travel page.
The product needs a design language that combines:

- the map-first clarity of `AllTrails`-style browse flows
- a premium editorial nature tone
- a reusable component system that can scale across the full site

Reference inputs used for this decision:

- the `explore_map_new_typography` screen reference
- the `evergreen_trail/DESIGN.md` system notes
- the Evergreen Trail token and component board

These references converge on one clear direction:

- product UI must feel calm, refined, and map-native
- the interface must use layered surfaces instead of hard separators
- typography and color must feel premium and nature-rooted
- recurring UI should be standardized as explicit components, not ad hoc page markup

Project constraints:

- Rails 8.1 monolith with ERB, Tailwind, Hotwire, and importmap
- bilingual `ru` / `en` UI
- map-first public product
- the team wants a mature, system-driven frontend, not isolated page-level styling
- `app/components` may be used only after an explicit project decision

## Decision

Adopt a formal design-system foundation for Wild Waters.

This decision includes four concrete commitments:

1. Use a single visual north star:
   - `Digital Naturalist`
   - map-first product UX with high-end editorial nature tone

2. Standardize the site around shared design tokens:
   - color roles
   - typography scale
   - spacing and radii
   - surface hierarchy
   - control states

3. Adopt a component-based UI layer for reusable product primitives:
   - use `ViewComponent` for shared UI primitives and app-shell elements
   - keep page composition in Rails views, but do not keep rebuilding buttons, fields, nav items, cards, or badges ad hoc

4. Treat the design system as infrastructure:
   - tokens live in dedicated frontend assets
   - components live in dedicated component directories
   - page refactors must consume the system instead of inventing local styles

## Visual North Star

Wild Waters should feel like:

- a serious map-based discovery product
- a premium outdoor editorial brand
- a calm, layered interface with natural light and air

Wild Waters should not feel like:

- a generic SaaS dashboard
- a stock Tailwind UI kit
- a dark, dramatic landing page pretending to be a product
- a direct clone of `AllTrails`

The guiding formula is:

- structure and browse clarity close to `AllTrails`
- visual tone closer to a premium nature journal

## Core Design Principles

### 1. Map-first clarity

The map remains the product hero.
Search, filters, and results support the map rather than compete with it.

### 2. Tonal layering over hard lines

Default sectioning should come from:

- background shifts
- depth
- spacing
- transparency

Avoid visible containment by default.
Use borders only when they are truly needed for accessibility or interaction clarity, and then prefer low-contrast ghost borders.

### 3. Intentional asymmetry

Layouts should feel curated rather than mechanically even.
Large surfaces may use uneven air, offset content groupings, and floating panels when that improves hierarchy.

### 4. Nature-rooted premium tone

The interface should feel grown, quiet, and tactile:

- forest greens
- alpine and river blues
- warm stone and sand accents
- soft neutrals instead of stark black/white contrast

### 5. Consistency before novelty

Every recurring UI pattern must have one canonical implementation.
Visual variety should come from content, scale, and composition, not from random component restyling.

## Design Tokens

### Color roles

Canonical semantic palette:

- `primary`: forest action green `#2C5601`
- `primary-strong`: deep forest green `#1D3D00`
- `secondary`: alpine lake blue `#3E7B91`
- `tertiary`: warm sand accent `#FFE8CC`
- `neutral-strong`: ink neutral `#111827`

Supporting interpretation:

- `primary` is for main actions, active nav, selected states, and success-leaning product accents
- `secondary` is for water-oriented accents, alternative controls, and informational emphasis
- `tertiary` is for warm editorial support, ambient accents, and softer lifestyle framing
- `neutral` anchors text, deep surfaces, and structural contrast

The system must define tonal ramps for each semantic family rather than single hex values.

Minimum token families:

- `primary-50` through `primary-900`
- `secondary-50` through `secondary-900`
- `tertiary-50` through `tertiary-900`
- `neutral-50` through `neutral-950`

### Surface tokens

Surface hierarchy should be explicit and reusable:

- `surface-base`
- `surface-subtle`
- `surface-raised`
- `surface-overlay`
- `surface-inverse`

Default usage:

- page background uses `surface-base`
- secondary sections use `surface-subtle`
- cards use `surface-raised`
- floating map panels, nav bars, and popovers use `surface-overlay`

### Typography

Adopt this type pairing:

- `Plus Jakarta Sans` for display and headline roles
- `Inter` for body, labels, metadata, and UI text

Canonical text roles:

- `display`
- `headline`
- `title`
- `body`
- `label`
- `caption`

Rules:

- do not mix serif editorial headings with sans product headings in the same system
- body copy and metadata should remain clean and highly legible
- secondary text should use toned-down neutral values, not opacity hacks by default

### Shape and spacing

The system should prefer soft geometry:

- `radius-sm`: small control rounding
- `radius-md`: inputs and compact buttons
- `radius-lg`: cards
- `radius-xl`: large image containers and map panels
- `radius-pill`: badges, pills, and primary CTA buttons

Spacing must follow a single scale and be reused across:

- shells
- cards
- form rows
- map control offsets

### Elevation

Depth comes from:

- tonal contrast
- blur
- soft ambient shadow

Avoid harsh drop-shadow stacks.
When shadows are needed, use broad, low-opacity, tinted shadows.

## Component Strategy

Wild Waters explicitly adopts `ViewComponent` for reusable UI primitives and app-shell pieces.

This is now an approved project decision.

### Why

The site needs:

- a unified header and footer
- canonical buttons and fields
- reusable filter chips and badges
- reusable result cards
- consistent popovers, menus, and map controls
- previews and tests for shared UI

This is a strong fit for `ViewComponent` because the goal is not just reuse, but controlled, testable, inspectable UI APIs.

### Boundaries

Use `ViewComponent` for:

- `SiteHeader`
- `SiteFooter`
- `Button`
- `IconButton`
- `TextField`
- `SelectField`
- `Badge`
- `Card`
- `FilterChip`
- `EmptyState`
- `MapStyleMenu`
- shared map/result cards

Do not move the whole app into components at once.
Pages should remain page-level ERB compositions that assemble shared components.

## Token Storage and Frontend Structure

The design system must have explicit storage layers.

### Canonical token storage

Create a dedicated token source in frontend assets.

Recommended shape:

- CSS custom properties for canonical design tokens
- Tailwind theme mappings that consume those variables

The source of truth should be semantic tokens, not raw utility literals spread across templates.

Target structure:

- `app/assets/stylesheets/design_tokens.css`
- `app/assets/stylesheets/components/`
- `app/components/`
- `spec/components/` or component previews/tests as adopted

### Rules

- do not hardcode one-off hex values in page templates once tokens exist
- do not invent page-local button styles
- do not create separate visual systems per feature
- map UI must use the same tokens as the rest of the product

## Interaction and UI Rules

### Header and shell

The site should use one canonical global header across public product pages.

The header must feel:

- light
- calm
- premium
- product-native

### Search and filters

Search and filter controls should be:

- compact
- rounded
- quiet by default
- visually secondary to results and the map

### Cards and lists

Cards must not be separated by divider lines.
Use surface shifts and spacing instead.

### Map controls

Map controls should be glassy, light, and soft-edged.
They should float on the map without making the experience feel like GIS software.

## Alternatives Considered

### Keep the current bespoke Tailwind approach

Rejected because it encourages page-level drift and repeated local decisions.
It is acceptable for MVP slices, but not for a site-wide mature design system.

### Build the system with partials only

Rejected as the primary long-term direction.
Partials are useful for simple extraction, but they do not provide enough API discipline for a growing shared UI library.

### Copy the current reference literally

Rejected because Wild Waters needs its own brand character.
The references provide structure and direction, not a mandate for pixel-for-pixel imitation.

## Consequences

Benefits:

- shared visual language across all product surfaces
- lower UI drift over time
- cleaner future redesigns because tokens and components become explicit infrastructure
- easier onboarding for future design and frontend work
- a clearer path from MVP explore UI to a complete product shell

Trade-offs:

- higher upfront design-system cost before broad feature work
- more discipline required in reviews
- introducing `ViewComponent` adds a new frontend abstraction layer that the team must use consistently

## Implementation Notes

Implementation should happen in phases.

### Phase 1: token foundation

- introduce canonical design tokens
- wire Tailwind/theme usage to semantic tokens
- add typography roles
- define surface, radius, and shadow tokens

### Phase 2: core shared components

- global header
- footer if kept
- button family
- inputs and selects
- badges and chips
- card surfaces

### Phase 3: explore page refactor

- rebuild the explore page on top of the new tokens and components
- preserve map-first behavior
- bring layout closer to the approved target concept

### Phase 4: broader site adoption

- waterfall detail page
- auth pages
- dashboard/profile surfaces
- future social/product pages

This ADR fixes the design-system foundation decision, not the full implementation of every page.
