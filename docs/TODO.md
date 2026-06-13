# TODO

This document is the ordered queue for known behavior that is not implemented.
It is not a specification and does not authorize implementation by itself.

Before starting an item:

1. confirm that it still solves a current product or operational problem;
2. create a Level 2 OpenSpec change, or Level 3 plus an ADR when a new durable
   architecture decision is required;
3. remove the item from this file after the change is implemented and archived.

Items are ordered by dependency, expected value, and implementation complexity.
Earlier items should normally be considered before later ones.

## P0: Close Existing Contract Gaps

1. **Apply the stored user locale to requests.**
   Registration persists `User#locale`, but authenticated requests still use
   the application default locale. Add a request-scoped locale selection with a
   deliberate guest fallback and coverage for both `en` and `ru`.

2. **Restrict automatic region creation to canonical identity sources.**
   The import model prevents a non-canonical source from becoming a primary
   identity, but the apply path can still create a new `Region` for any enabled
   source. Enrichment sources should attach only to an existing match unless a
   separately approved workflow says otherwise.

3. **Add abuse protection to authentication entrypoints.**
   Rate limit sign-in, registration, and password-reset requests without
   revealing account existence or weakening existing session and CSRF
   behavior.

4. **Replace the catalog's fixed first-60 result window with explicit
   pagination or continuation.**
   Keep map payloads bounded, but make the HTML catalog and filtered discovery
   behavior explicit when more than 60 published waterfalls match.

## P1: Complete Core Waterfall Discovery

5. **Add database-backed waterfall and region-name search.**
   The explore search field currently filters only the features already loaded
   in the browser. Search should use first-class waterfall fields and indexed
   `region_names`, while preserving the current map filters.

6. **Add nearby waterfall discovery.**
   Implement an index-backed PostGIS distance query with an explicit radius,
   ordering, result limit, and privacy-safe handling of user-provided
   coordinates.

7. **Add dedicated region browse behavior.**
   Expose useful region hierarchy and region context beyond the current filter
   dropdown. Reuse closure-table traversal and multilingual names rather than
   introducing a second hierarchy model.

## P2: Build the First Account Value Loop

8. **Add a real user profile surface.**
   Define public and private profile fields before expanding the dashboard
   placeholder.

9. **Add saved waterfalls.**
   Provide the smallest authenticated return-value loop before introducing
   public social content.

10. **Add waterfall reviews with explicit ownership authorization.**
    Define publication state, edit/delete permissions, and anti-spam controls
    before exposing reviews publicly.

11. **Add waterfall photos through Active Storage.**
    Define content-type and size validation, publication visibility,
    attribution, and asynchronous derivatives.

12. **Add check-ins with a privacy boundary.**
    Decide timestamp and location precision, public visibility, and ownership
    rules before persistence or feed integration.

13. **Add follows and an activity feed.**
    Build this only after profiles and at least one meaningful activity source
    exist. Paginate the feed and keep authorization explicit.

14. **Add achievements.**
    Treat achievements as a derived layer over stable check-in and activity
    behavior, not as an independent MVP subsystem.

## P3: Improve Import Operations and Coverage

15. **Add an admin import operations surface.**
    Provide source/run/item visibility, sanitized failures, enqueue controls,
    and retry-failed actions behind explicit admin authorization. Reuse the
    existing import interactors rather than shelling out to Make or rake.

16. **Add scheduled GeoNames imports when an operating cadence is known.**
    Scheduled jobs must call the same enqueue interactor and use persisted run
    snapshots. Do not add a scheduler merely to satisfy the old ADR plan.

17. **Add targeted Wikidata name enrichment when GeoNames language coverage is
    insufficient.**
    Match only to existing regions, preserve source provenance, and prove the
    licensing/display policy before importing.

18. **Add geoBoundaries geometry enrichment when a product feature needs region
    polygons or improved centroids.**
    Keep polygon data outside the core `regions` table until a confirmed query
    or display requirement justifies promotion.

19. **Evaluate Who's On First only for a demonstrated concordance problem.**
    Do not add it as a general extra source; require a concrete matching or data
    quality case first.

## P4: Optional Consolidation and Scale Work

20. **Extract shared explore-map controls and result cards after reuse becomes
    stable.**
    The current page-level ERB and partials are valid under ADR 0002. Extract
    components only when another surface needs the same API or current markup
    becomes difficult to test.

21. **Move map delivery beyond bounded GeoJSON only when measured load requires
    it.**
    Evaluate vector tiles or PMTiles against observed payload size, query cost,
    cache behavior, and operating complexity before selecting an architecture.

22. **Add a public API only for a concrete consumer.**
    Reuse existing interactors and authorization rules, but define separate
    versioning, pagination, error, and exposure contracts in OpenSpec.
