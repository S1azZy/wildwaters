# Quality and Security

## Security baseline
Authentication:
- Passwords are hashed only
- Never log passwords, reset tokens, signed blob tokens, or secrets
- Password reset tokens must be single-use and time-bound
- Invalidate relevant sessions after password reset or security-sensitive changes

Authorization:
- Policy checks on all user-owned resources
- Admin surfaces protected by explicit admin authorization
- Never trust client-provided ownership or role fields
- Check edit/delete rights for reviews, photos, and check-ins explicitly

Uploads and media:
- Validate content type and file size for uploads
- Store uploads in S3-compatible storage through managed application flows only
- Generate derivatives/previews asynchronously when appropriate
- Keep private/internal blobs out of public listing surfaces unless explicitly published

Location and privacy:
- Treat exact user check-in location and timestamps as privacy-sensitive
- Do not expose more precision than product requirements need
- Be explicit about what profile/activity data is public

Sessions and transport:
- Secure, HttpOnly cookies
- Proper SameSite configuration
- Production HTTPS (`force_ssl`) and proxy SSL handling
- CSRF protection enabled for web flows

Secrets and logging:
- No secrets in git
- Secrets only via env/credentials
- Filter sensitive parameters and headers

Abuse protection:
- Rate limit sign in
- Rate limit password reset
- Rate limit registration
- Rate limit review/check-in/photo spam surfaces as they are introduced

## Testing strategy
Default stance:
- Integration-first with real PostgreSQL/PostGIS
- Avoid mocks/stubs for app internals without a strong reason
- Mocks/stubs are acceptable mainly at external I/O boundaries
- Prefer request/system coverage for core user journeys

Required spec layers:
- `spec/models`
- `spec/interactors` or `spec/services`
- `spec/policies`
- `spec/requests`
- `spec/system`

Coverage policy:
- Global line coverage: `>= 90%`
- Critical domain flows: `>= 95%`

Critical flows to cover:
- Auth
- Region browsing
- Waterfall browse/detail
- Nearby search
- Photo upload
- Check-in creation
- Review permissions
- Profile and follow flows

Performance guardrails:
- Watch N+1 in catalog, feed, and profile surfaces
- Keep nearby queries index-backed
- Paginate feed and catalog surfaces by default
- Keep map payloads lean

## CI and merge gates
Required checks:
- RuboCop
- RSpec
- Brakeman
- bundler-audit

Before merge:
- All checks green
- Authorization coverage exists for new protected flows
- New business logic uses the canonical service/interactor style
- New migrations include required constraints and indexes
- Geospatial changes are tested against real PostGIS behavior
- `CHANGES.md` updated with a short dated summary
