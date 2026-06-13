# Quality and Security

This document owns security baseline, testing policy, risk checks, and CI/merge
gates. Workflow, commands, and permission routing live in
`docs/DEVELOPMENT.md`. Product and architecture boundaries live in
`docs/FOUNDATIONS.md`.

## Security Baseline

Authentication and sessions:

- Passwords are hashed only.
- Password reset tokens must be single-use and time-bound.
- Invalidate relevant sessions after password reset or security-sensitive
  changes.
- Rotate session identifiers on successful sign in.
- Cookies must be Secure, HttpOnly, and use a deliberate SameSite policy.
- CSRF protection stays enabled for web flows.

Authorization:

- Policy checks are required on user-owned resources.
- Admin surfaces require explicit admin authorization.
- Never trust client-provided ownership or role fields.
- Check edit/delete rights explicitly for reviews, photos, and check-ins.

Uploads and media:

- Validate content type and file size.
- Store uploads through managed Active Storage/application flows.
- Keep private/internal blobs out of public listing surfaces unless explicitly
  published.
- Generate derivatives/previews asynchronously when appropriate.

Privacy:

- Treat exact user check-in location and timestamps as privacy-sensitive.
- Do not expose more precision than the product needs.
- Be explicit about what profile and activity data is public.

Secrets and logging:

- No secrets in git.
- Secrets only via env or credentials.
- Never log passwords, reset tokens, signed blob tokens, secrets, or raw
  credentials.
- Filter sensitive parameters and headers.

Abuse protection:

- Public authentication and write endpoints require abuse protection
  appropriate to their risk.
- Known missing controls are tracked in `docs/TODO.md` until implemented through
  an OpenSpec change.

## Risk Matrix

Use this matrix to decide what must be proved for security-sensitive changes.

| Change area | Main risks | Required proof |
| --- | --- | --- |
| Authentication | Account takeover, enumeration, weak credential handling | Request/interactor specs for success and failure paths; no secret/token logging |
| Password reset | Token replay, account enumeration, stale sessions | Single-use/time-bound token coverage; generic user-facing responses; session revocation coverage |
| Sessions/cookies | Fixation, weak cookie policy, stale auth | Rotation or revocation behavior covered; cookie/session settings reviewed |
| Authorization | IDOR, privilege escalation, admin bypass | Policy specs and request specs for owner, non-owner, guest, and admin where relevant |
| Admin surfaces | Unprotected operational tools | Admin-only request coverage and default-deny behavior |
| Uploads/media | Unsafe file exposure, oversized uploads, signed URL leakage | Content type/size validation and publication boundary coverage |
| Location/check-ins | Privacy leakage, over-precise public data | Precision and visibility decisions explicit in request/system coverage |
| Public catalog/map data | Draft/private data exposure, oversized payloads, N+1 | Published-only coverage, lean response shape, obvious N+1 review |
| Imports/provenance | Poisoned source data, unsafe retries, lost attribution | Idempotency, source metadata, sanitized errors, and retry behavior covered |
| Dependencies | Known vulnerable packages, unsafe transitive updates | Tradeoff explained; `make security` or equivalent result recorded |
| Logging/config | Secret disclosure, insecure production defaults | Filtered parameters/settings reviewed; no secrets committed |

## Testing Policy

Default stance:

- Integration-first with real PostgreSQL/PostGIS.
- Avoid mocks/stubs for app internals without a strong reason.
- Mocks/stubs are acceptable mainly at external I/O boundaries.
- Prefer request/system coverage for core user journeys.

Required spec layers:

- `spec/models`
- `spec/interactors`
- `spec/policies`
- `spec/requests`
- `spec/system`

Coverage targets:

- Global line coverage: `>= 90%`.
- Critical domain flows: `>= 95%`.

Critical flows:

- Auth.
- Region hierarchy and imports.
- Waterfall browse/detail.
- Waterfall map data.

New protected, upload, location, or social flows become critical when their
OpenSpec change is approved.

Performance guardrails:

- Watch N+1 in catalog, feed, and profile surfaces.
- Keep distance queries index-backed when introduced.
- Keep public collections bounded and add pagination before exposing unbounded
  catalog or feed results.
- Keep map payloads lean.

## CI and Merge Gates

Required checks:

- RuboCop.
- ERB lint.
- RSpec.
- Brakeman.
- bundler-audit.

Before merge:

- All required checks are green or the known blocker is explicitly accepted.
- I18n keys exist for `ru` and `en` when user-facing text is introduced.
- Authorization coverage exists for new protected flows.
- New business logic uses the canonical `yabi` interactor style.
- New migrations include required constraints and indexes.
- Geospatial changes are tested against real PostGIS behavior.
- `CHANGES.md` has a short dated summary.
