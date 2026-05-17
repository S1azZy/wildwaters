# Plan

This document owns current status, delivery phases, roadmap, and deferred work.
Architecture rules live in `docs/FOUNDATIONS.md`; execution workflow lives in
`docs/DEVELOPMENT.md`.

## Current status

Completed:
- Project vision captured
- MVP scope constrained to waterfall-first behavior
- Initial foundations, plan, and quality/security documentation created

Next:
- Phase 1: bootstrap Rails monolith and infrastructure baseline

## MVP baseline

The MVP must deliver a coherent waterfall discovery and social loop:
- Auth and protected user space
- Region hierarchy and waterfall catalog
- Map browsing with waterfall markers
- Waterfall detail pages with structured information
- Photos, reviews, and check-ins
- User profiles and follow graph
- Nearby waterfall discovery
- Basic activity feed
- Achievement groundwork tied to visits/check-ins

## Delivery phases

### Phase 1: foundation
- Create Rails application
- Configure PostgreSQL + PostGIS
- Configure Docker and local dev workflow
- Set up auth
- Create initial domain models
- Set up Active Storage
- Set up admin basics
- Establish API namespace and response conventions
- Add quality/security tooling baseline

### Phase 2: waterfall catalog
#### Iteration 2.1
- Implement region hierarchy
- Implement `Spot` schema with waterfall-first constraints
- Add import-friendly waterfall data model
- Add slugs and public browse paths

#### Iteration 2.2
- Build waterfall CRUD for admin/backoffice
- Build public waterfall index
- Build waterfall detail page
- Expose matching read API endpoints

#### Iteration 2.3
- Integrate MapLibre
- Render waterfall markers on map
- Add nearby waterfall search using PostGIS
- Add request/system coverage for browse and map flows

### Phase 3: social layer
#### Iteration 3.1
- User profiles
- Photo upload flow
- Reviews on waterfall pages

#### Iteration 3.2
- Check-ins with photos
- Follow relationships
- Basic activity feed

#### Iteration 3.3
- Activity aggregation and feed polishing
- API support for social surfaces
- Background jobs for non-critical fan-out work

### Phase 4: gamification
- Achievement definitions
- Visited counts
- Progress tracking
- Lightweight achievement presentation in profile/feed

### Phase 5: mobile prep
- Stabilize JSON API contracts
- Ensure auth flow works for future mobile clients
- Ensure upload flow works for future mobile clients
- Close obvious web/API contract gaps before Flutter work starts

### Phase 6: future expansion
- Add additional `Spot` types incrementally
- Keep waterfalls as the first-class category
- Extend without breaking waterfall-first URLs, API shape, and admin flows

## Post-MVP roadmap
- Native Flutter clients
- Better recommendation/discovery surfaces
- Moderation tooling
- Import pipelines for larger waterfall datasets
- Additional natural swimming spot types

## Parking lot
- Real-time features via Action Cable
- Route planning
- Offline-first sync
- Generic travel-platform features

## Rule
No future-type expansion before the waterfall MVP and its social loop are complete.
