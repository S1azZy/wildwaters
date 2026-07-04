## ADDED Requirements

### Requirement: Jobs route coexistence with application admin namespace
The system SHALL keep the Mission Control Jobs dashboard protected and
reachable when the application-owned admin namespace is introduced.

#### Scenario: Jobs route remains protected
- **GIVEN** the application-owned admin service-actions route exists
- **WHEN** a visitor requests `/admin/jobs`
- **THEN** the existing jobs dashboard authorization behavior remains in force
  for guest, member, and admin users

#### Scenario: Admin namespace does not shadow jobs engine
- **GIVEN** an authenticated admin can open the application-owned admin service
  actions page
- **WHEN** the admin requests `/admin/jobs`
- **THEN** the system routes the request to the Mission Control Jobs engine
  rather than the application-owned Inertia admin page
