# TODO

This document is the ordered queue for known behavior and deferred architecture
or tooling work that is not implemented. It is not a specification and does
not authorize implementation by itself.

Before starting an item:

1. confirm that it still solves a current product or operational problem;
2. create a Level 2 OpenSpec change, or Level 3 plus an ADR when a new durable
   architecture decision is required;
3. remove the item from this file after the change is implemented and archived.

Items are ordered by dependency, expected value, and implementation complexity.
Earlier items should normally be considered before later ones.

## P0: Close Existing Contract Gaps

1. **Restrict automatic region creation to canonical identity sources.**
   The import model prevents a non-canonical source from becoming a primary
   identity, but the apply path can still create a new `Region` for any enabled
   source. Enrichment sources should attach only to an existing match unless a
   separately approved workflow says otherwise.

2. **Add abuse protection to authentication entrypoints.**
   Rate limit sign-in, registration, and password-reset requests without
   revealing account existence or weakening existing session and CSRF
   behavior.

3. **Replace the catalog's fixed first-60 result window with explicit
   pagination or continuation.**
   Keep map payloads bounded, but make the HTML catalog and filtered discovery
   behavior explicit when more than 60 published waterfalls match.

## P1: Complete Core Waterfall Discovery

4. **Add database-backed waterfall and region-name search.**
   The explore search field currently filters only the features already loaded
   in the browser. Search should use first-class waterfall fields and indexed
   `region_names`, while preserving the current map filters.

5. **Add nearby waterfall discovery.**
   Implement an index-backed PostGIS distance query with an explicit radius,
   ordering, result limit, and privacy-safe handling of user-provided
   coordinates.

6. **Add dedicated region browse behavior.**
   Expose useful region hierarchy and region context beyond the current filter
   dropdown. Reuse closure-table traversal and multilingual names rather than
   introducing a second hierarchy model.

## P2: Build the First Account Value Loop

7. **Add a real user profile surface.**
   Define public and private profile fields before expanding the dashboard
   placeholder.

8. **Add saved waterfalls.**
   Provide the smallest authenticated return-value loop before introducing
   public social content.

9. **Add waterfall reviews with explicit ownership authorization.**
    Define publication state, edit/delete permissions, and anti-spam controls
    before exposing reviews publicly.

10. **Add waterfall photos through Active Storage.**
    Define content-type and size validation, publication visibility,
    attribution, and asynchronous derivatives.

11. **Add check-ins with a privacy boundary.**
    Decide timestamp and location precision, public visibility, and ownership
    rules before persistence or feed integration.

12. **Add follows and an activity feed.**
    Build this only after profiles and at least one meaningful activity source
    exist. Paginate the feed and keep authorization explicit.

13. **Add achievements.**
    Treat achievements as a derived layer over stable check-in and activity
    behavior, not as an independent MVP subsystem.

## P3: Improve Import Operations and Coverage

14. **Add an admin import operations surface.**
    Provide source/run/item visibility, sanitized failures, enqueue controls,
    and retry-failed actions behind explicit admin authorization. Use the ADR
    0006 shadcn-backed component layer and reuse the existing import
    interactors rather than shelling out to Make or rake.

15. **Add scheduled GeoNames imports when an operating cadence is known.**
    Scheduled jobs must call the same enqueue interactor and use persisted run
    snapshots. Do not add a scheduler merely to satisfy the old ADR plan.

16. **Add targeted Wikidata name enrichment when GeoNames language coverage is
    insufficient.**
    Match only to existing regions, preserve source provenance, and prove the
    licensing/display policy before importing.

17. **Add geoBoundaries geometry enrichment when a product feature needs region
    polygons or improved centroids.**
    Keep polygon data outside the core `regions` table until a confirmed query
    or display requirement justifies promotion.

18. **Evaluate Who's On First only for a demonstrated concordance problem.**
    Do not add it as a general extra source; require a concrete matching or data
    quality case first.

## P4: Optional Consolidation and Scale Work

19. **Extract shared React explore-map controls and result cards only after
    reuse becomes stable.**
    Keep the migrated Explore composition feature-owned until another React
    surface needs the same API or the local components become difficult to
    test.

20. **Move map delivery beyond bounded GeoJSON only when measured load requires
    it.**
    Evaluate vector tiles or PMTiles against observed payload size, query cost,
    cache behavior, and operating complexity before selecting an architecture.

21. **Add a public API only for a concrete consumer.**
    Reuse existing interactors and authorization rules, but define separate
    versioning, pagination, error, and exposure contracts in OpenSpec.

22. **Evaluate Inertia server-side rendering after the initial release.**
    Measure SEO, initial rendering, accessibility, and operational needs before
    adding a production Node SSR process. Preserve Rails security and routing
    ownership, and require a new Level 3 change if SSR is adopted.
