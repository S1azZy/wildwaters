# Documentation and OpenSpec Baseline Migration

> Status: Completed 2026-06-13
> Started: 2026-06-13

## Goal

Align project documentation with the implemented system:

- ADRs record only durable architectural decisions that exist in the code;
- OpenSpec owns current observable behavior and future behavioral changes;
- `docs/TODO.md` owns known work that is not implemented yet;
- README and the Codex harness point to the correct source of truth.

For the reconstructed OpenSpec baseline, current code and passing RSpec examples
are implementation evidence. When an old document disagrees with them, the
baseline follows the implementation.

## Steps

- [x] Rewrite ADR 0001-0004 to remove plans, requirements, and unimplemented
  alternatives while preserving implemented architectural decisions and
  rationale.
- [x] Create a prioritized `docs/TODO.md` for known unimplemented requirements,
  ordered by dependency, expected value, and implementation complexity.
- [x] Reconstruct capability specs under `openspec/specs/` from current code and
  RSpec without inventing future behavior.
- [x] Update README, source maps, workflow policy, historical plan status, and
  `CHANGES.md` for the new ownership model.
- [x] Run `bin/openspec validate --all --strict`, tooling specs,
  `git diff --check`, and review the final diff for contradictions.

## Bootstrap Rule

This migration is a one-time baseline reconstruction, not a fictional historical
feature change. Baseline capability specs may therefore be written directly to
`openspec/specs/`. After the baseline exists, all meaningful behavior changes
must use normal OpenSpec delta changes and archive back into the baseline.
