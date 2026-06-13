# ADRs

Architecture decision records for durable, cross-cutting choices that should
remain understandable after the feature change that introduced them has been
archived.

ADRs may own:

- selected technologies and important dependency boundaries;
- application, persistence, integration, and execution boundaries;
- design-system foundations and durable visual principles;
- constraints, non-goals, rejected alternatives, and consequences;
- scale or replacement triggers when they explain the current architecture
  rather than promise future work.

Feature intent, acceptance behavior, product scenarios, design exploration, and
implementation tasks belong in OpenSpec. Create an ADR only when a confirmed
Level 3 change introduces a decision that should outlive the feature change.

An ADR records the architecture that the project actually adopted. When an old
ADR still contains planning material or contradicts established implementation,
normalize it to the implemented decision and record the normalization date.
Move unimplemented work to `docs/TODO.md`; do not preserve it as an ADR
requirement.

ADRs explain what the project chose and why. They may describe the implemented
shape needed to make that choice concrete, but they do not own endpoint
behavior, acceptance scenarios, rollout steps, implementation checklists, or
feature roadmaps. Exact runtime behavior remains in OpenSpec and is proved by
code and RSpec.

- [ADR 0001: Map Browse Stack](0001-map-browse-stack.md)
- [ADR 0002: Design System Foundation](0002-design-system-foundation.md)
- [ADR 0003: Import Architecture and Region Ingestion](0003-import-architecture-and-region-ingestion.md)
- [ADR 0004: GeoNames Queued Import Orchestration](0004-geonames-queued-import-orchestration.md)
